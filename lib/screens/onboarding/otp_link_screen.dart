import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation/app_routes.dart';

/// Caregiver OTP link — six cells, sage CTA, entrance + focus + press motion.
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

  double _buttonScale = 1;

  bool get _isComplete =>
      _digitControllers.every((c) => c.text.trim().isNotEmpty);

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

  void _linkAccount() {
    if (!_isComplete) return;
    Navigator.pushNamed(context, AppRoutes.caregiverDashboard);
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
                          Text(
                            'Link to Patient',
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
                            "Enter the 6-digit code shown on patient's phone",
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
                                      mutedColor: _ctaMuted,
                                      readyColor: _ctaReady,
                                      onTap: _linkAccount,
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
    required this.mutedColor,
    required this.readyColor,
    required this.onTap,
    required this.onTapDown,
    required this.onTapEnd,
  });

  final double scale;
  final bool enabled;
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
                'Link Account',
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
