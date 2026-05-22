import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import Stripe from "https://esm.sh/stripe@17.4.0?target=deno";

const stripeKey = Deno.env.get("STRIPE_SECRET_KEY")!;
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const stripe = new Stripe(stripeKey, { apiVersion: "2024-11-20.acacia" });
const admin = createClient(supabaseUrl, serviceKey);

async function upsertActive(
  patientId: string,
  subscriptionId: string,
  periodEnd: number | null,
  customerId?: string,
) {
  await admin.from("patient_chat_subscriptions").upsert({
    patient_id: patientId,
    status: "active",
    stripe_subscription_id: subscriptionId,
    stripe_customer_id: customerId ?? null,
    current_period_end: periodEnd
      ? new Date(periodEnd * 1000).toISOString()
      : null,
    updated_at: new Date().toISOString(),
  });
}

Deno.serve(async (req) => {
  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("Missing signature", { status: 400 });
  }

  const body = await req.text();
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(`Webhook error: ${message}`, { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const patientId =
          session.client_reference_id ??
          session.metadata?.patient_id ??
          "";
        if (!patientId || session.mode !== "subscription") break;

        const subId = session.subscription?.toString();
        if (!subId) break;

        const sub = await stripe.subscriptions.retrieve(subId);
        await upsertActive(
          patientId,
          subId,
          sub.current_period_end,
          session.customer?.toString(),
        );
        break;
      }
      case "customer.subscription.updated":
      case "customer.subscription.created": {
        const sub = event.data.object as Stripe.Subscription;
        const patientId = sub.metadata?.patient_id ?? "";
        if (!patientId) break;
        const active = sub.status === "active" || sub.status === "trialing";
        await admin.from("patient_chat_subscriptions").upsert({
          patient_id: patientId,
          status: active ? "active" : "past_due",
          stripe_subscription_id: sub.id,
          stripe_customer_id: sub.customer?.toString() ?? null,
          current_period_end: new Date(sub.current_period_end * 1000)
            .toISOString(),
          updated_at: new Date().toISOString(),
        });
        break;
      }
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const patientId = sub.metadata?.patient_id ?? "";
        if (!patientId) break;
        await admin.from("patient_chat_subscriptions").upsert({
          patient_id: patientId,
          status: "canceled",
          stripe_subscription_id: sub.id,
          current_period_end: new Date(sub.current_period_end * 1000)
            .toISOString(),
          updated_at: new Date().toISOString(),
        });
        break;
      }
      default:
        break;
    }
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return new Response(message, { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
