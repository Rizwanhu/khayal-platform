import 'package:flutter/material.dart';

import 'doctor_shell_colors.dart';
import 'doctor_ui_tokens.dart';

abstract final class DoctorUi {
  static PreferredSizeWidget appBar({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    Widget? leading,
  }) {
    return AppBar(
      backgroundColor: DoctorShellColors.header,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: subtitle != null ? 72 : 64,
      leading: leading,
      title: subtitle == null
          ? Text(
              title,
              style: const TextStyle(
                fontFamily: 'KhayalRoboto',
                fontWeight: FontWeight.w800,
                fontSize: DoctorUiTokens.titleMedium,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'KhayalRoboto',
                    fontWeight: FontWeight.w800,
                    fontSize: DoctorUiTokens.titleMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'KhayalRoboto',
                    fontSize: DoctorUiTokens.caption,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
      actions: actions,
    );
  }

  static Widget sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'KhayalRoboto',
          fontSize: DoctorUiTokens.caption,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: DoctorShellColors.textSecondary,
        ),
      ),
    );
  }

  static Widget statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Material(
        color: DoctorShellColors.card,
        borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
          onTap: null,
          child: Container(
            padding: const EdgeInsets.all(DoctorUiTokens.paddingCard),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
              border: Border.all(color: DoctorShellColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'KhayalRoboto',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: DoctorUiTokens.bodyStyle(
                    color: DoctorShellColors.textSecondary,
                  ).copyWith(fontSize: DoctorUiTokens.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: DoctorUiTokens.minTouchHeight + 4,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: DoctorShellColors.header,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'KhayalRoboto',
            fontSize: DoctorUiTokens.body,
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: Icon(icon, size: 22),
        label: Text(label),
      ),
    );
  }

  static Widget navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DoctorUiTokens.gapItem),
      child: Material(
        color: DoctorShellColors.card,
        borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorUiTokens.paddingCard,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
              border: Border.all(color: DoctorShellColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: DoctorShellColors.header.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: DoctorShellColors.header, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: DoctorUiTokens.labelStyle()),
                      const SizedBox(height: 3),
                      Text(subtitle, style: DoctorUiTokens.bodyStyle()),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                  color: DoctorShellColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 56, color: DoctorShellColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DoctorUiTokens.labelStyle(size: DoctorUiTokens.titleMedium),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DoctorUiTokens.bodyStyle(),
          ),
        ],
      ),
    );
  }

  static Widget loading() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: DoctorShellColors.header),
        ),
      );

  static Widget errorBox(String message, {VoidCallback? onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DoctorUiTokens.paddingCard),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(DoctorUiTokens.radiusCard),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: DoctorUiTokens.bodyStyle(color: const Color(0xFFB71C1C)),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
