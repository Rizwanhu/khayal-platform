import 'package:flutter/material.dart';

import 'doctor_shell_colors.dart';

abstract final class DoctorUiTokens {
  static const double paddingScreen = 20;
  static const double paddingCard = 18;
  static const double gapSection = 20;
  static const double gapItem = 12;
  static const double radiusCard = 16;
  static const double minTouchHeight = 52;

  static const double titleLarge = 22;
  static const double titleMedium = 18;
  static const double body = 16;
  static const double bodySmall = 14;
  static const double caption = 12;

  static TextStyle labelStyle({double? size}) => TextStyle(
        fontFamily: 'KhayalRoboto',
        fontSize: size ?? body,
        fontWeight: FontWeight.w700,
        color: DoctorShellColors.textPrimary,
        height: 1.3,
      );

  static TextStyle bodyStyle({Color? color}) => TextStyle(
        fontFamily: 'KhayalRoboto',
        fontSize: body,
        fontWeight: FontWeight.w500,
        color: color ?? DoctorShellColors.textSecondary,
        height: 1.4,
      );
}
