import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_routes.dart';
import '../caregiver_colors.dart';

/// Add medication — sage app bar, cream form, animated fields, photo slot.
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _urdu;
  late final TextEditingController _english;
  late final TextEditingController _dose;
  late final TextEditingController _times;
  late final AnimationController _entrance;

  String _type = 'Tablet';
  String _frequency = 'Daily';

  double _saveScale = 1;
  double _uploadScale = 1;

  static const _types = ['Tablet', 'Capsule', 'Liquid', 'Injection'];
  static const _frequencies = ['Daily', 'Twice daily', 'Three times daily', 'Weekly'];

  @override
  void initState() {
    super.initState();
    _urdu = TextEditingController();
    _english = TextEditingController(text: 'Paracetamol');
    _dose = TextEditingController(text: '1 tablet');
    _times = TextEditingController(text: '08:00, 14:00, 20:00');
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _urdu.dispose();
    _english.dispose();
    _dose.dispose();
    _times.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _slot(int i) {
    final start = (0.04 + i * 0.08).clamp(0.0, 0.72);
    final end = (0.35 + i * 0.1).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'KhayalRoboto',
        fontWeight: FontWeight.w700,
        color: CaregiverColors.textMuted,
        fontSize: 12,
      ),
      filled: true,
      fillColor: CaregiverColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CaregiverColors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CaregiverColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CaregiverColors.headerForm, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaregiverColors.canvasForm,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CaregiverColors.headerForm,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Add New Medication',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'KhayalRoboto',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          _fadeSlide(0, TextField(controller: _urdu, decoration: _dec('Medicine Name (Urdu)'), textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 16))),
          const SizedBox(height: 16),
          _fadeSlide(1, TextField(controller: _english, decoration: _dec('Medicine Name (English)'), style: const TextStyle(fontFamily: 'KhayalRoboto'))),
          const SizedBox(height: 16),
          _fadeSlide(2, TextField(controller: _dose, decoration: _dec('Dose Amount'), style: const TextStyle(fontFamily: 'KhayalRoboto'))),
          const SizedBox(height: 16),
          _fadeSlide(3, _dropdown(context, label: 'Type', value: _type, items: _types, onChanged: (v) => setState(() => _type = v ?? _type))),
          const SizedBox(height: 16),
          _fadeSlide(4, _dropdown(context, label: 'Frequency', value: _frequency, items: _frequencies, onChanged: (v) => setState(() => _frequency = v ?? _frequency))),
          const SizedBox(height: 16),
          _fadeSlide(5, TextField(controller: _times, decoration: _dec('Times'), style: const TextStyle(fontFamily: 'KhayalRoboto'))),
          const SizedBox(height: 24),
          _fadeSlide(6, Listener(
            onPointerDown: (_) => setState(() => _saveScale = 0.97),
            onPointerUp: (_) => setState(() => _saveScale = 1),
            onPointerCancel: (_) => setState(() => _saveScale = 1),
            child: AnimatedScale(
              scale: _saveScale,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CaregiverColors.headerForm,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'KhayalRoboto', fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medication saved (demo).'), behavior: SnackBarBehavior.floating),
                    );
                    Navigator.pushNamed(context, AppRoutes.medicationManagement);
                  },
                  child: const Text('Save Medication'),
                ),
              ),
            ),
          )),
          const SizedBox(height: 28),
          _fadeSlide(7, Text('Pill Photo', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontFamily: 'KhayalRoboto', fontWeight: FontWeight.w700, color: CaregiverColors.textPrimary))),
          const SizedBox(height: 10),
          _fadeSlide(8, Listener(
            onPointerDown: (_) => setState(() => _uploadScale = 0.98),
            onPointerUp: (_) => setState(() => _uploadScale = 1),
            onPointerCancel: (_) => setState(() => _uploadScale = 1),
            child: AnimatedScale(
              scale: _uploadScale,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              child: Material(
                color: CaregiverColors.fieldFill,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo picker would open here.'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: CustomPaint(
                    foregroundPainter: _DashedRectPainter(
                      color: CaregiverColors.fieldBorder,
                      radius: 16,
                    ),
                    child: const SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined, size: 40, color: CaregiverColors.textMuted),
                          SizedBox(height: 10),
                          Text('Upload Photo', style: TextStyle(fontFamily: 'KhayalRoboto', fontWeight: FontWeight.w600, color: CaregiverColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _dropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: _dec(label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          value: value,
          style: const TextStyle(
            fontFamily: 'KhayalRoboto',
            fontSize: 16,
            color: CaregiverColors.textPrimary,
          ),
          items:
              items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontFamily: 'KhayalRoboto')),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _fadeSlide(int slot, Widget child) {
    final a = _slot(slot);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(a),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final extract = metric.extractPath(d, d + 6);
        canvas.drawPath(extract, paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
