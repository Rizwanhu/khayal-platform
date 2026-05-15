import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/backend/backend.dart';
import '../../../core/navigation/app_routes.dart';
import '../caregiver_colors.dart';
import 'medication_photo_widgets.dart';

/// Edit medication — dynamic times, dashed photo zone, sticky save bar.
class EditMedicationScreen extends StatefulWidget {
  const EditMedicationScreen({super.key});

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _urdu;
  late final TextEditingController _english;
  late final TextEditingController _dose;
  late final AnimationController _entrance;

  String _type = 'Tablet';
  String _frequency = 'Daily';
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 20, minute: 0)];

  double _saveScale = 1;
  double _uploadScale = 1;

  static const _types = ['Tablet', 'Capsule', 'Liquid', 'Injection'];
  static const _frequencies = [
    'Daily',
    'Twice daily',
    'Three times daily',
    'Weekly',
  ];
  String? _medicationId;
  String? _patientId;
  String? _existingImagePath;
  Uint8List? _newPhotoBytes;
  String? _newPhotoMime;
  bool _loading = true;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _urdu = TextEditingController(text: 'پیراسیٹامول');
    _english = TextEditingController(text: 'Paracetamol');
    _dose = TextEditingController(text: '1 tablet');
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
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _slot(int i) {
    final start = (0.04 + i * 0.07).clamp(0.0, 0.7);
    final end = (0.32 + i * 0.09).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && arg.isNotEmpty) {
      _medicationId = arg;
      _loadMedication(arg);
    } else {
      _loading = false;
    }
  }

  Future<void> _loadMedication(String medicationId) async {
    try {
      final med = await Backend.repo.getMedicationById(medicationId);
      if (med == null) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _urdu.text = med.nameUr;
        _english.text = med.nameEn;
        _dose.text = med.doseAmount;
        _patientId = med.patientId;
        _existingImagePath = med.imageStoragePath;
        _newPhotoBytes = null;
        _newPhotoMime = null;
        _type =
            _types.contains(_capitalize(med.doseUnit))
                ? _capitalize(med.doseUnit)
                : _type;
        final normalizedType = _capitalize(med.medicationType);
        if (_types.contains(normalizedType)) _type = normalizedType;
        _times
          ..clear()
          ..addAll(
            med.times.map(_parseTimeOfDay).whereType<TimeOfDay>().toList(),
          );
        if (_times.isEmpty) {
          _times.add(const TimeOfDay(hour: 8, minute: 0));
        }
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
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
        borderSide: const BorderSide(
          color: CaregiverColors.headerForm,
          width: 2,
        ),
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
                      child: Text(
                        e,
                        style: const TextStyle(fontFamily: 'KhayalRoboto'),
                      ),
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
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: CaregiverColors.canvasForm,
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
        title: Text(
          'Edit Medication',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'KhayalRoboto',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              physics: const BouncingScrollPhysics(),
              children: [
                _fadeSlide(
                  0,
                  TextField(
                    controller: _urdu,
                    decoration: _dec('Medicine Name (Urdu)'),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _fadeSlide(
                  1,
                  TextField(
                    controller: _english,
                    decoration: _dec('Medicine Name (English)'),
                    style: const TextStyle(fontFamily: 'KhayalRoboto'),
                  ),
                ),
                const SizedBox(height: 16),
                _fadeSlide(
                  2,
                  TextField(
                    controller: _dose,
                    decoration: _dec('Dose Amount'),
                    style: const TextStyle(fontFamily: 'KhayalRoboto'),
                  ),
                ),
                const SizedBox(height: 16),
                _fadeSlide(
                  3,
                  _dropdown(
                    context,
                    label: 'Type',
                    value: _type,
                    items: _types,
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                ),
                const SizedBox(height: 16),
                _fadeSlide(
                  4,
                  _dropdown(
                    context,
                    label: 'Frequency',
                    value: _frequency,
                    items: _frequencies,
                    onChanged:
                        (v) => setState(() => _frequency = v ?? _frequency),
                  ),
                ),
                const SizedBox(height: 20),
                _fadeSlide(
                  5,
                  Text(
                    'Times',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      color: CaregiverColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(_times.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _fadeSlide(
                      6,
                      Material(
                        color: CaregiverColors.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: Colors.grey.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _pickTime(i),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      MaterialLocalizations.of(
                                        context,
                                      ).formatTimeOfDay(
                                        _times[i],
                                        alwaysUse24HourFormat: false,
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'KhayalRoboto',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: CaregiverColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () {
                                  if (_times.length > 1) {
                                    setState(() => _times.removeAt(i));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(
                        () => _times.add(const TimeOfDay(hour: 8, minute: 0)),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add Another Time'),
                    style: TextButton.styleFrom(
                      foregroundColor: CaregiverColors.textPrimary,
                      backgroundColor: CaregiverColors.fieldFill,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pill Photo',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontFamily: 'KhayalRoboto',
                    fontWeight: FontWeight.w700,
                    color: CaregiverColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Listener(
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
                        onTap: () async {
                          // Bind the onTap event of the photo button to trigger the camera/gallery selection dialog
                          HapticFeedback.selectionClick();
                          await showMedicationPhotoPickerSheet(
                            context,
                            onPicked: (bytes, mime) {
                              setState(() {
                                _newPhotoBytes = bytes;
                                _newPhotoMime = mime;
                              });
                            },
                          );
                        },
                        child: CustomPaint(
                          foregroundPainter: _DashedRectPainter(
                            color: CaregiverColors.fieldBorder,
                            radius: 16,
                          ),
                          child: SizedBox(
                            height: 120,
                            width: double.infinity,
                            child:
                                _newPhotoBytes != null
                                    ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        MedicationMemoryPhotoPreview(
                                          bytes: _newPhotoBytes!,
                                          height: 120,
                                          borderRadius: 16,
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Material(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _newPhotoBytes = null;
                                                  _newPhotoMime = null;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : _existingImagePath != null &&
                                        _existingImagePath!.isNotEmpty
                                    ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: MedicationSignedThumb(
                                              storagePath: _existingImagePath!,
                                              size: 96,
                                              borderRadius: 12,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 6,
                                          right: 6,
                                          child: Text(
                                            'Tap to replace',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall?.copyWith(
                                              fontFamily: 'KhayalRoboto',
                                              color: CaregiverColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_camera_outlined,
                                          size: 36,
                                          color: CaregiverColors.textMuted,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Upload Photo',
                                          style: TextStyle(
                                            fontFamily: 'KhayalRoboto',
                                            fontWeight: FontWeight.w600,
                                            color: CaregiverColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Material(
            elevation: 12,
            shadowColor: Colors.black26,
            color: CaregiverColors.pillRowBg,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Listener(
                  onPointerDown: (_) => setState(() => _saveScale = 0.97),
                  onPointerUp: (_) => setState(() => _saveScale = 1),
                  onPointerCancel: (_) => setState(() => _saveScale = 1),
                  child: AnimatedScale(
                    scale: _saveScale,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: CaregiverColors.header,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontFamily: 'KhayalRoboto',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed:
                            _saving
                                ? null
                                : () async {
                                  HapticFeedback.mediumImpact();
                                  await _saveMedication(context);
                                },
                        child: Text(_saving ? 'Saving...' : 'Save Medication'),
                      ),
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

  Future<void> _saveMedication(BuildContext context) async {
    final medId = _medicationId;
    if (medId == null || medId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication ID missing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await Backend.repo.updateMedication(
        medicationId: medId,
        urduName: _urdu.text.trim(),
        englishName: _english.text.trim(),
        doseAmountRaw: _dose.text.trim(),
        doseUnit: _type,
        medicationType: _type.toLowerCase(),
        times:
            _times
                .map(
                  (t) =>
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                )
                .toList(),
      );
      final pid = _patientId;
      if (pid != null &&
          pid.isNotEmpty &&
          _newPhotoBytes != null &&
          _newPhotoMime != null &&
          _newPhotoMime!.isNotEmpty) {
        // Pass the selected image bytes to Backend.repo.uploadMedicationPhotoAndSave
        await Backend.repo.uploadMedicationPhotoAndSave(
          patientId: pid,
          medicationId: medId,
          bytes: _newPhotoBytes!,
          contentType: _newPhotoMime!,
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, AppRoutes.medicationManagement);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  TimeOfDay? _parseTimeOfDay(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hh = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    if (hh == null || mm == null) return null;
    return TimeOfDay(hour: hh, minute: mm);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(r);
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
