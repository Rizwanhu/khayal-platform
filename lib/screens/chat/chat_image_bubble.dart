import 'package:flutter/material.dart';

import '../../core/backend/backend.dart';
import '../../core/ui/doctor_shell_colors.dart';

/// Chat message bubble showing a signed image (and optional caption).
class ChatImageBubble extends StatefulWidget {
  const ChatImageBubble({
    super.key,
    required this.storagePath,
    required this.caption,
    required this.mine,
    this.onTap,
  });

  final String storagePath;
  final String caption;
  final bool mine;
  final VoidCallback? onTap;

  @override
  State<ChatImageBubble> createState() => _ChatImageBubbleState();
}

class _ChatImageBubbleState extends State<ChatImageBubble> {
  late final Future<String?> _url = Backend.chat.signedChatImageUrl(
    widget.storagePath,
  );

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.72;
    final bg = widget.mine
        ? DoctorShellColors.chatBubbleMine
        : Colors.grey.shade200;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: maxW),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(widget.mine ? 16 : 4),
            bottomRight: Radius.circular(widget.mine ? 4 : 16),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String?>(
              future: _url,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return SizedBox(
                    width: maxW,
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.mine ? Colors.white70 : null,
                      ),
                    ),
                  );
                }
                final u = snap.data;
                if (u == null || u.isEmpty) {
                  return SizedBox(
                    width: maxW,
                    height: 120,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: widget.mine ? Colors.white70 : Colors.black45,
                      size: 40,
                    ),
                  );
                }
                return Image.network(
                  u,
                  width: maxW,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      width: maxW,
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: widget.mine ? Colors.white70 : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: maxW,
                    height: 120,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: widget.mine ? Colors.white70 : Colors.black45,
                    ),
                  ),
                );
              },
            ),
            if (widget.caption.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Text(
                  widget.caption,
                  style: TextStyle(
                    color: widget.mine ? Colors.white : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void showChatImageFullscreen(BuildContext context, String signedUrl) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          InteractiveViewer(
            child: Image.network(signedUrl, fit: BoxFit.contain),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  );
}
