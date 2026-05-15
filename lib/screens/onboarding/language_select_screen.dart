import 'package:flutter/material.dart';

import '../../core/i18n/app_language.dart';
import '../../core/navigation/app_routes.dart';

/// Language select: off-white canvas, Urdu wordmark, bilingual prompt, two CTA pills.
class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  static const Color _canvas = Color(0xFFF9F9F9);
  static const Color _greenCta = Color(0xFF608971);
  static const Color _tanCta = Color(0xFFD4A373);
  static const Color _instructionGray = Color(0xFF6E6E6E);
  static const Color _englishOnTan = Color(0xFF2C1810);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 56),
              const Text(
                'خیال',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 40,
                  height: 1.25,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Select Your Language',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'KhayalRoboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: _instructionGray,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'اپنی زبان منتخب کریں',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 22,
                  height: 1.35,
                  color: Color(0xFF000000),
                ),
              ),
              const Spacer(),
              _LanguagePill(
                label: 'اردو',
                background: _greenCta,
                foreground: Colors.white,
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 22,
                onTap: () async {
                  await AppLanguageState.setLanguage(AppLanguage.urdu);
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, AppRoutes.roleSelect);
                },
              ),
              const SizedBox(height: 16),
              _LanguagePill(
                label: 'English',
                background: _tanCta,
                foreground: _englishOnTan,
                fontFamily: 'KhayalRoboto',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                onTap: () async {
                  await AppLanguageState.setLanguage(AppLanguage.english);
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, AppRoutes.roleSelect);
                },
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.fontFamily,
    required this.fontSize,
    this.fontWeight,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final String fontFamily;
  final double fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.09),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                fontWeight: fontWeight ?? FontWeight.w500,
                color: foreground,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
