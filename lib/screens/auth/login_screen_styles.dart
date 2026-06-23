import 'package:flutter/material.dart';

/// Toàn bộ màu sắc, kích thước, style dùng cho LoginScreen.
/// Tách riêng để dễ chỉnh sửa theme mà không phải đụng vào logic UI.
class LoginScreenStyles {
  LoginScreenStyles._();

  // ----- Colors -----
  static const Color primaryGreen = Color(0xFF1B5E3C);
  static const Color backgroundColor = Color(0xFFF7F8F6);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color socialButtonBorder = Color(0xFFE0E0E0);

  // ----- Spacing -----
  static const double horizontalPadding = 24;
  static const double fieldSpacing = 16;
  static const double sectionSpacing = 28;

  // ----- Border radius -----
  static const double inputRadius = 12;
  static const double buttonRadius = 14;
  static const double socialButtonRadius = 50;

  // ----- Text styles -----
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 14,
    color: Color(0xFFB0B0B0),
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 13,
    color: primaryGreen,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle primaryButtonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle dividerText = TextStyle(
    fontSize: 13,
    color: textSecondary,
  );

  static const TextStyle footerText = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );

  static const TextStyle footerLink = TextStyle(
    fontSize: 14,
    color: primaryGreen,
    fontWeight: FontWeight.w600,
  );

  // ----- Decorations -----
  static InputDecoration inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: inputHint,
      filled: true,
      fillColor: inputFill,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: primaryGreen),
      ),
    );
  }

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryGreen,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    elevation: 0,
  );

  static BoxDecoration socialButtonDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white,
    border: Border.all(color: socialButtonBorder),
  );
}