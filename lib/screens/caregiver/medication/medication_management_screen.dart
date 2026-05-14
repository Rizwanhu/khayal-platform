import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_routes.dart';
import '../caregiver_colors.dart';

class _MedListItem {
  const _MedListItem({
    required this.en,
    required this.ur,
    required this.schedule,
    required this.times,
  });

  final String en;
  final String ur;
  final String schedule;
  final String times;
}

/// Full medication list for a patient — matches dashboard list styling.
class MedicationManagementScreen extends StatefulWidget {
  const MedicationManagementScreen({super.key});

  @override
  State<MedicationManagementScreen> createState() =>
      _MedicationManagementScreenState();
}

class _MedicationManagementScreenState extends State<MedicationManagementScreen>
    with SingleTickerProviderStateMixin {
  static const List<_MedListItem> _items = [
    _MedListItem(
      en: 'Paracetamol',
      ur: 'پیراسیٹامول',
      schedule: '1 tablet • 3x daily',
      times: '08:00, 14:00, 20:00',
    ),
    _MedListItem(
      en: 'Metformin',
      ur: 'میٹفارمن',
      schedule: '2 tablets • 2x daily',
      times: '09:00, 21:00',
    ),
    _MedListItem(
      en: 'Omeprazole',
      ur: 'اومیپرازول',
      schedule: '1 capsule • 1x daily',
      times: '07:30',
    ),
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
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

  Animation<double> _anim(int i) {
    final start = (0.06 + i * 0.12).clamp(0.0, 0.65);
    final end = (0.5 + i * 0.15).clamp(0.0, 1.0);
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
        title: Text(
          'Medications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'KhayalRoboto',
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.addMedication);
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 1, curve: Curves.elasticOut),
          ),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: CaregiverColors.headerForm,
          foregroundColor: Colors.white,
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pushNamed(context, AppRoutes.addMedication);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add', style: TextStyle(fontFamily: 'KhayalRoboto', fontWeight: FontWeight.w700)),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        physics: const BouncingScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          final a = _anim(index);
          return FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(a),
              child: _MedTile(
                item: item,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, AppRoutes.editMedication);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MedTile extends StatefulWidget {
  const _MedTile({required this.item, required this.onTap});

  final _MedListItem item;
  final VoidCallback onTap;

  @override
  State<_MedTile> createState() => _MedTileState();
}

class _MedTileState extends State<_MedTile> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.99),
      onPointerUp: (_) => setState(() => _scale = 1),
      onPointerCancel: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Material(
          elevation: 2,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(18),
          color: CaregiverColors.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                decoration: BoxDecoration(
                  color: CaregiverColors.pillRowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.en,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontFamily: 'KhayalRoboto',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: CaregiverColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.ur,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'NotoNastaliqUrdu',
                                  fontSize: 16,
                                  height: 1.35,
                                  color: CaregiverColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.schedule,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'KhayalRoboto',
                                  color: CaregiverColors.textMuted,
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.times,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontFamily: 'KhayalRoboto',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: CaregiverColors.textMuted,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: CaregiverColors.header.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
