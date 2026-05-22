import 'package:flutter/material.dart';

import 'patient_shell_colors.dart';

/// Design tokens for patient UI — tuned for ages ~50–60+ (readable, tappable).
///
/// Use these instead of scattered font sizes so screens stay consistent.
abstract final class PatientUiTokens {
  // --- Touch (WCAG 2.5.5: min 44dp; we use 56dp for older users) ---
  static const double minTouchHeight = 56;
  static const double minTouchWidth = 56;
  static const double iconButtonSize = 56;

  // --- Type scale ---
  static const double titleLarge = 26;
  static const double titleMedium = 22;
  static const double body = 18;
  static const double bodySmall = 16;
  static const double label = 15;
  static const double caption = 14;

  static const double lineHeightBody = 1.45;
  static const double lineHeightTight = 1.2;

  // --- Layout ---
  static const double radiusCard = 16;
  static const double radiusButton = 14;
  static const double paddingScreen = 20;
  static const double paddingCard = 18;
  static const double gapSection = 16;
  static const double gapItem = 12;

  static String fontFamily({required bool urdu}) =>
      urdu ? 'NotoNastaliqUrdu' : 'KhayalRoboto';

  static TextStyle titleLargeStyle({required bool urdu, Color? color}) =>
      TextStyle(
        fontFamily: fontFamily(urdu: urdu),
        fontSize: titleLarge,
        fontWeight: FontWeight.w800,
        height: lineHeightTight,
        color: color ?? PatientShellColors.textPrimary,
      );

  static TextStyle titleMediumStyle({required bool urdu, Color? color}) =>
      TextStyle(
        fontFamily: fontFamily(urdu: urdu),
        fontSize: titleMedium,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        color: color ?? PatientShellColors.textPrimary,
      );

  static TextStyle bodyStyle({required bool urdu, Color? color}) => TextStyle(
        fontFamily: fontFamily(urdu: urdu),
        fontSize: body,
        fontWeight: FontWeight.w500,
        height: lineHeightBody,
        color: color ?? PatientShellColors.textPrimary,
      );

  static TextStyle bodySmallStyle({required bool urdu, Color? color}) =>
      TextStyle(
        fontFamily: fontFamily(urdu: urdu),
        fontSize: bodySmall,
        fontWeight: FontWeight.w500,
        height: lineHeightBody,
        color: color ?? PatientShellColors.textSecondary,
      );

  static TextStyle labelStyle({required bool urdu, Color? color}) => TextStyle(
        fontFamily: fontFamily(urdu: urdu),
        fontSize: label,
        fontWeight: FontWeight.w700,
        height: lineHeightBody,
        color: color ?? PatientShellColors.textPrimary,
      );

  static ButtonStyle primaryButtonStyle() => FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, minTouchHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor: PatientShellColors.header,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'KhayalRoboto',
          fontSize: body,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
      );

  static ButtonStyle outlinedButtonStyle() => OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, minTouchHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        foregroundColor: PatientShellColors.header,
        side: const BorderSide(color: PatientShellColors.header, width: 2),
        textStyle: const TextStyle(
          fontFamily: 'KhayalRoboto',
          fontSize: body,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
      );
}
