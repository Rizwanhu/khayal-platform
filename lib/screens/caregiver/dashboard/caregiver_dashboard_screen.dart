import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/app_session.dart';
import '../../../core/backend/backend.dart';
import '../../../core/reminders/medication_reminder_watcher.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/navigation/app_routes.dart';
import '../caregiver_colors.dart';

/// Caregiver overview: status, adherence chart, medications, FAB.
class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen>
    with TickerProviderStateMixin, MedicationReminderWatcherMixin {
  late final AnimationController _entrance;

  List<MedicationRecord> _medications = const [];
  String _patientName = 'Loading...';
  bool _loading = true;
  String? _error;
  int _todayTaken = 0;
  int _todayMissed = 0;
  int _todayUpcoming = 0;
  List<WeeklyAdherenceDay> _weeklyDays = const [];
  int _overallPercent = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final caregiverId =
        AppSession.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (caregiverId == null || caregiverId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Missing caregiver session.';
        _patientName = 'No Patient';
      });
      syncMedicationReminders(const []);
      return;
    }

    try {
      final patientId = await Backend.repo.getFirstPatientForCaregiver(
        caregiverId,
      );
      if (patientId == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'No linked patient found.';
          _patientName = 'No Patient';
        });
        syncMedicationReminders(const []);
        return;
      }
      AppSession.selectedPatientId = patientId;

      final profile = await Backend.repo.getPatientProfile(patientId);
      final meds = await Backend.repo.getMedicationsForPatient(patientId);
      final adherence = await Backend.repo.getPatientAdherenceSummary(patientId);

      if (!mounted) return;
      setState(() {
        _patientName = profile?.fullName ?? 'Unknown Patient';
        _medications = meds;
        _todayTaken = adherence.todayTaken;
        _todayMissed = adherence.todayMissed;
        _todayUpcoming = adherence.todayUpcoming;
        _weeklyDays = adherence.weeklyDays;
        _overallPercent = adherence.overallPercent;
        _loading = false;
        _error = null;
      });
      syncMedicationReminders(meds);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load dashboard: $e';
        _patientName = 'Error';
      });
      syncMedicationReminders(const []);
    }
  }

  @override
  void dispose() {
    disposeMedicationReminders();
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _slot(int i) {
    final start = (0.06 + i * 0.1).clamp(0.0, 0.72);
    final end = (0.45 + i * 0.12).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaregiverColors.canvas,
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _entrance,
            curve: const Interval(0.55, 1, curve: Curves.elasticOut),
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: CaregiverColors.header,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pushNamed(context, AppRoutes.addMedication).then((_) {
              if (mounted) _loadDashboardData();
            });
          },
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _animated(0, _todayStatusCard(context)),
                const SizedBox(height: 16),
                _animated(1, _weeklyAdherenceCard(context)),
                const SizedBox(height: 16),
                _animated(2, _overallAdherenceCard(context)),
                const SizedBox(height: 16),
                _animated(3, _medicationsCard(context)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animated(int slot, Widget child) {
    final a = _slot(slot);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final a = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.35, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.06),
          end: Offset.zero,
        ).animate(a),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 14,
            16,
            22,
          ),
          decoration: BoxDecoration(
            color: CaregiverColors.header,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontFamily: 'KhayalRoboto',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Patient: $_patientName',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'KhayalRoboto',
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, AppRoutes.settings);
                      },
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final meds = _medications;
                        if (meds.isNotEmpty) {
                          final m = meds.first;
                          AppSession.pendingDoseReminder = PendingDoseReminder(
                            medicationId: m.id,
                            nameEn: m.nameEn,
                            nameUr: m.nameUr,
                            timeDisplay: m.timeLabel,
                            doseUr: m.doseLabel,
                            scheduleRaw: m.firstScheduleRaw,
                          );
                        }
                        Navigator.pushNamed(
                          context,
                          AppRoutes.notificationOverlay,
                        );
                      },
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todayStatusCard(BuildContext context) {
    return _shadowCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Status",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'KhayalRoboto',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: CaregiverColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _statusColumn(
                    context,
                    value: '$_todayTaken',
                    label: 'Taken',
                    icon: Icons.check_rounded,
                    iconColor: CaregiverColors.taken,
                    disk: CaregiverColors.takenSoft,
                  ),
                ),
                Expanded(
                  child: _statusColumn(
                    context,
                    value: '$_todayMissed',
                    label: 'Missed',
                    icon: Icons.close_rounded,
                    iconColor: CaregiverColors.missed,
                    disk: CaregiverColors.missedSoft,
                  ),
                ),
                Expanded(
                  child: _statusColumn(
                    context,
                    value: '$_todayUpcoming',
                    label: 'Upcoming',
                    icon: Icons.schedule_rounded,
                    iconColor: CaregiverColors.upcoming,
                    disk: CaregiverColors.upcomingSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusColumn(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color disk,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => HapticFeedback.selectionClick(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'KhayalRoboto',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: disk, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFamily: 'KhayalRoboto',
                  color: CaregiverColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklyAdherenceCard(BuildContext context) {
    final days = _weeklyDays;
    return _shadowCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Weekly Adherence',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: CaregiverColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: CaregiverColors.takenSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: CaregiverColors.taken,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_overallPercent%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontFamily: 'KhayalRoboto',
                          fontWeight: FontWeight.w800,
                          color: CaregiverColors.taken,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (i) {
                  final rate = days[i].rate;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 4 + 86 * rate,
                            decoration: BoxDecoration(
                              color: CaregiverColors.chartBar,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            days[i].label,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontFamily: 'KhayalRoboto',
                                  color: CaregiverColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                return CustomPaint(
                  size: Size(c.maxWidth, 1),
                  painter: _DottedLinePainter(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _overallAdherenceCard(BuildContext context) {
    return _shadowCard(
      color: CaregiverColors.adherenceCard,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            top: -4,
            child: Icon(
              Icons.trending_up_rounded,
              size: 96,
              color: CaregiverColors.header.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Adherence Rate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'KhayalRoboto',
                    fontWeight: FontWeight.w700,
                    color: CaregiverColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_overallPercent%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontFamily: 'KhayalRoboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 40,
                    color: CaregiverColors.header,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicationsCard(BuildContext context) {
    return _shadowCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Medications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: CaregiverColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      AppRoutes.medicationManagement,
                    );
                  },
                  child: Text(
                    'See all',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      color: CaregiverColors.header,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_medications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No medications added yet.',
                  style: TextStyle(color: CaregiverColors.textMuted),
                ),
              )
            else
              ..._medications.take(3).map((med) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _medRow(
                    context,
                    en: med.nameEn,
                    ur: med.nameUr,
                    dose: med.doseLabel,
                    times: med.timeLabel,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.editMedication,
                      arguments: med.id,
                    ),
                  ),
                );
              }),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, AppRoutes.caregiverReminders);
                },
                icon: const Icon(Icons.notifications_active_outlined, size: 20),
                label: const Text('Reminders & alerts'),
                style: TextButton.styleFrom(
                  foregroundColor: CaregiverColors.header,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, AppRoutes.alertHistory);
                },
                icon: const Icon(Icons.history_rounded, size: 20),
                label: const Text('Alert history'),
                style: TextButton.styleFrom(
                  foregroundColor: CaregiverColors.header,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medRow(
    BuildContext context, {
    required String en,
    required String ur,
    required String dose,
    required String times,
    required VoidCallback onTap,
  }) {
    return Material(
      color: CaregiverColors.pillRowBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLanguageState.pick(en: en, ur: ur),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: AppLanguageState.isUrdu
                            ? 'NotoNastaliqUrdu'
                            : 'KhayalRoboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: CaregiverColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dose,
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
              Text(
                times,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFamily: 'KhayalRoboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: CaregiverColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shadowCard({
    required Widget child,
    Color color = CaregiverColors.card,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CaregiverColors.fieldBorder.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
