import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/backend/backend.dart';

/// Loads a time-limited signed URL for a private Storage object path.
class MedicationSignedThumb extends StatefulWidget {
  const MedicationSignedThumb({
    super.key,
    required this.storagePath,
    this.size = 48,
    this.borderRadius = 10,
  });

  final String storagePath;
  final double size;
  final double borderRadius;

  @override
  State<MedicationSignedThumb> createState() => _MedicationSignedThumbState();
}

class _MedicationSignedThumbState extends State<MedicationSignedThumb> {
  late final Future<String?> _url = Backend.repo.signedMedicationImageUrl(
    widget.storagePath,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<String?>(
          future: _url,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final u = snap.data;
            if (u == null || u.isEmpty) {
              return Icon(Icons.medication_rounded, size: widget.size * 0.5);
            }
            return Image.network(
              u,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    size: widget.size * 0.45,
                  ),
            );
          },
        ),
      ),
    );
  }
}

class MedicationMemoryPhotoPreview extends StatelessWidget {
  const MedicationMemoryPhotoPreview({
    super.key,
    required this.bytes,
    this.height = 140,
    this.borderRadius = 16,
  });

  final Uint8List bytes;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }
}

Future<void> showMedicationPhotoPickerSheet(
  BuildContext context, {
  required void Function(Uint8List bytes, String mimeType) onPicked,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add pill photo',
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                  fontFamily: 'KhayalRoboto',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontFamily: 'KhayalRoboto'),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndDeliver(
                    context,
                    useCamera: false,
                    onPicked: onPicked,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text(
                  'Take photo',
                  style: TextStyle(fontFamily: 'KhayalRoboto'),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndDeliver(
                    context,
                    useCamera: true,
                    onPicked: onPicked,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _pickAndDeliver(
  BuildContext context, {
  required bool useCamera,
  required void Function(Uint8List bytes, String mimeType) onPicked,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    // Implement the actual image_picker logic using the Flutter image_picker package
    final picker = ImagePicker();
    final XFile? x = await picker.pickImage(
      source: useCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (x == null) return;

    final bytes = await x.readAsBytes();
    if (bytes.isEmpty) return;
    final mime = x.mimeType ?? _mimeFromPath(x.path);
    onPicked(bytes, mime);
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Could not pick image: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

String _mimeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
