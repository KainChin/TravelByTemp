import 'package:flutter/material.dart';

class LoginScreenStyles {
  LoginScreenStyles._();

  static const Color primary = Color(0xFF007BFF); // Blue
  static const Color accent = Color(0xFF00B4D8); // Cyan
  static const Color textDark = Color(0xFF1E293B); // Dark slate
  static const Color textGray = Color(0xFF64748B); // Slate
  static const Color borderGray = Color(0xFFE2E8F0); // Light slate
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF007BFF), Color(0xFF00B4D8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const TextStyle heroTitle = TextStyle(
    color: Colors.white,
    fontSize: 42,
    height: 1.1,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static const TextStyle heroTitleAccent = TextStyle(
    color: Color(0xFF00D4AA), // Teal/cyan accent
    fontSize: 36,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle heroSubtitle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle panelTitle = TextStyle(
    color: textDark,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  static const TextStyle panelSubtitle = TextStyle(
    color: textGray,
    fontSize: 14,
    height: 1.5,
  );

  static const TextStyle inputLabel = TextStyle(
    color: textDark,
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  static InputDecoration inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGray, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
