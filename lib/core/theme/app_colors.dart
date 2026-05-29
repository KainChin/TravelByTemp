import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF2D9F75);
  static const primaryDark = Color(0xFF2D8B69);
  static const primaryLight = Color(0xFFE8F5EF);
  static const accentPurple = Color(0xFF9B59B6);
  static const accentBlue = Color(0xFF3498DB);

  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const cardBorder = Color(0xFFE8E8E8);

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFF9E9E9E);

  static const gradientCta = LinearGradient(
    colors: [Color(0xFF2EC4B6), Color(0xFF9B59B6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientSave = LinearGradient(
    colors: [Color(0xFF3498DB), Color(0xFF9B59B6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
