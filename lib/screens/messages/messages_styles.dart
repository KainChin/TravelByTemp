import 'package:flutter/material.dart';

/// All colors used across the Messages feature.
/// Keep every color reference here — never hardcode a Color(...) in a widget.
class MessageColors {
  MessageColors._();

  static const Color primaryGreen = Color(0xFF1F5D3D);
  static const Color accentGreen = Color(0xFF2D7A4F);
  static const Color backgroundMint = Color(0xFFEEF6F1);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color userBubble = Color(0xFFDFF0E3);
  static const Color aiBubble = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1B1F1C);
  static const Color textGrey = Color(0xFF8A938E);
  static const Color onlineGreen = Color(0xFF3DBE6C);
  static const Color divider = Color(0xFFE4EAE6);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color tagBackground = Color(0xFFE3F3E8);
}

/// Spacing scale (4pt grid) used for paddings/margins throughout the feature.
class MessageSpacing {
  MessageSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

/// Border radius tokens for cards, bubbles, inputs and pills.
class MessageRadius {
  MessageRadius._();

  static const double bubble = 18;
  static const double card = 24;
  static const double input = 28;
  static const double avatar = 100;
  static const double pill = 20;
}

/// Reusable box shadows.
class MessageShadows {
  MessageShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Typography used across the Messages feature.
class MessageTextStyles {
  MessageTextStyles._();

  static const TextStyle headerTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: MessageColors.primaryGreen,
    height: 1.1,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: MessageColors.primaryGreen,
  );

  static const TextStyle headerSubtitleMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF4F6B5B),
  );

  static const TextStyle aiName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: MessageColors.textDark,
  );

  static const TextStyle onlineStatus = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: MessageColors.textGrey,
  );

  static const TextStyle bubbleText = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: MessageColors.textDark,
    height: 1.4,
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: MessageColors.textGrey,
  );

  static const TextStyle datePill = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: MessageColors.primaryGreen,
  );

  static const TextStyle itineraryTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: MessageColors.primaryGreen,
  );

  static const TextStyle itinerarySubtitle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: MessageColors.textGrey,
  );

  static const TextStyle destinationName = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: MessageColors.textDark,
  );

  static const TextStyle destinationDuration = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: MessageColors.textGrey,
  );

  static const TextStyle dayTag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: MessageColors.primaryGreen,
  );

  static const TextStyle footerLink = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: MessageColors.primaryGreen,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MessageColors.textGrey,
  );
}
