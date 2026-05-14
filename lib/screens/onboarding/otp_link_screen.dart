import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_env.dart';
import '../../core/backend/app_session.dart';
import '../../core/backend/backend.dart';
import '../../core/navigation/app_routes.dart';

/// Phone OTP login/registration for selected role.
class OtpLinkScreen extends StatefulWidget {
  const OtpLinkScreen({super.key});

  @override
  State<OtpLinkScreen> createState() => _OtpLinkScreenState();
}

class _OtpLinkScreenState extends State<OtpLinkScreen>
    with TickerProviderStateMixin {
  static const Color _canvas = Color(0xFFFAF9F6);
  static const Color _title = Color(0xFF222222);
  static const Color _subtitle = Color(0xFF757575);
  static const Color _cellFill = Color(0xFFF2EFE9);
  static const Color _cellBorderIdle = Color(0xFFE0DCD4);
  static const Color _cellBorderFocus = Color(0xFFADC2B1);
  static const Color _ctaMuted = Color(0xFFADC2B1);
  static const Color _ctaReady = Color(0xFF6B8E7B);

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocus = List.generate(6, (_) => FocusNode());
  final TextEditingController _phoneController = TextEditingController();

  double _buttonScale = 1;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _otpSent = false;

  bool get _isComplete =>
      _digitControllers.every((c) => c.text.trim().isNotEmpty);

  String get _otpCode => _digitControllers.map((e) => e.text).join();

  AppRole get _role => AppSession.currentRole ?? AppRole.patient;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    for (final n in _digitFocus) {
      n.addListener(_onFocusChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 380), () {
        if (mounted) _digitFocus.first.requestFocus();
      });
    });
  }

  void _onFocusChanged() {
    final hasFocus = _digitFocus.any((n) => n.hasFocus);
    if (hasFocus && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!hasFocus) {
      _pulseController.stop();
      _pulseController.reset();
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final n in _digitFocus) {
      n.removeListener(_onFocusChanged);
      n.dispose();
    }
    for (final c in _digitControllers) {
      c.dispose();
    }
    _phoneController.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      _pasteDigits(digits, index);
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _digitFocus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _digitFocus[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _pasteDigits(String digits, int startIndex) {
    final chars = digits.split('');
    var i = startIndex;
    for (final ch in chars) {
      if (i > 5) break;
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        _digitControllers[i].text = ch;
        i++;
      }
    }
    if (i <= 5) {
      _digitFocus[i].requestFocus();
    } else {
      _digitFocus[5].requestFocus();
    }
    setState(() {});
  }

  String _normalizedPhone() {
    final raw = _phoneController.text.trim().replaceAll(' ', '');
    return raw.startsWith('+') ? raw : '+$raw';
  }

  Future<void> _sendOtp() async {
    if (AppEnv.devOtpBypass) {
      if (!mounted) return;
      setState(() => _otpSent = true);
      _snack(
        'Dev bypass: SMS disabled. Enter any 6 digits, then Verify & Continue.',
      );
      return;
    }

    final phone = _normalizedPhone();
    if (phone.length < 8) {
      _snack('Enter valid phone number with country code.');
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      if (!mounted) return;
      setState(() => _otpSent = true);
      _snack('OTP sent successfully.');
      _digitFocus.first.requestFocus();
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Failed to send OTP: $e');
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtpAndContinue() async {
    if (!_otpSent) {
      await _sendOtp();
      return;
    }
    if (!_isComplete) {
      _snack('Enter 6-digit OTP code.');
      return;
    }

    setState(() => _verifyingOtp = true);
    try {
      User? user;

      if (AppEnv.devOtpBypass) {
        final creds = AppEnv.bypassEmailPasswordForRole(_role);
        if (creds == null) {
          _snack(
            'DEV_OTP_BYPASS is on but .env is missing DEV_BYPASS_*_EMAIL / PASSWORD for this role.',
          );
          return;
        }
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: creds.$1,
          password: creds.$2,
        );
        user = res.user ?? Supabase.instance.client.auth.currentUser;
      } else {
        final response = await Supabase.instance.client.auth.verifyOTP(
          phone: _normalizedPhone(),
          token: _otpCode,
          type: OtpType.sms,
        );
        user = response.user ?? Supabase.instance.client.auth.currentUser;
      }

      final resolvedUser = user;
      if (resolvedUser == null) {
        _snack('OTP verification failed. Try again.');
        return;
      }

      final phoneForProfile = () {
        final p = _normalizedPhone();
        return p.length >= 8 ? p : null;
      }();

      await Backend.repo.upsertProfile(
        userId: resolvedUser.id,
        role: _role.name,
        fullName: _role == AppRole.caregiver ? 'New Caregiver' : 'New User',
        phone: phoneForProfile,
      );

      AppSession.setRole(
        role: _role,
        userId: resolvedUser.id,
        patientId: _role == AppRole.patient ? resolvedUser.id : null,
      );

      if (!mounted) return;
      switch (_role) {
        case AppRole.patient:
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.patientHome,
            (route) => false,
          );
          break;
        case AppRole.caregiver:
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.caregiverRegistration,
            (route) => false,
          );
          break;
        case AppRole.doctor:
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.doctorDashboard,
            (route) => false,
          );
          break;
      }
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('OTP verify failed: $e');
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
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

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _entranceController,
                _pulseController,
              ]),
              builder: (context, _) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                'DEV: OTP bypass on — any 6 digits. Turn off DEV_OTP_BYPASS before release.',
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
                            _otpSent ? 'Verify OTP' : 'Sign In with Phone',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontFamily: 'KhayalRoboto',
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                              color: _title,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _otpSent
                                ? 'Enter the 6-digit code sent to your phone'
                                : 'Use your phone number to continue',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              fontFamily: 'KhayalRoboto',
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
                            decoration: InputDecoration(
                              hintText: '+923001234567',
                              labelText: 'Phone Number',
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
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _sendingOtp ? null : _sendOtp,
                            child: Text(_sendingOtp ? 'Sending...' : 'Send OTP'),
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 10.0;
                              final rowWidth = constraints.maxWidth;
                              final cellW = (rowWidth - 5 * gap) / 6;
                              final w = cellW.clamp(44.0, 56.0);
                              final totalRow = 6 * w + 5 * gap;

                              return Column(
                                children: [
                                  SizedBox(
                                    width: totalRow,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        6,
                                        (i) => _OtpCell(
                                          width: w,
                                          digitColor: _title,
                                          controller: _digitControllers[i],
                                          focusNode: _digitFocus[i],
                                          fill: _cellFill,
                                          borderIdle: _cellBorderIdle,
                                          borderFocus: _cellBorderFocus,
                                          pulse: _pulseAnimation.value,
                                          isFocused: _digitFocus[i].hasFocus,
                                          onChanged: (v) => _onDigitChanged(
                                            i,
                                            v,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  SizedBox(
                                    width: totalRow,
                                    child: _LinkAccountButton(
                                      scale: _buttonScale,
                                      enabled: _isComplete,
                                      label:
                                          _verifyingOtp
                                              ? 'Verifying...'
                                              : _otpSent
                                              ? 'Verify & Continue'
                                              : 'Send OTP',
                                      mutedColor: _ctaMuted,
                                      readyColor: _ctaReady,
                                      onTap: _verifyOtpAndContinue,
                                      onTapDown:
                                          () => setState(() {
                                            _buttonScale = 0.96;
                                          }),
                                      onTapEnd:
                                          () => setState(() {
                                            _buttonScale = 1;
                                          }),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.width,
    required this.digitColor,
    required this.controller,
    required this.focusNode,
    required this.fill,
    required this.borderIdle,
    required this.borderFocus,
    required this.pulse,
    required this.isFocused,
    required this.onChanged,
  });

  final double width;
  final Color digitColor;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color fill;
  final Color borderIdle;
  final Color borderFocus;
  final double pulse;
  final bool isFocused;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        Color.lerp(borderIdle, borderFocus, isFocused ? pulse * 0.35 + 0.65 : 0)!;
    final borderWidth = isFocused ? 1.8 + pulse * 0.4 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: width,
      height: width * 1.12,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow:
            isFocused
                ? [
                  BoxShadow(
                    color: borderFocus.withValues(alpha: 0.22 * pulse),
                    blurRadius: 8 + 6 * pulse,
                    spreadRadius: 0.5 * pulse,
                  ),
                ]
                : null,
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'KhayalRoboto',
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: digitColor,
            height: 1,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LinkAccountButton extends StatelessWidget {
  const _LinkAccountButton({
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
    final canTap = enabled;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: canTap ? 0.28 : 0.12),
              blurRadius: canTap ? 18 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: canTap ? onTap : null,
            onTapDown: canTap ? (_) => onTapDown() : null,
            onTapCancel: canTap ? onTapEnd : null,
            onTapUp: canTap ? (_) => onTapEnd() : null,
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
