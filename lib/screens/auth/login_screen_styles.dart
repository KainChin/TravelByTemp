import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────

class LoginColors {
  LoginColors._();

  static const Color primary       = Color(0xFF22C55E);
  static const Color primaryDark   = Color(0xFF16A34A);
  static const Color background    = Color(0xFFF8F9FA);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);
  static const Color border        = Color(0xFFE5E7EB);
}

// ─── Text Styles ──────────────────────────────────────────────────────────────

class LoginTextStyles {
  LoginTextStyles._();

  static const TextStyle heroTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: LoginColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle heroTitleHighlight = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: LoginColors.primary,
    height: 1.2,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontSize: 13,
    color: LoginColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: LoginColors.textPrimary,
  );

  static const TextStyle socialBtnLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: LoginColors.textPrimary,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    color: LoginColors.textPrimary,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 15,
    color: LoginColors.textHint,
  );

  static const TextStyle ctaButton = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static const TextStyle forgotPassword = TextStyle(
    fontSize: 13,
    color: LoginColors.textSecondary,
  );

  static const TextStyle registerNormal = TextStyle(
    fontSize: 14,
    color: LoginColors.textSecondary,
  );

  static const TextStyle registerLink = TextStyle(
    fontSize: 14,
    color: LoginColors.primary,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle dividerLabel = TextStyle(
    fontSize: 13,
    color: LoginColors.textHint,
  );

  static const TextStyle promoBannerTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: LoginColors.textPrimary,
  );

  static const TextStyle promoBannerDesc = TextStyle(
    fontSize: 12,
    color: LoginColors.textSecondary,
    height: 1.4,
  );
}

// ─── Decorations ──────────────────────────────────────────────────────────────

class LoginDecorations {
  LoginDecorations._();

  static BoxDecoration get backButton => BoxDecoration(
    color: LoginColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get heroImage => const BoxDecoration(
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(48),
    ),
  );

  static BoxDecoration get heroImageFallback => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6EE7B7), Color(0xFF3B82F6)],
    ),
  );

  static BoxDecoration get socialButton => BoxDecoration(
    color: LoginColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: LoginColors.border),
  );

  static BoxDecoration get inputField => BoxDecoration(
    color: LoginColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: LoginColors.border),
  );

  static BoxDecoration get ctaButton => BoxDecoration(
    gradient: const LinearGradient(
      colors: [LoginColors.primary, LoginColors.primaryDark],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: LoginColors.primary.withOpacity(0.35),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get promoBanner => BoxDecoration(
    color: LoginColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: LoginColors.border),
  );

  static BoxDecoration get promoImageFallback => BoxDecoration(
    color: const Color(0xFFDCFCE7),
    borderRadius: BorderRadius.circular(12),
  );
}