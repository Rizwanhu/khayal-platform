import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Rich medication profile with staggered entrance and tactile rows.
class MedicationDetailScreen extends StatefulWidget {
  const MedicationDetailScreen({super.key});

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

  static const List<({String label, String value, bool urdu})> _rows = [
    (label: 'English name', value: 'Paracetamol', urdu: false),
    (label: 'Urdu name', value: 'پیراسیٹامول', urdu: true),
    (label: 'Dose', value: '500 mg', urdu: false),
    (label: 'Frequency', value: 'Twice daily', urdu: false),
    (label: 'Times', value: '08:00 · 20:00', urdu: false),
    (label: 'Instructions', value: 'Take after food with water.', urdu: false),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: CustomScrollView(
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
              'Medication',
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
                        Text(
                          'پیراسیٹامول',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontFamily: 'NotoNastaliqUrdu',
                                fontSize: 28,
                                height: 1.25,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Paracetamol',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontFamily: 'KhayalRoboto',
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.92),
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
                final row = _rows[index];
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
              }, childCount: _rows.length),
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
