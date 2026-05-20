import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/medication/dose_missed_sync.dart';
import '../../../core/reminders/medication_notification_service.dart';
import '../../../core/reminders/medication_reminder_watcher.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../widgets/patient_home_drawer.dart';
import '../../../core/time/medication_dose_status.dart';
import '../../../core/time/pakistan_time.dart';
import '../../../core/ui/patient_shell_colors.dart';

/// Patient home — today's doses with animated list and floating summary pill.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

enum _MedStatus { taken, upcoming, dueSoon, missed }

class _MedSchedule {
  const _MedSchedule({
    required this.medicationId,
    required this.nameEn,
    required this.nameUr,
    required this.time,
    required this.doseEn,
    required this.doseUr,
    required this.status,
    this.scheduleRaw,
    this.takenSlots = 0,
    this.totalSlots = 1,
    this.imageStoragePath,
  });

  final String medicationId;
  final String nameEn;
  final String nameUr;
  final String time;
  final String doseEn;
  final String doseUr;
  final _MedStatus status;
  final String? scheduleRaw;
  final int takenSlots;
  final int totalSlots;
  final String? imageStoragePath;
}

class _PatientHomeScreenState extends State<PatientHomeScreen>
    with
        TickerProviderStateMixin,
        MedicationReminderWatcherMixin,
        WidgetsBindingObserver {
  static const Color _summarySurface = Color(0xFFFEFCF8);
  static const Color _summaryBorder = Color(0xFFE8E4DC);
  static const Color _mutedLabel = Color(0xFF8A8A8A);

  static const Color _takenIcon = Color(0xFF2E7D32);
  static const Color _upcomingIcon = Color(0xFFEF6C00);
  static const Color _dueSoonIcon = Color(0xFFC62828);
  static const Color _missedIcon = Color(0xFFC62828);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final AnimationController _listController;
  late final AnimationController _summaryController;

  Timer? _statusRefreshTimer;
  bool _loadingMeds = true;
  String? _loadError;
  List<_MedSchedule> _items = [];
  List<MedicationRecord> _medRecords = [];
  Set<String> _takenSlotKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      MedicationNotificationService.instance.requestAndroidPermissions();
      MedicationNotificationService.instance.consumePendingLaunchNavigation(
        context,
      );
      _listController.forward();
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (mounted) _summaryController.forward();
      });
    });
    _loadMeds();
    _statusRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshDoseStatuses(),
    );
  }

  Future<void> _refreshDoseStatuses() async {
    if (!mounted || _medRecords.isEmpty) return;
    final uid =
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (uid != null && uid.isNotEmpty) {
      await DoseMissedSync.syncForPatient(uid);
    }
    if (!mounted) return;
    setState(() {
      _items = _medRecords.map(_fromRecord).toList();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMeds();
    }
  }

  Future<void> _loadMeds() async {
    final uid =
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingMeds = false;
          _loadError = 'Not signed in.';
          _items = [];
        });
      }
      syncMedicationReminders(const []);
      await MedicationNotificationService.instance.cancelAllDoseReminders();
      return;
    }

    setState(() {
      _loadingMeds = true;
      _loadError = null;
    });

    try {
      final rows = await Backend.repo.getMedicationsForPatient(uid);

      Set<String> takenSlots = {};
      try {
        takenSlots = await Backend.repo.getTodayTakenDoseSlotKeys(uid);
      } catch (e) {
        debugPrint('khayal_platform: dose_logs for home skipped: $e');
      }

      await DoseMissedSync.syncForPatient(uid);

      if (!mounted) return;
      setState(() {
        _medRecords = rows;
        _takenSlotKeys = takenSlots;
        _items = rows.map(_fromRecord).toList();
        _loadingMeds = false;
        _loadError = null;
      });

      syncMedicationReminders(rows);
      await MedicationNotificationService.instance.requestAndroidPermissions(
        force: true,
      );
      await MedicationNotificationService.instance.syncSchedules(
        patientId: uid,
        meds: rows,
      );
    } catch (e) {
      debugPrint('khayal_platform: patient home meds load failed: $e');
      if (!mounted) return;
      setState(() {
        _loadingMeds = false;
        _loadError = e.toString();
        _items = [];
        _medRecords = [];
      });
      syncMedicationReminders(const []);
      await MedicationNotificationService.instance.syncSchedules(
        patientId: uid,
        meds: const [],
      );
    }
  }

  List<String> _scheduleRawsFor(MedicationRecord r) {
    if (r.scheduleRaws.isNotEmpty) {
      return r.scheduleRaws
          .where((s) => s.isNotEmpty && s != '--:--')
          .toList();
    }
    final first = r.firstScheduleRaw;
    if (first == null || first.isEmpty || first == '--:--') return const [];
    return [first];
  }

  _MedSchedule _fromRecord(MedicationRecord r) {
    final raws = _scheduleRawsFor(r);
    final nextRaw =
        MedicationDoseStatusLogic.nextActionableScheduleRaw(raws) ??
            r.firstScheduleRaw;

    final totalSlots = raws.length;
    final takenSlots = MedicationDoseStatusLogic.countTakenSlotsForMedication(
      medicationId: r.id,
      scheduleRaws: raws,
      takenSlotKeys: _takenSlotKeys,
    );

    final _MedStatus status;
    if (totalSlots > 0 && takenSlots >= totalSlots) {
      status = _MedStatus.taken;
    } else {
      status = switch (MedicationDoseStatusLogic.statusForMedicationSlots(
        scheduleRaws: raws,
        takenSlotKeys: _takenSlotKeys,
        medicationId: r.id,
      )) {
        MedicationDoseStatus.upcoming => _MedStatus.upcoming,
        MedicationDoseStatus.dueSoon => _MedStatus.dueSoon,
        MedicationDoseStatus.missed => _MedStatus.missed,
      };
    }

    return _MedSchedule(
      medicationId: r.id,
      nameEn: r.nameEn,
      nameUr: r.nameUr,
      time: r.timeLabel,
      doseEn: r.doseLabel,
      doseUr: r.doseLabel,
      status: status,
      scheduleRaw: nextRaw,
      takenSlots: takenSlots,
      totalSlots: totalSlots > 0 ? totalSlots : 1,
      imageStoragePath: r.imageStoragePath,
    );
  }

  TodayDoseSlotCounts _slotCounts() {
    return MedicationDoseStatusLogic.countTodaySlots(
      meds: _medRecords.map(
        (r) => (medicationId: r.id, scheduleRaws: _scheduleRawsFor(r)),
      ),
      takenSlotKeys: _takenSlotKeys,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusRefreshTimer?.cancel();
    disposeMedicationReminders();
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

  void _openForItem(_MedSchedule item) {
    AppSession.pendingDoseReminder = PendingDoseReminder(
      medicationId: item.medicationId,
      nameEn: item.nameEn,
      nameUr: item.nameUr,
      timeDisplay: item.time,
      doseUr: item.doseUr,
      scheduleRaw: item.scheduleRaw,
      imageStoragePath: item.imageStoragePath,
    );
    if (item.status == _MedStatus.upcoming ||
        item.status == _MedStatus.dueSoon) {
      Navigator.pushNamed(context, AppRoutes.doseConfirmation)
          .then((_) => _loadMeds());
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.medicationDetail,
        arguments: item.medicationId,
      );
    }
  }

  Future<void> _generatePatientLinkCode() async {
    final userId = AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session missing. Login again.')),
      );
      return;
    }
    final phone = await Backend.repo.resolvePatientLinkPhone(userId);
    if (!mounted) return;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No phone on your profile. Sign in as patient with your phone number first.',
          ),
        ),
      );
      return;
    }
    try {
      final code = await Backend.repo.createPatientLinkCode(
        patientPhone: phone,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Link code'),
          content: Text(
            'Share this code with your caregiver or doctor:\n\n$code',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate code: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final bottomInset = mq.padding.bottom;
    final today = PakistanTime.now();
    final slotCounts = _slotCounts();
    const quickActionsHeight = 84.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: PatientShellColors.canvas,
      drawer: const PatientHomeDrawer(),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(
                topPadding: topInset,
                dateLabel: _formatHeaderDate(today),
                onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                onGenerateCode: _generatePatientLinkCode,
              ),
              _PatientQuickActions(
                onNotifications: () {
                  if (_items.isNotEmpty) {
                    final upcoming = _items
                        .where(
                          (e) =>
                              e.status == _MedStatus.upcoming ||
                              e.status == _MedStatus.dueSoon,
                        )
                        .toList();
                    final u = upcoming.isNotEmpty ? upcoming.first : _items.first;
                    AppSession.pendingDoseReminder = PendingDoseReminder(
                      medicationId: u.medicationId,
                      nameEn: u.nameEn,
                      nameUr: u.nameUr,
                      timeDisplay: u.time,
                      doseUr: u.doseUr,
                      scheduleRaw: u.scheduleRaw,
                      imageStoragePath: u.imageStoragePath,
                    );
                  }
                  Navigator.pushNamed(
                    context,
                    AppRoutes.notificationOverlay,
                  );
                },
                onHistory: () =>
                    Navigator.pushNamed(context, AppRoutes.patientHistory),
                onSettings: () =>
                    Navigator.pushNamed(context, AppRoutes.settings),
              ),
              Expanded(
                child: _loadingMeds
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: PatientShellColors.header,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                AppLanguageState.pick(
                                  en: 'Loading your medicines…',
                                  ur: 'دوائیں لوڈ ہو رہی ہیں…',
                                ),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontFamily: 'KhayalRoboto',
                                      fontWeight: FontWeight.w700,
                                      color: PatientShellColors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _loadError != null
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          18,
                          18,
                          bottomInset + 112 + quickActionsHeight,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.medication_outlined,
                            size: 52,
                            color: PatientShellColors.header.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load medicines',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontFamily: 'KhayalRoboto',
                                  fontWeight: FontWeight.w800,
                                  color: PatientShellColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: PatientShellColors.textMuted,
                                  height: 1.4,
                                  fontFamily: 'KhayalRoboto',
                                ),
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: FilledButton.icon(
                              onPressed: _loadMeds,
                              style: FilledButton.styleFrom(
                                backgroundColor: PatientShellColors.header,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(
                                AppLanguageState.pick(
                                  en: 'Try again',
                                  ur: 'دوبارہ کوشش',
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _items.isEmpty
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          18,
                          18,
                          bottomInset + 112 + quickActionsHeight,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: PatientShellColors.header.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_moderator_outlined,
                              size: 40,
                              color: PatientShellColors.header,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No medicines scheduled yet.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontFamily: 'KhayalRoboto',
                                  fontWeight: FontWeight.w800,
                                  color: PatientShellColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppLanguageState.pick(
                              en: 'Add your prescriptions so we can remind you on time.',
                              ur: 'اپنی دوائیں شامل کریں تاکہ وقت پر یاد دلایا جا سکے۔',
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: PatientShellColors.textMuted,
                                  height: 1.4,
                                  fontFamily: AppLanguageState.isUrdu
                                      ? 'NotoNastaliqUrdu'
                                      : 'KhayalRoboto',
                                ),
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: FilledButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.medicationManagement,
                                );
                                _loadMeds();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: PatientShellColors.header,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(
                                AppLanguageState.pick(
                                  en: 'Add medicine',
                                  ur: 'دوا شامل کریں',
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    bottomInset + 112 + quickActionsHeight,
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
                      curve: Interval(start, end, curve: Curves.easeOutCubic),
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
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1.15),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _summaryController,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: _FloatingSummaryBar(
                  taken: slotCounts.taken,
                  missed: slotCounts.missed,
                  upcoming: slotCounts.upcoming,
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
    required this.onOpenMenu,
    required this.onGenerateCode,
  });

  final double topPadding;
  final String dateLabel;
  final VoidCallback onOpenMenu;
  final VoidCallback onGenerateCode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PatientShellColors.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding + 10, 8, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: 'Menu',
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
              onPressed: onOpenMenu,
              icon: const Icon(Icons.menu_rounded, size: 26),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.todaysMedicines,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: AppLanguageState.isUrdu
                          ? 'NotoNastaliqUrdu'
                          : 'KhayalRoboto',
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
              tooltip: AppStrings.linkCode,
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
              onPressed: onGenerateCode,
              icon: const Icon(Icons.password_rounded, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientQuickActions extends StatelessWidget {
  const _PatientQuickActions({
    required this.onNotifications,
    required this.onHistory,
    required this.onSettings,
  });

  final VoidCallback onNotifications;
  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              _QuickAction(
                icon: Icons.notifications_none_rounded,
                label: AppLanguageState.pick(en: 'Alerts', ur: 'الرٹ'),
                onTap: onNotifications,
              ),
              _QuickAction(
                icon: Icons.history_rounded,
                label: AppLanguageState.pick(en: 'History', ur: 'تاریخ'),
                onTap: onHistory,
              ),
              _QuickAction(
                icon: Icons.settings_outlined,
                label: AppLanguageState.pick(en: 'Settings', ur: 'ترتیبات'),
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: PatientShellColors.header),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: AppLanguageState.isUrdu
                      ? 'NotoNastaliqUrdu'
                      : 'KhayalRoboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
            ],
          ),
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
                        Text(
                          AppLanguageState.pick(
                            en: item.nameEn,
                            ur: item.nameUr,
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontFamily: AppLanguageState.isUrdu
                                    ? 'NotoNastaliqUrdu'
                                    : 'KhayalRoboto',
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: const Color(0xFF1C1C1C),
                              ),
                        ),
                        if (item.totalSlots > 1 &&
                            item.takenSlots > 0 &&
                            item.takenSlots < item.totalSlots)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              AppLanguageState.pick(
                                en:
                                    '${item.takenSlots}/${item.totalSlots} doses taken today',
                                ur:
                                    'آج ${item.takenSlots}/${item.totalSlots} دوائیں لی گئیں',
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.schedule_rounded,
                                size: 17,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.time,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontFamily: 'KhayalRoboto',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      height: 1.35,
                                      color: const Color(0xFF5C5C5C),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                AppLanguageState.pick(
                                  en: item.doseEn,
                                  ur: item.doseUr,
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontFamily: AppLanguageState.isUrdu
                                          ? 'NotoNastaliqUrdu'
                                          : 'KhayalRoboto',
                                      fontSize: 14,
                                      height: 1.3,
                                      color: const Color(0xFF5C5C5C),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(
                              status: item.status,
                              scheduleRaw: item.scheduleRaw,
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
      _MedStatus.taken => (
        _PatientHomeScreenState._takenIcon,
        Icons.check_rounded,
      ),
      _MedStatus.upcoming => (
        _PatientHomeScreenState._upcomingIcon,
        Icons.schedule_rounded,
      ),
      _MedStatus.dueSoon => (
        _PatientHomeScreenState._dueSoonIcon,
        Icons.notifications_active_rounded,
      ),
      _MedStatus.missed => (
        _PatientHomeScreenState._missedIcon,
        Icons.close_rounded,
      ),
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
  const _StatusBadge({required this.status, this.scheduleRaw});

  final _MedStatus status;
  final String? scheduleRaw;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (status) {
      _MedStatus.taken => (
        AppStrings.taken,
        const Color(0xFFE8F5E9),
        const Color(0xFF1B5E20),
      ),
      _MedStatus.upcoming => (
        AppStrings.upcoming,
        const Color(0xFFFFF3E0),
        const Color(0xFFE65100),
      ),
      _MedStatus.dueSoon => (
        MedicationDoseStatusLogic.isBeforeScheduledDose(scheduleRaw)
            ? AppStrings.comingSoon
            : AppStrings.dueNow,
        const Color(0xFFFFEBEE),
        const Color(0xFFC62828),
      ),
      _MedStatus.missed => (
        AppStrings.missed,
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
          fontFamily: AppLanguageState.isUrdu
              ? 'NotoNastaliqUrdu'
              : 'KhayalRoboto',
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
                label: AppStrings.taken,
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
                label: AppStrings.missed,
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
                label: AppStrings.upcoming,
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
