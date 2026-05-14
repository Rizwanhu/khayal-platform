import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared reminder card: bell, med info, primary + snooze actions.
class DoseReminderPanel extends StatefulWidget {
  const DoseReminderPanel({
    super.key,
    required this.nameEn,
    required this.nameUr,
    required this.time,
    required this.doseUr,
    required this.onTookIt,
    required this.onSnooze,
    this.headline = 'Time to Take Medicine!',
  });

  final String nameEn;
  final String nameUr;
  final String time;
  final String doseUr;
  final VoidCallback onTookIt;
  final VoidCallback onSnooze;
  final String headline;

  @override
  State<DoseReminderPanel> createState() => _DoseReminderPanelState();
}

class _DoseReminderPanelState extends State<DoseReminderPanel>
    with SingleTickerProviderStateMixin {
  static const Color _cardBorder = Color(0xFFE8B07A);
  static const Color _infoFill = Color(0xFFF5EBDD);
  static const Color _primaryGreen = Color(0xFF709F7D);
  static const Color _textPrimary = Color(0xFF333333);
  static const Color _bellDisk = Color(0xFFFFE8D9);
  static const Color _bellIcon = Color(0xFFC4955A);
  static const Color _secondaryFill = Color(0xFFF5EBDD);
  static const Color _secondaryText = Color(0xFF4A3F35);

  late final AnimationController _bellController;

  double _primaryScale = 1;
  double _secondaryScale = 1;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _runBellWobble();
    });
  }

  Future<void> _runBellWobble() async {
    for (var i = 0; i < 5; i++) {
      if (!mounted) return;
      await _bellController.forward();
      if (!mounted) return;
      await _bellController.reverse();
    }
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: _cardBorder.withValues(alpha: 0.12),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: Tween<double>(begin: -0.06, end: 0.06).animate(
              CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: _bellDisk,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 34,
                color: _bellIcon,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.headline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'KhayalRoboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  height: 1.25,
                  color: _textPrimary,
                ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: _infoFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5D5C4).withValues(alpha: 0.9),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nameEn,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: _textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.nameUr,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 18,
                        height: 1.4,
                        color: _textPrimary,
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.time,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'KhayalRoboto',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: _textPrimary,
                          ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      widget.doseUr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 15,
                            height: 1.25,
                            color: _textPrimary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Material(
            color: _primaryGreen,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTapDown: (_) => setState(() => _primaryScale = 0.97),
              onTapUp: (_) => setState(() => _primaryScale = 1),
              onTapCancel: () => setState(() => _primaryScale = 1),
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onTookIt();
              },
              child: AnimatedScale(
                scale: _primaryScale,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'I Took It',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontFamily: 'KhayalRoboto',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: _secondaryFill,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTapDown: (_) => setState(() => _secondaryScale = 0.98),
              onTapUp: (_) => setState(() => _secondaryScale = 1),
              onTapCancel: () => setState(() => _secondaryScale = 1),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onSnooze();
              },
              child: AnimatedScale(
                scale: _secondaryScale,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5D5C4).withValues(alpha: 0.95),
                    ),
                  ),
                  child: Text(
                    'Remind me in 15 min',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontFamily: 'KhayalRoboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _secondaryText,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
