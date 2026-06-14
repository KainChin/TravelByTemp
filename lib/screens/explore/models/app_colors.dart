import 'package:flutter/material.dart';

/// Bảng màu chính của app, trích từ mockup
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A7A5E);       // Xanh lá chủ đạo
  static const Color primaryLight = Color(0xFFE8F5F0);  // Nền chip/tab active
  static const Color primaryText = Color(0xFF1A7A5E);   // Text xanh lá
  static const Color background = Color(0xFFF5F7FA);    // Nền app
  static const Color surface = Color(0xFFFFFFFF);       // Nền card
  static const Color textPrimary = Color(0xFF1A1A2E);   // Text đậm
  static const Color textSecondary = Color(0xFF6B7280); // Text xám
  static const Color star = Color(0xFFFBBF24);          // Màu sao rating
  static const Color divider = Color(0xFFE5E7EB);
  static const Color verified = Color(0xFF2196F3);      // Tích xanh verified
  static const Color tagBg = Color(0xFF2A9D6A);         // Background tag "NỔI BẬT"
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static const TextStyle primaryLabel = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText,
  );
}