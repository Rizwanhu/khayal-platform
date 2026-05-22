import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/backend_repository.dart';

/// Medication profile loaded from Supabase for the tapped medicine.
class MedicationDetailScreen extends StatefulWidget {
  const MedicationDetailScreen({super.key, this.medicationId});

  final String? medicationId;

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen>
    with SingleTickerProviderStateMixin {
  static const Color _header = Color(0xFF608266);
  static const Color _canvas = Color(0xFFF9F8F3);
  static const Color _card = Colors.white;
  static const Color _label = Color(0xFF6B7280);
  static const Color _value = Color(0xFF1C1C1C);

  late final AnimationController _controller;
  bool _loading = true;
  String? _error;
  MedicationEditRecord? _med;
  bool _startedLoad = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_startedLoad) {
      _startedLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.medicationId ??
        ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No medication selected.';
      });
      return;
    }
    try {
      final med = await Backend.repo.getMedicationById(id);
      if (!mounted) return;
      setState(() {
        _med = med;
        _loading = false;
        _error = med == null ? 'Medication not found.' : null;
      });
      if (med != null) _controller.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _frequencyLabel(int scheduleCount) {
    return switch (scheduleCount) {
      0 => '—',
      1 => 'Once daily',
      2 => 'Twice daily',
      3 => 'Three times daily',
      _ => '$scheduleCount times daily',
    };
  }

  String _formatTimes(List<String> times) {
    if (times.isEmpty) return '—';
    return times.map(_formatTime).join(' · ');
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hh = int.tryParse(parts[0]) ?? 0;
    final mm = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: hh, minute: mm);
    final suffix = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m $suffix';
  }

  List<({String label, String value, bool urdu})> _rowsFor(MedicationEditRecord med) {
    return [
      (label: 'English name', value: med.nameEn, urdu: false),
      (label: 'Urdu name', value: med.nameUr, urdu: true),
      (
        label: 'Dose',
        value: '${med.doseAmount} ${med.doseUnit}'.trim(),
        urdu: false,
      ),
      (
        label: 'Type',
        value: med.medicationType,
        urdu: false,
      ),
      (
        label: 'Frequency',
        value: _frequencyLabel(med.times.length),
        urdu: false,
      ),
      (label: 'Times', value: _formatTimes(med.times), urdu: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final med = _med;

    return Scaffold(
      backgroundColor: _canvas,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : med == null
          ? const SizedBox.shrink()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar.large(
                  expandedHeight: 168,
                  pinned: true,
                  stretch: true,
                  backgroundColor: _header,
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  title: Text(
                    med.nameEn.isNotEmpty ? med.nameEn : 'Medication',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_header, Color(0xFF4F7058)],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (med.nameUr.isNotEmpty)
                                Text(
                                  med.nameUr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontFamily: 'NotoNastaliqUrdu',
                                        fontSize: 28,
                                        height: 1.25,
                                        color: Colors.white,
                                      ),
                                ),
                              if (med.nameUr.isNotEmpty)
                                const SizedBox(height: 6),
                              Text(
                                med.nameEn,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontFamily: 'KhayalRoboto',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final rows = _rowsFor(med);
                      final row = rows[index];
                      final start = (index * 0.1).clamp(0.0, 0.5);
                      final end = (0.45 + index * 0.1).clamp(0.0, 1.0);
                      final anim = CurvedAnimation(
                        parent: _controller,
                        curve: Interval(start, end, curve: Curves.easeOutCubic),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(anim),
                            child: _DetailTile(
                              label: row.label,
                              value: row.value,
                              valueIsUrdu: row.urdu,
                              labelColor: _label,
                              valueColor: _value,
                              cardColor: _card,
                            ),
                          ),
                        ),
                      );
                    }, childCount: _rowsFor(med).length),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DetailTile extends StatefulWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    required this.valueIsUrdu,
    required this.labelColor,
    required this.valueColor,
    required this.cardColor,
  });

  final String label;
  final String value;
  final bool valueIsUrdu;
  final Color labelColor;
  final Color valueColor;
  final Color cardColor;

  @override
  State<_DetailTile> createState() => _DetailTileState();
}

class _DetailTileState extends State<_DetailTile> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.99),
      onPointerUp: (_) => setState(() => _scale = 1),
      onPointerCancel: (_) => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Material(
          color: widget.cardColor,
          elevation: 1.5,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => HapticFeedback.selectionClick(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: 'KhayalRoboto',
                        fontWeight: FontWeight.w600,
                        color: widget.labelColor,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.value,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: widget.valueIsUrdu
                            ? 'NotoNastaliqUrdu'
                            : 'KhayalRoboto',
                        fontWeight: FontWeight.w600,
                        fontSize: widget.valueIsUrdu ? 17 : 15,
                        height: widget.valueIsUrdu ? 1.4 : 1.25,
                        color: widget.valueColor,
                      ),
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
