import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../caregiver_colors.dart';

enum _AlertTone { escalated, reminder }

class _AlertItem {
  const _AlertItem({
    required this.titleEn,
    required this.titleUr,
    required this.tone,
    required this.scheduled,
    required this.missedAt,
    required this.dateLine,
    required this.bannerText,
    required this.showEscalatedChip,
  });

  final String titleEn;
  final String titleUr;
  final _AlertTone tone;
  final String scheduled;
  final String missedAt;
  final String dateLine;
  final String bannerText;
  final bool showEscalatedChip;
}

/// Caregiver alert log with color-coded severity and message banners.
class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const List<_AlertItem> _alerts = [
    _AlertItem(
      titleEn: 'Blood Pressure Medicine',
      titleUr: 'بلڈ پریشر کی دوا',
      tone: _AlertTone.escalated,
      scheduled: '10:00',
      missedAt: '10:30',
      dateLine: 'Monday, May 4',
      bannerText:
          'Patient did not take medication for 30 minutes. Please check.',
      showEscalatedChip: true,
    ),
    _AlertItem(
      titleEn: 'Vitamin D',
      titleUr: 'وٹامن ڈی',
      tone: _AlertTone.reminder,
      scheduled: '12:00',
      missedAt: '12:20',
      dateLine: 'Monday, May 4',
      bannerText: 'Medication reminder needed.',
      showEscalatedChip: false,
    ),
    _AlertItem(
      titleEn: 'Metformin',
      titleUr: 'میٹفارمن',
      tone: _AlertTone.reminder,
      scheduled: '21:00',
      missedAt: '21:15',
      dateLine: 'Sunday, May 3',
      bannerText: 'Medication reminder needed.',
      showEscalatedChip: false,
    ),
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _animFor(int index) {
    final start = (0.05 + index * 0.12).clamp(0.0, 0.65);
    final end = (0.5 + index * 0.15).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaregiverColors.canvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CaregiverColors.header,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'KhayalRoboto',
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              '${_alerts.length} alerts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'KhayalRoboto',
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        physics: const BouncingScrollPhysics(),
        itemCount: _alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final a = _animFor(index);
          return FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(a),
              child: _AlertCard(item: _alerts[index]),
            ),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatefulWidget {
  const _AlertCard({required this.item});

  final _AlertItem item;

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isRed = item.tone == _AlertTone.escalated;
    final accent =
        isRed ? CaregiverColors.alertRed : CaregiverColors.alertOrange;
    final soft =
        isRed ? CaregiverColors.missedSoft : CaregiverColors.upcomingSoft;

    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.99),
      onPointerUp: (_) => setState(() => _scale = 1),
      onPointerCancel: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Material(
          color: CaregiverColors.card,
          elevation: 1.5,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => HapticFeedback.selectionClick(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 5, color: accent),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: soft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.priority_high_rounded,
                                      color: accent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.titleEn,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            fontFamily: 'KhayalRoboto',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: CaregiverColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.titleUr,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            fontFamily: 'NotoNastaliqUrdu',
                                            fontSize: 15,
                                            height: 1.35,
                                            color: CaregiverColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.showEscalatedChip)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CaregiverColors.missedSoft,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'Escalated',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall?.copyWith(
                                          fontFamily: 'KhayalRoboto',
                                          fontWeight: FontWeight.w800,
                                          color: CaregiverColors.alertRed,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _metaRow(
                                context,
                                Icons.schedule_rounded,
                                'Scheduled: ${item.scheduled}',
                              ),
                              const SizedBox(height: 6),
                              _metaRow(
                                context,
                                Icons.error_outline_rounded,
                                'Missed at: ${item.missedAt}',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.dateLine,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'KhayalRoboto',
                                  color: CaregiverColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _BannerStrip(
                  accent: accent,
                  soft: soft,
                  isRed: isRed,
                  text: item.bannerText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CaregiverColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'KhayalRoboto',
              color: CaregiverColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerStrip extends StatelessWidget {
  const _BannerStrip({
    required this.accent,
    required this.soft,
    required this.isRed,
    required this.text,
  });

  final Color accent;
  final Color soft;
  final bool isRed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRed ? Icons.warning_amber_rounded : Icons.alarm_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'KhayalRoboto',
                color: CaregiverColors.textPrimary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
