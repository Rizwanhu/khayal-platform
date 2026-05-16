import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_env.dart';

/// Opens Stripe Checkout for the monthly doctor–patient chat subscription.
class ChatBillingService {
  ChatBillingService(this._client);

  final SupabaseClient _client;

  /// Stripe Checkout URL, or a static Payment Link from `.env`.
  /// [error] is set when checkout could not be created (for UI messages).
  Future<({String? url, String? error})> createCheckoutUrl() async {
    String? invokeError;

    try {
      final response = await _client.functions.invoke(
        'create-chat-checkout',
        body: <String, dynamic>{},
      );
      final data = response.data;
      if (data is Map) {
        final url = data['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return (url: url, error: null);
        }
        final err = data['error']?.toString();
        if (err != null && err.isNotEmpty) {
          invokeError = err;
        }
      } else if (data != null) {
        invokeError = data.toString();
      }
      if (invokeError == null && response.status != 200) {
        invokeError = 'Edge function HTTP ${response.status}';
      }
    } catch (e) {
      invokeError = e.toString();
    }

    final link = AppEnv.chatStripePaymentLink;
    if (link != null && link.isNotEmpty) {
      return (url: link, error: null);
    }

    if (invokeError != null) {
      return (
        url: null,
        error:
            'Checkout failed: $invokeError. Deploy Edge Function '
            '"create-chat-checkout" in Supabase and set STRIPE_SECRET_KEY + '
            'STRIPE_CHAT_PRICE_ID secrets.',
      );
    }

    return (
      url: null,
      error:
          'Payment is not configured. In Supabase: deploy Edge Function '
          '"create-chat-checkout" and add STRIPE_SECRET_KEY + '
          'STRIPE_CHAT_PRICE_ID. Or set CHAT_STRIPE_PAYMENT_LINK in .env.',
    );
  }

  /// Confirms subscription with Stripe and updates Supabase (use after payment).
  Future<bool> syncSubscriptionAfterPayment({String? checkoutSessionId}) async {
    try {
      final response = await _client.functions.invoke(
        'sync-chat-subscription',
        body: checkoutSessionId == null || checkoutSessionId.isEmpty
            ? <String, dynamic>{}
            : <String, dynamic>{'sessionId': checkoutSessionId},
      );
      final data = response.data;
      if (data is Map && data['active'] == true) return true;
    } catch (_) {
      // Fall through.
    }
    return false;
  }
}
