import 'package:flutter/material.dart';

import '../core/backend/backend_repository.dart';
import '../core/ui/doctor_shell_colors.dart';
import '../core/ui/doctor_ui_tokens.dart';

/// Patient row with clear Message and History actions.
class DoctorPatientTile extends StatelessWidget {
  const DoctorPatientTile({
    super.key,
    required this.patient,
    required this.onMessage,
    required this.onHistory,
    this.selected = false,
  });

  final DoctorPatientSummary patient;
  final VoidCallback onMessage;
  final VoidCallback onHistory;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DoctorUiTokens.gapItem),
      child: Material(
        color: DoctorShellColors.card,
        borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
          onTap: onMessage,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
              border: Border.all(
                color: selected
                    ? DoctorShellColors.accent
                    : DoctorShellColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      DoctorShellColors.header.withValues(alpha: 0.14),
                  child: Text(
                    patient.patientName.isNotEmpty
                        ? patient.patientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: DoctorShellColors.header,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientName,
                        style: DoctorUiTokens.labelStyle(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap card or Message to chat',
                        style: DoctorUiTokens.bodyStyle().copyWith(
                          fontSize: DoctorUiTokens.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Dose history',
                  onPressed: onHistory,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        DoctorShellColors.divider.withValues(alpha: 0.6),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 22),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: onMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor: DoctorShellColors.header,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text(
                    'Message',
                    style: TextStyle(
                      fontFamily: 'KhayalRoboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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
