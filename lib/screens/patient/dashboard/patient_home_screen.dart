import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_routes.dart';

/// Patient home — today's doses with animated list and floating summary pill.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

enum _MedStatus { taken, upcoming, missed }

class _MedSchedule {
  const _MedSchedule({
    required this.nameEn,
    required this.nameUr,
    required this.time,
    required this.doseUr,
    required this.status,
  });

  final String nameEn;
  final String nameUr;
  final String time;
  final String doseUr;
  final _MedStatus status;
}

class _PatientHomeScreenState extends State<PatientHomeScreen>
    with TickerProviderStateMixin {
  static const Color _headerGreen = Color(0xFF608266);
  static const Color _contentBg = Color(0xFFF9F8F3);
  static const Color _summarySurface = Color(0xFFFEFCF8);
  static const Color _summaryBorder = Color(0xFFE8E4DC);
  static const Color _mutedLabel = Color(0xFF8A8A8A);

  static const Color _takenIcon = Color(0xFF2E7D32);
  static const Color _upcomingIcon = Color(0xFFEF6C00);
  static const Color _missedIcon = Color(0xFFC62828);

  late final AnimationController _listController;
  late final AnimationController _summaryController;

  /// Demo schedule — counts: 2 taken, 1 missed, 1 upcoming.
  final List<_MedSchedule> _items = const [
    _MedSchedule(
      nameEn: 'Paracetamol',
      nameUr: 'پیراسیٹامول',
      time: '08:00',
      doseUr: '1 گولی',
      status: _MedStatus.upcoming,
    ),
    _MedSchedule(
      nameEn: 'Metformin',
      nameUr: 'میٹفارمن',
      time: '09:30',
      doseUr: '1 گولی',
      status: _MedStatus.taken,
    ),
    _MedSchedule(
      nameEn: 'Vitamin D',
      nameUr: 'وٹامن ڈی',
      time: '12:00',
      doseUr: '1 کیپسول',
      status: _MedStatus.taken,
    ),
    _MedSchedule(
      nameEn: 'Lisinopril',
      nameUr: 'لسینوپریل',
      time: '20:00',
      doseUr: '1 گولی',
      status: _MedStatus.missed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    );
    _summaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _listController.forward();
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (mounted) _summaryController.forward();
      });
    });
  }

  @override
  void dispose() {
    _listController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  String _formatHeaderDate(DateTime d) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  int _count(_MedStatus s) => _items.where((e) => e.status == s).length;

  void _openForItem(_MedSchedule item) {
    if (item.status == _MedStatus.upcoming) {
      Navigator.pushNamed(context, AppRoutes.doseConfirmation);
    } else {
      Navigator.pushNamed(context, AppRoutes.medicationDetail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final bottomInset = mq.padding.bottom;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: _contentBg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(
                topPadding: topInset,
                dateLabel: _formatHeaderDate(today),
                onNotifications: () => Navigator.pushNamed(
                  context,
                  AppRoutes.notificationOverlay,
                ),
                onSettings: () => Navigator.pushNamed(context, AppRoutes.settings),
                onHistory: () =>
                    Navigator.pushNamed(context, AppRoutes.patientHistory),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    bottomInset + 112,
                  ),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final start = (index * 0.09).clamp(0.0, 0.55);
                    final end = (0.42 + index * 0.11).clamp(0.0, 1.0);
                    final curve = CurvedAnimation(
                      parent: _listController,
                      curve: Interval(
                        start,
                        end,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return FadeTransition(
                      opacity: curve,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.14),
                          end: Offset.zero,
                        ).animate(curve),
                        child: _MedicineCard(
                          item: item,
                          onTap: () => _openForItem(item),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomInset + 14,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _summaryController,
                curve: const Interval(0, 0.65, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1.15),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _summaryController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: _FloatingSummaryBar(
                  taken: _count(_MedStatus.taken),
                  missed: _count(_MedStatus.missed),
                  upcoming: _count(_MedStatus.upcoming),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.topPadding,
    required this.dateLabel,
    required this.onNotifications,
    required this.onSettings,
    required this.onHistory,
  });

  final double topPadding;
  final String dateLabel;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _PatientHomeScreenState._headerGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding + 10, 12, 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Medicines",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontFamily: 'KhayalRoboto',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          height: 1.15,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'KhayalRoboto',
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'History',
              onPressed: onHistory,
              icon: Icon(
                Icons.history_rounded,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            IconButton(
              tooltip: 'Alerts',
              onPressed: onNotifications,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: onSettings,
              icon: Icon(
                Icons.settings_outlined,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineCard extends StatefulWidget {
  const _MedicineCard({required this.item, required this.onTap});

  final _MedSchedule item;
  final VoidCallback onTap;

  @override
  State<_MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<_MedicineCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.985),
      onPointerUp: (_) => setState(() => _scale = 1),
      onPointerCancel: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusIconCircle(status: item.status),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nameEn,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontFamily: 'KhayalRoboto',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17,
                                          color: const Color(0xFF1C1C1C),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.nameUr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontFamily: 'NotoNastaliqUrdu',
                                          fontSize: 17,
                                          height: 1.45,
                                          color: const Color(0xFF2B2B2B),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 17,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.time,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'KhayalRoboto',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: const Color(0xFF5C5C5C),
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.doseUr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'NotoNastaliqUrdu',
                                    fontSize: 15,
                                    height: 1.3,
                                    color: const Color(0xFF5C5C5C),
                                  ),
                            ),
                          ],
                        ),
                      ],
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

class _StatusIconCircle extends StatelessWidget {
  const _StatusIconCircle({required this.status});

  final _MedStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, IconData icon) = switch (status) {
      _MedStatus.taken => (_PatientHomeScreenState._takenIcon, Icons.check_rounded),
      _MedStatus.upcoming => (
        _PatientHomeScreenState._upcomingIcon,
        Icons.schedule_rounded,
      ),
      _MedStatus.missed => (_PatientHomeScreenState._missedIcon, Icons.close_rounded),
    };

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _MedStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (status) {
      _MedStatus.taken => (
        'Taken',
        const Color(0xFFE8F5E9),
        const Color(0xFF1B5E20),
      ),
      _MedStatus.upcoming => (
        'Upcoming',
        const Color(0xFFFFF3E0),
        const Color(0xFFE65100),
      ),
      _MedStatus.missed => (
        'Missed',
        const Color(0xFFFFEBEE),
        const Color(0xFFC62828),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontFamily: 'KhayalRoboto',
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _FloatingSummaryBar extends StatefulWidget {
  const _FloatingSummaryBar({
    required this.taken,
    required this.missed,
    required this.upcoming,
  });

  final int taken;
  final int missed;
  final int upcoming;

  @override
  State<_FloatingSummaryBar> createState() => _FloatingSummaryBarState();
}

class _FloatingSummaryBarState extends State<_FloatingSummaryBar> {
  int? _pressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _PatientHomeScreenState._summarySurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _PatientHomeScreenState._summaryBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummarySegment(
                value: widget.taken,
                label: 'Taken',
                valueColor: _PatientHomeScreenState._takenIcon,
                pressed: _pressed == 0,
                onTapDown: () => setState(() => _pressed = 0),
                onTapEnd: () => setState(() => _pressed = null),
                onTap: () => HapticFeedback.selectionClick(),
              ),
            ),
            _SummaryDivider(),
            Expanded(
              child: _SummarySegment(
                value: widget.missed,
                label: 'Missed',
                valueColor: _PatientHomeScreenState._missedIcon,
                pressed: _pressed == 1,
                onTapDown: () => setState(() => _pressed = 1),
                onTapEnd: () => setState(() => _pressed = null),
                onTap: () => HapticFeedback.selectionClick(),
              ),
            ),
            _SummaryDivider(),
            Expanded(
              child: _SummarySegment(
                value: widget.upcoming,
                label: 'Upcoming',
                valueColor: _PatientHomeScreenState._upcomingIcon,
                pressed: _pressed == 2,
                onTapDown: () => setState(() => _pressed = 2),
                onTapEnd: () => setState(() => _pressed = null),
                onTap: () => HapticFeedback.selectionClick(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _PatientHomeScreenState._summaryBorder.withValues(alpha: 0.15),
            _PatientHomeScreenState._summaryBorder.withValues(alpha: 0.65),
            _PatientHomeScreenState._summaryBorder.withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }
}

class _SummarySegment extends StatelessWidget {
  const _SummarySegment({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.pressed,
    required this.onTapDown,
    required this.onTapEnd,
    required this.onTap,
  });

  final int value;
  final String label;
  final Color valueColor;
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTapDown: (_) => onTapDown(),
        onTapCancel: onTapEnd,
        onTapUp: (_) => onTapEnd(),
        onTap: onTap,
        child: AnimatedScale(
          scale: pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: valueColor,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontFamily: 'KhayalRoboto',
                        color: _PatientHomeScreenState._mutedLabel,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
