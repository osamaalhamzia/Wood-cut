import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF1E1F21);
  static const raised = Color(0xFF292A2C);
  static const inset = Color(0xFF161718);
  static const line = Color(0xFF3A3B3E);
  static const text = Color(0xFFF2F1ED);
  static const textDim = Color(0x9EF2F1ED);
  static const accent = Color(0xFF25E4D1);
  static const accentInk = Color(0xFF0B2A28);
  static const warn = Color(0xFFE4B54A);
  static const danger = Color(0xFFE4675C);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.accentInk,
      surface: AppColors.raised,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
  );
}
