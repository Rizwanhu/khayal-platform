import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_env.dart';
import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/chat/chat_models.dart';
import '../../../core/chat/chat_subscription_period.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/ui/patient_shell_colors.dart';
import '../../../core/ui/patient_ui_tokens.dart';
import '../../../core/ui/patient_ui_widgets.dart';
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
      appBar: PatientUi.appBar(
        title: _doctor?.doctorName ??
            AppLanguageState.pick(en: 'Doctor chat', ur: 'ڈاکٹر چیٹ'),
        actions: [
          if (_subscribed)
            IconButton(
              tooltip: AppLanguageState.pick(
                en: 'Refresh messages',
                ur: 'پیغامات تازہ کریں',
              ),
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 28),
            ),
        ],
      ),
      body: _loading
          ? PatientUi.loadingPanel(
              title: AppLanguageState.pick(
                en: 'Loading your chat…',
                ur: 'چیٹ لوڈ ہو رہی ہے…',
              ),
              subtitle: AppLanguageState.pick(
                en: 'Please wait a moment.',
                ur: 'تھوڑی دیر انتظار کریں۔',
              ),
            )
          : _error != null
          ? PatientUi.messagePanel(
              icon: Icons.error_outline_rounded,
              iconColor: PatientShellColors.missed,
              iconBg: const Color(0xFFFFEBEE),
              title: AppLanguageState.pick(
                en: 'Could not open chat',
                ur: 'چیٹ نہیں کھلی',
              ),
              message: _error!,
              primaryLabel: AppLanguageState.pick(
                en: 'Try again',
                ur: 'دوبارہ کوشش',
              ),
              onPrimary: _load,
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
          ? PatientUi.messagePanel(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: PatientShellColors.header,
              iconBg: PatientShellColors.header.withValues(alpha: 0.12),
              title: AppLanguageState.pick(
                en: 'Chat not ready',
                ur: 'چیٹ تیار نہیں',
              ),
              message: AppLanguageState.pick(
                en: 'Please tap Try again.',
                ur: 'دوبارہ کوشش دبائیں۔',
              ),
              primaryLabel: AppLanguageState.pick(
                en: 'Try again',
                ur: 'دوبارہ کوشش',
              ),
              onPrimary: _load,
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

class _NoDoctorLinked extends StatelessWidget {
  const _NoDoctorLinked({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PatientUi.messagePanel(
      icon: Icons.link_off_rounded,
      iconColor: PatientShellColors.header,
      iconBg: PatientShellColors.header.withValues(alpha: 0.12),
      title: AppLanguageState.pick(
        en: 'No doctor linked yet',
        ur: 'ابھی ڈاکٹر منسلک نہیں',
      ),
      message: AppLanguageState.pick(
        en:
            'On the home screen, tap the key icon at the top. Share the 6-digit code with your doctor. Then tap the button below.',
        ur:
            'ہوم اسکرین پر اوپر چابی کا آئیکن دبائیں۔ 6 ہندسوں کا کوڈ ڈاکٹر کو دیں۔ پھر نیچے بٹن دبائیں۔',
      ),
      primaryLabel: AppLanguageState.pick(
        en: 'I shared my code — check again',
        ur: 'کوڈ دے دیا — دوبارہ چیک کریں',
      ),
      onPrimary: onRetry,
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
      padding: const EdgeInsets.fromLTRB(
        PatientUiTokens.paddingScreen,
        16,
        PatientUiTokens.paddingScreen,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 64,
            color: PatientShellColors.header,
          ),
          const SizedBox(height: 20),
          Text(
            AppLanguageState.pick(
              en: 'Chat with $doctorName',
              ur: '$doctorName سے بات',
            ),
            style: PatientUiTokens.titleLargeStyle(
              urdu: AppLanguageState.isUrdu,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguageState.pick(
              en: 'Safe private messages. Pay once each month to use chat.',
              ur: 'محفوظ پیغامات۔ چیٹ کے لیے ہر ماہ ایک بار ادائیگی۔',
            ),
            textAlign: TextAlign.center,
            style: PatientUiTokens.bodyStyle(
              urdu: AppLanguageState.isUrdu,
              color: PatientShellColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: PatientShellColors.card,
              borderRadius: BorderRadius.circular(PatientUiTokens.radiusCard),
              border: Border.all(color: PatientShellColors.divider, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Rs $priceLabel',
                    style: PatientUiTokens.titleLargeStyle(
                      urdu: false,
                      color: PatientShellColors.header,
                    ).copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLanguageState.pick(en: 'per month', ur: 'ہر ماہ'),
                    style: PatientUiTokens.bodyStyle(urdu: AppLanguageState.isUrdu),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLanguageState.pick(
                      en: 'Your doctor does not pay for chat.',
                      ur: 'ڈاکٹر کو چیٹ کی الگ فیس نہیں۔',
                    ),
                    textAlign: TextAlign.center,
                    style: PatientUiTokens.bodySmallStyle(
                      urdu: AppLanguageState.isUrdu,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          PatientUi.primaryButton(
            label: AppLanguageState.pick(
              en: 'Pay Rs $priceLabel per month',
              ur: 'Rs $priceLabel ہر ماہ ادا کریں',
            ),
            onPressed: paying ? null : onPay,
            icon: Icons.payment_rounded,
            loading: paying,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: PatientUiTokens.minTouchHeight,
            child: TextButton(
              onPressed: syncing || paying ? null : onRefresh,
              child: syncing
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      AppLanguageState.pick(
                        en: 'I already paid — refresh',
                        ur: 'ادا کر چکا — تازہ کریں',
                      ),
                      style: PatientUiTokens.labelStyle(
                        urdu: AppLanguageState.isUrdu,
                        color: PatientShellColors.header,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
