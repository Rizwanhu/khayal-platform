import 'package:flutter/material.dart';

/// Shared patient shell styling (consistency across home, drawer, chat).
abstract final class PatientShellColors {
  static const Color header = Color(0xFF608266);
  static const Color headerDark = Color(0xFF4D6B52);
  static const Color canvas = Color(0xFFF9F8F3);
  static const Color card = Colors.white;
  /// High-contrast body text (readable for 50–60+).
  static const Color textPrimary = Color(0xFF121212);
  /// Secondary — still ≥4.5:1 on white.
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textMuted = Color(0xFF4A4A4A);
  static const Color divider = Color(0xFFD8D4CC);
  static const Color taken = Color(0xFF2E7D32);
  static const Color upcoming = Color(0xFFE65100);
  static const Color missed = Color(0xFFC62828);
}
