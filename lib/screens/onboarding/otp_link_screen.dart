import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_env.dart';
import '../../core/auth/auth_restore.dart';
import '../../core/backend/app_session.dart';
import '../../core/backend/backend.dart';
import '../../core/i18n/app_language.dart';
import '../../core/i18n/app_strings.dart';

/// Phone number sign-in (no SMS OTP). Linking doctor/caregiver to patient still
/// uses the 6-digit code from the patient home screen.
class OtpLinkScreen extends StatefulWidget {
  const OtpLinkScreen({super.key});

  @override
  State<OtpLinkScreen> createState() => _OtpLinkScreenState();
}

class _OtpLinkScreenState extends State<OtpLinkScreen>
    with SingleTickerProviderStateMixin {
  static const Color _canvas = Color(0xFFFAF9F6);
  static const Color _title = Color(0xFF222222);
  static const Color _subtitle = Color(0xFF757575);
  static const Color _cellFill = Color(0xFFF2EFE9);
  static const Color _cellBorderIdle = Color(0xFFE0DCD4);
  static const Color _ctaMuted = Color(0xFFADC2B1);
  static const Color _ctaReady = Color(0xFF6B8E7B);

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final TextEditingController _phoneController = TextEditingController();

  double _buttonScale = 1;
  bool _signingIn = false;

  AppRole get _role => AppSession.currentRole ?? AppRole.patient;

  bool get _phoneValid =>
      BackendRepository.normalizePhone(_phoneController.text) != null;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _continueWithPhone() async {
    if (!_phoneValid && !AppEnv.devOtpBypass) {
      _snack('Enter a valid phone number with country code (e.g. +923001234567).');
      return;
    }

    setState(() => _signingIn = true);
    try {
      final User user;
      if (AppEnv.devOtpBypass) {
        final creds = AppEnv.bypassEmailPasswordForRole(_role);
        if (creds == null) {
          _snack(
            'DEV_OTP_BYPASS is on but .env needs DEV_BYPASS_EMAIL / DEV_BYPASS_PASSWORD '
            '(or per-role DEV_BYPASS_*).',
          );
          return;
        }
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: creds.$1,
          password: creds.$2,
        );
        final resolved = res.user ?? Supabase.instance.client.auth.currentUser;
        if (resolved == null) {
          _snack('Dev sign-in failed. Check bypass credentials in .env.');
          return;
        }
        user = resolved;
      } else {
        final phone = BackendRepository.normalizePhone(_phoneController.text)!;
        user = await Backend.repo.signInOrSignUpWithPhone(phone: phone);
      }

      final phoneForProfile = AppEnv.devOtpBypass
          ? (BackendRepository.normalizePhone(_phoneController.text) ??
                user.phone)
          : BackendRepository.normalizePhone(_phoneController.text);

      await _finishSignIn(user, phoneForProfile);
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _finishSignIn(User resolvedUser, String? phoneForProfile) async {
    final existingProfile =
        await Backend.repo.getPatientProfile(resolvedUser.id);
    final defaultName =
        _role == AppRole.caregiver ? 'New Caregiver' : 'New User';
    final existingName = existingProfile?.fullName.trim() ?? '';
    final fullNameForProfile =
        existingName.isNotEmpty &&
            existingName != 'New Caregiver' &&
            existingName != 'New User'
        ? existingName
        : defaultName;

    final storedLang = existingProfile?.languageCode?.trim();
    if (storedLang != null && storedLang.isNotEmpty) {
      await AppLanguageState.setLanguage(
        storedLang == 'ur' || storedLang.startsWith('ur')
            ? AppLanguage.urdu
            : AppLanguage.english,
      );
    }

    await Backend.repo.upsertProfile(
      userId: resolvedUser.id,
      role: _role.name,
      fullName: fullNameForProfile,
      phone: phoneForProfile,
      languageCode: AppLanguageState.languageCode,
    );

    if (!mounted) return;
    await AuthRestore.navigateAfterSignIn(
      context,
      user: resolvedUser,
      role: _role,
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canContinue = AppEnv.devOtpBypass || _phoneValid;

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (kDebugMode &&
                          !AppEnv.devOtpBypass &&
                          AppEnv.phoneAuthPassword.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blueGrey.shade300,
                            ),
                          ),
                          child: Text(
                            'Set PHONE_AUTH_PASSWORD in .env (Supabase Auth → disable email confirmation for sign-up).',
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              fontFamily: 'KhayalRoboto',
                              color: Colors.blueGrey.shade900,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (AppEnv.devOtpBypass) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Text(
                            'DEV: bypass on — phone optional; uses DEV_BYPASS_* credentials.',
                            textAlign: TextAlign.center,
                            style: textTheme.labelMedium?.copyWith(
                              fontFamily: 'KhayalRoboto',
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade900,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        AppStrings.continueWithPhone,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontFamily: AppLanguageState.isUrdu
                              ? 'NotoNastaliqUrdu'
                              : 'KhayalRoboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: _title,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.phoneSignInBlurb,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          fontFamily: AppLanguageState.isUrdu
                              ? 'NotoNastaliqUrdu'
                              : 'KhayalRoboto',
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                          height: 1.45,
                          color: _subtitle,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '+923001234567',
                          labelText: AppStrings.phoneNumber,
                          filled: true,
                          fillColor: _cellFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _cellBorderIdle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _cellBorderIdle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      _ContinueButton(
                        scale: _buttonScale,
                        enabled: canContinue && !_signingIn,
                        label: _signingIn
                            ? AppStrings.pleaseWait
                            : AppStrings.continueBtn,
                        mutedColor: _ctaMuted,
                        readyColor: _ctaReady,
                        onTap: _continueWithPhone,
                        onTapDown: () => setState(() => _buttonScale = 0.96),
                        onTapEnd: () => setState(() => _buttonScale = 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.scale,
    required this.enabled,
    required this.label,
    required this.mutedColor,
    required this.readyColor,
    required this.onTap,
    required this.onTapDown,
    required this.onTapEnd,
  });

  final double scale;
  final bool enabled;
  final String label;
  final Color mutedColor;
  final Color readyColor;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapEnd;

  @override
  Widget build(BuildContext context) {
    final bg = Color.lerp(mutedColor, readyColor, enabled ? 1.0 : 0.0)!;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: enabled ? 0.28 : 0.12),
              blurRadius: enabled ? 18 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: enabled ? onTap : null,
            onTapDown: enabled ? (_) => onTapDown() : null,
            onTapCancel: enabled ? onTapEnd : null,
            onTapUp: enabled ? (_) => onTapEnd() : null,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'KhayalRoboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
