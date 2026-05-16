import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_env.dart';
import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/chat/chat_models.dart';
import '../../chat/chat_conversation_panel.dart';
import 'stripe_checkout_webview_screen.dart';

/// Patient ↔ linked doctor chat. Requires monthly subscription (Stripe).
class PatientDoctorChatScreen extends StatefulWidget {
  const PatientDoctorChatScreen({super.key});

  @override
  State<PatientDoctorChatScreen> createState() =>
      _PatientDoctorChatScreenState();
}

class _PatientDoctorChatScreenState extends State<PatientDoctorChatScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _paying = false;
  bool _syncing = false;
  String? _error;
  LinkedDoctorInfo? _doctor;
  bool _subscribed = false;
  ChatThread? _thread;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_subscribed) {
      _refreshAfterPayment(showErrors: false);
    }
  }

  /// Pulls subscription status from Stripe into Supabase, then reloads UI.
  Future<void> _refreshAfterPayment({
    bool showErrors = true,
    String? checkoutSessionId,
  }) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final synced = await Backend.chatBilling.syncSubscriptionAfterPayment(
        checkoutSessionId: checkoutSessionId,
      );
      await _load();
      if (!mounted || !showErrors || synced || _subscribed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment not found yet. Wait a few seconds and tap refresh again.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _load() async {
    final patientId =
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (patientId == null || patientId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not signed in.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _patientId = patientId;
    });

    try {
      final doctor = await Backend.chat.getLinkedDoctorForPatient(patientId);
      final subscribed = await Backend.chat.isPatientSubscribed(patientId);
      ChatThread? thread;
      if (doctor != null && subscribed) {
        thread = await Backend.chat.getOrCreateThread(
          doctorId: doctor.doctorId,
          patientId: patientId,
        );
      }
      if (!mounted) return;
      setState(() {
        _doctor = doctor;
        _subscribed = subscribed;
        _thread = thread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startCheckout() async {
    setState(() => _paying = true);
    try {
      final checkout = await Backend.chatBilling.createCheckoutUrl();
      final url = checkout.url;
      if (url == null || url.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkout.error ?? 'Payment is not configured yet.',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
        return;
      }
      if (!mounted) return;
      final sessionResult = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => StripeCheckoutWebViewScreen(checkoutUrl: url),
        ),
      );
      if (!mounted) return;
      if (sessionResult != null) {
        await _refreshAfterPayment(
          checkoutSessionId: sessionResult.isEmpty ? null : sessionResult,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = AppEnv.chatMonthlyPricePkr;
    final priceLabel =
        price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_doctor?.doctorName ?? 'Doctor chat'),
        actions: [
          if (_subscribed)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _doctor == null
          ? _NoDoctorLinked(onRetry: _load)
          : !_subscribed
          ? _ChatPaywall(
              doctorName: _doctor!.doctorName,
              priceLabel: priceLabel,
              paying: _paying,
              syncing: _syncing,
              onPay: _startCheckout,
              onRefresh: () => _refreshAfterPayment(),
            )
          : _thread == null
          ? const Center(child: Text('Could not start chat.'))
          : ChatConversationPanel(
              threadId: _thread!.id,
              currentUserId: _patientId!,
              peerName: _doctor!.doctorName,
            ),
    );
  }
}

class _NoDoctorLinked extends StatelessWidget {
  const _NoDoctorLinked({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 56, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          Text(
            'No doctor linked yet',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your 6-digit link code from the home screen (key icon) so your doctor can connect.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _ChatPaywall extends StatelessWidget {
  const _ChatPaywall({
    required this.doctorName,
    required this.priceLabel,
    required this.paying,
    required this.syncing,
    required this.onPay,
    required this.onRefresh,
  });

  final String doctorName;
  final String priceLabel;
  final bool paying;
  final bool syncing;
  final VoidCallback onPay;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 20),
          Text(
            'Chat with $doctorName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Secure messaging with your doctor is a paid feature.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Rs $priceLabel',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF608266),
                        ),
                  ),
                  const Text('per month'),
                  const SizedBox(height: 8),
                  const Text(
                    'Your doctor can chat for free.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: paying ? null : onPay,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF608266),
            ),
            child: paying
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Pay Rs $priceLabel / month'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: syncing || paying ? null : onRefresh,
            child: syncing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('I completed payment — refresh'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
