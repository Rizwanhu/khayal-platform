import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import Stripe from "https://esm.sh/stripe@17.4.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!stripeKey || !supabaseUrl || !serviceKey || !anonKey) {
      throw new Error("Missing Stripe or Supabase configuration.");
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized", active: false }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const admin = createClient(supabaseUrl, serviceKey);
    const stripe = new Stripe(stripeKey, { apiVersion: "2024-11-20.acacia" });

    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return new Response(JSON.stringify({ error: "Unauthorized", active: false }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const patientId = userData.user.id;
    let body: { sessionId?: string } = {};
    if (req.method === "POST") {
      try {
        body = await req.json();
      } catch {
        body = {};
      }
    }

    // If app sends checkout session id, verify that session directly.
    if (body.sessionId) {
      const session = await stripe.checkout.sessions.retrieve(body.sessionId);
      if (
        session.mode === "subscription" &&
        session.payment_status === "paid" &&
        (session.client_reference_id === patientId ||
          session.metadata?.patient_id === patientId)
      ) {
        const subId = session.subscription?.toString();
        if (subId) {
          const sub = await stripe.subscriptions.retrieve(subId);
          await admin.from("patient_chat_subscriptions").upsert({
            patient_id: patientId,
            status: "active",
            stripe_customer_id: session.customer?.toString() ?? null,
            stripe_subscription_id: subId,
            current_period_end: new Date(sub.current_period_end * 1000)
              .toISOString(),
            updated_at: new Date().toISOString(),
          });
          return new Response(JSON.stringify({ active: true }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      }
    }

    const { data: row } = await admin
      .from("patient_chat_subscriptions")
      .select("stripe_customer_id")
      .eq("patient_id", patientId)
      .maybeSingle();

    const customerId = row?.stripe_customer_id as string | undefined;
    if (!customerId) {
      return new Response(JSON.stringify({ active: false }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const subs = await stripe.subscriptions.list({
      customer: customerId,
      status: "all",
      limit: 10,
    });

    const activeSub = subs.data.find(
      (s) => s.status === "active" || s.status === "trialing",
    );

    if (activeSub) {
      await admin.from("patient_chat_subscriptions").upsert({
        patient_id: patientId,
        status: "active",
        stripe_customer_id: customerId,
        stripe_subscription_id: activeSub.id,
        current_period_end: new Date(activeSub.current_period_end * 1000)
          .toISOString(),
        updated_at: new Date().toISOString(),
      });
      return new Response(JSON.stringify({ active: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ active: false }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: message, active: false }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
