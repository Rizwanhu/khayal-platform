import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_env.dart';
import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/chat/chat_models.dart';
import '../../../core/chat/chat_subscription_period.dart';
import '../../../core/ui/patient_shell_colors.dart';
import '../../../core/ui/user_facing_error.dart';
import '../../chat/chat_conversation_panel.dart';
import 'chat_subscription_banner.dart';
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
  PatientChatSubscription? _subscription;
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
      final subscription = await Backend.chat.getSubscription(patientId);
      final subscribed =
          subscription?.isActive ??
          await Backend.chat.isPatientSubscribed(patientId);
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
        _subscription = subscription;
        _subscribed = subscribed;
        _thread = thread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFacingNetworkOrGenericError(e);
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
      backgroundColor: PatientShellColors.canvas,
      appBar: AppBar(
        backgroundColor: PatientShellColors.header,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _doctor?.doctorName ?? 'Doctor chat',
          style: const TextStyle(
            fontFamily: 'KhayalRoboto',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_subscribed)
            IconButton(
              tooltip: 'Refresh messages',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: _loading
          ? const _ChatLoadingState()
          : _error != null
          ? _ChatErrorState(
              message: _error!,
              onRetry: _load,
            )
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
          ? _ChatErrorState(
              message: 'Chat could not be opened. Pull to refresh or try again.',
              onRetry: _load,
            )
          : Column(
              children: [
                ChatSubscriptionBanner(
                  display: chatSubscriptionPeriodDisplay(_subscription),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: ChatConversationPanel(
                        threadId: _thread!.id,
                        currentUserId: _patientId!,
                        peerName: _doctor!.doctorName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: PatientShellColors.header,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading your chat…',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'KhayalRoboto',
                    fontWeight: FontWeight.w700,
                    color: PatientShellColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This only takes a moment.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PatientShellColors.textMuted,
                    fontFamily: 'KhayalRoboto',
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  const _ChatErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 36,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'We couldn’t load chat',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'KhayalRoboto',
                          fontWeight: FontWeight.w800,
                          color: PatientShellColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PatientShellColors.textMuted,
                          height: 1.4,
                          fontFamily: 'KhayalRoboto',
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: PatientShellColors.header,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 22),
                      label: const Text(
                        'Try again',
                        style: TextStyle(
                          fontFamily: 'KhayalRoboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoDoctorLinked extends StatelessWidget {
  const _NoDoctorLinked({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PatientShellColors.header.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link_off_rounded,
                  size: 48,
                  color: PatientShellColors.header,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'No doctor linked yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w800,
                      color: PatientShellColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Open the home screen, tap the key icon, and share the 6-digit code with your doctor so they can link to you.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: PatientShellColors.textMuted,
                      height: 1.45,
                      fontFamily: 'KhayalRoboto',
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PatientShellColors.header,
                    side: const BorderSide(color: PatientShellColors.header),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'I’ve shared my code — check again',
                    style: TextStyle(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.verified_user_outlined,
            size: 56,
            color: PatientShellColors.header.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 18),
          Text(
            'Chat with $doctorName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'KhayalRoboto',
                  fontWeight: FontWeight.w800,
                  color: PatientShellColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Private, secure messaging. Subscribe once per month to unlock.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: PatientShellColors.textMuted,
                  height: 1.4,
                  fontFamily: 'KhayalRoboto',
                ),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PatientShellColors.divider,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 22,
                horizontal: 20,
              ),
              child: Column(
                children: [
                  Text(
                    'Rs $priceLabel',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: PatientShellColors.header,
                          fontFamily: 'KhayalRoboto',
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'per month',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: PatientShellColors.textMuted,
                          fontFamily: 'KhayalRoboto',
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your doctor uses chat at no extra charge.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PatientShellColors.textMuted,
                          fontFamily: 'KhayalRoboto',
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: paying ? null : onPay,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: PatientShellColors.header,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
                : Text(
                    'Pay Rs $priceLabel / month',
                    style: const TextStyle(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: syncing || paying ? null : onRefresh,
            child: syncing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'I already paid — refresh status',
                    style: TextStyle(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
