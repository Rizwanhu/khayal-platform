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
    const priceId = Deno.env.get("STRIPE_CHAT_PRICE_ID");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!stripeKey || !priceId || !supabaseUrl || !serviceKey || !anonKey) {
      throw new Error("Missing Stripe or Supabase env vars on the function.");
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const admin = createClient(supabaseUrl, serviceKey);

    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const patientId = userData.user.id;
    const stripe = new Stripe(stripeKey, { apiVersion: "2024-11-20.acacia" });

    const { data: existing } = await admin
      .from("patient_chat_subscriptions")
      .select("stripe_customer_id")
      .eq("patient_id", patientId)
      .maybeSingle();

    let customerId = existing?.stripe_customer_id as string | undefined;
    if (!customerId) {
      const customer = await stripe.customers.create({
        metadata: { patient_id: patientId },
      });
      customerId = customer.id;
      await admin.from("patient_chat_subscriptions").upsert({
        patient_id: patientId,
        status: "inactive",
        stripe_customer_id: customerId,
      });
    }

    // App WebView detects session_id= or chat-payment-success in the URL.
    const successUrl =
      Deno.env.get("STRIPE_CHECKOUT_SUCCESS_URL") ??
      "https://khayal.app/chat-payment-success?session_id={CHECKOUT_SESSION_ID}";
    const cancelUrl =
      Deno.env.get("STRIPE_CHECKOUT_CANCEL_URL") ??
      "https://khayal.app/chat-payment-cancel";

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      client_reference_id: patientId,
      metadata: { patient_id: patientId },
      subscription_data: {
        metadata: { patient_id: patientId },
      },
    });

    return new Response(JSON.stringify({ url: session.url }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
