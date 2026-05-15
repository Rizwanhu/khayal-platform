import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_routes.dart';

/// Shown after confirming a dose — progress summary and return to home.
class DoseTakenSuccessScreen extends StatefulWidget {
  const DoseTakenSuccessScreen({
    super.key,
    this.takenCount = 2,
    this.totalCount = 3,
  });

  final int takenCount;
  final int totalCount;

  @override
  State<DoseTakenSuccessScreen> createState() => _DoseTakenSuccessScreenState();
}

class _DoseTakenSuccessScreenState extends State<DoseTakenSuccessScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFFF1F5F0);
  static const Color _iconCircle = Color(0xFF76A07F);
  static const Color _sparkle = Color(0xFFE8AA6D);
  static const Color _cardFill = Color(0xFFD9E5D6);
  static const Color _cardBorder = Color(0xFFB8CBB8);
  static const Color _cardText = Color(0xFF4A6B52);
  static const Color _button = Color(0xFF5F856C);
  static const Color _title = Color(0xFF1A1A1A);
  static const Color _subtitle = Color(0xFF6B7280);

  late final AnimationController _heroController;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkOpacity;
  late final AnimationController _sparkleController;
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  double _buttonScale = 1;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _circleScale = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _checkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _heroController.forward();
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _sparkleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _goHome() {
    HapticFeedback.lightImpact();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.patientHome,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: _goHome,
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade700),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _heroController,
                        builder: (context, _) {
                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: -6,
                                right: -10,
                                child: _Sparkle(
                                  animation: _sparkleController,
                                  delay: 0,
                                  color: _sparkle,
                                ),
                              ),
                              Positioned(
                                bottom: -8,
                                left: -12,
                                child: _Sparkle(
                                  animation: _sparkleController,
                                  delay: 0.35,
                                  color: _sparkle,
                                ),
                              ),
                              Transform.scale(
                                scale: _circleScale.value,
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: _iconCircle,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _iconCircle.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Opacity(
                                    opacity: _checkOpacity.value,
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 52,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _contentFade,
                        child: SlideTransition(
                          position: _contentSlide,
                          child: Column(
                            children: [
                              Text(
                                'Well Done!',
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontFamily: 'KhayalRoboto',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  color: _title,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You took your medicine on time. Great job!',
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'KhayalRoboto',
                                  fontSize: 16,
                                  height: 1.45,
                                  color: _subtitle,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: _cardFill,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _cardBorder),
                                ),
                                child: Text(
                                  "You've taken ${widget.takenCount} out of ${widget.totalCount} medicines today.",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontFamily: 'KhayalRoboto',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 1.4,
                                    color: _cardText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Listener(
                    onPointerDown: (_) => setState(() => _buttonScale = 0.97),
                    onPointerUp: (_) => setState(() => _buttonScale = 1),
                    onPointerCancel: (_) => setState(() => _buttonScale = 1),
                    child: AnimatedScale(
                      scale: _buttonScale,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _button,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: _button.withValues(alpha: 0.45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontFamily: 'KhayalRoboto',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.patientHome,
                              (route) => false,
                            );
                          },
                          child: const Text('Back to Home'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.animation,
    required this.delay,
    required this.color,
  });

  final Animation<double> animation;
  final double delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = (animation.value + delay) % 1.0;
        final scale = 0.75 + 0.35 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
        return Transform.rotate(
          angle: t * 0.4,
          child: Transform.scale(
            scale: scale,
            child: Icon(Icons.auto_awesome, size: 22, color: color),
          ),
        );
      },
    );
  }
}
