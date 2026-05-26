import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet: gallery or camera → bytes + MIME type.
Future<void> showImageSourceSheet(
  BuildContext context, {
  required String title,
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
                title,
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
    final picker = ImagePicker();
    final x = await picker.pickImage(
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
