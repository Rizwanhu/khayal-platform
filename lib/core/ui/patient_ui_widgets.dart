import 'package:flutter/material.dart';

import '../i18n/app_language.dart';
import 'patient_shell_colors.dart';
import 'patient_ui_tokens.dart';

/// Reusable patient UI building blocks (keeps screens thin and consistent).
abstract final class PatientUi {
  static PreferredSizeWidget appBar({
    required String title,
    List<Widget>? actions,
  }) {
    return AppBar(
      backgroundColor: PatientShellColors.header,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: PatientUiTokens.fontFamily(
            urdu: AppLanguageState.isUrdu,
          ),
          fontWeight: FontWeight.w800,
          fontSize: PatientUiTokens.titleMedium,
        ),
      ),
      actions: actions,
    );
  }

  static Widget sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'KhayalRoboto',
          fontSize: PatientUiTokens.caption,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: PatientShellColors.textSecondary,
        ),
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
      padding: const EdgeInsets.only(bottom: PatientUiTokens.gapItem),
      child: Material(
        color: PatientShellColors.card,
        borderRadius: BorderRadius.circular(PatientUiTokens.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(PatientUiTokens.radiusCard),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: PatientUiTokens.minTouchHeight + 20,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PatientUiTokens.paddingCard,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: PatientShellColors.header.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: PatientShellColors.header,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: PatientUiTokens.labelStyle(
                            urdu: AppLanguageState.isUrdu,
                          ).copyWith(fontSize: PatientUiTokens.body),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: PatientUiTokens.bodySmallStyle(
                            urdu: AppLanguageState.isUrdu,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 28,
                    color: PatientShellColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget loadingPanel({
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: PatientShellColors.header,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: PatientUiTokens.titleMediumStyle(
                urdu: AppLanguageState.isUrdu,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: PatientUiTokens.bodySmallStyle(
                  urdu: AppLanguageState.isUrdu,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget messagePanel({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    bool primaryLoading = false,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PatientUiTokens.paddingScreen),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: PatientShellColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PatientShellColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: iconColor),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: PatientUiTokens.titleMediumStyle(
                      urdu: AppLanguageState.isUrdu,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: PatientUiTokens.bodyStyle(
                      urdu: AppLanguageState.isUrdu,
                      color: PatientShellColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: primaryLoading ? null : onPrimary,
                      style: PatientUiTokens.primaryButtonStyle(),
                      icon: primaryLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 26),
                      label: Text(primaryLabel),
                    ),
                  ),
                  if (secondaryLabel != null && onSecondary != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        style: PatientUiTokens.outlinedButtonStyle(),
                        child: Text(secondaryLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget primaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: PatientUiTokens.primaryButtonStyle(),
        icon: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.check_rounded, size: 26),
        label: Text(label),
      ),
    );
  }
}
