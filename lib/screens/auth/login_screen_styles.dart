import 'package:flutter/material.dart';

class LoginScreenStyles {
  LoginScreenStyles._();

  static const Color ink = Color(0xFF15221D);
  static const Color muted = Color(0xFF6E7A74);
  static const Color primary = Color(0xFF008F6A);
  static const Color primaryDark = Color(0xFF006B52);
  static const Color accent = Color(0xFFFF8A5B);
  static const Color background = Color(0xFFF5F7F4);
  static const Color surface = Colors.white;
  static const Color line = Color(0xFFE2E8E4);
  static const Color fieldFill = Color(0xFFF8FAF8);

  static const double horizontalPadding = 20;
  static const double radius = 18;

  static const TextStyle heroEyebrow = TextStyle(
    color: Color(0xFFE9FFF5),
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heroTitle = TextStyle(
    color: Colors.white,
    fontSize: 30,
    height: 1.08,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle title = TextStyle(
    color: ink,
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle subtitle = TextStyle(
    color: muted,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputLabel = TextStyle(
    color: ink,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle linkText = TextStyle(
    color: primary,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle primaryButtonText = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w900,
  );

  static InputDecoration inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AA6A0), fontSize: 14),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: muted, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5484D)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1.4),
      ),
    );
  }

  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFFB8C7C0),
    minimumSize: const Size(double.infinity, 54),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
