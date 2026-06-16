import 'package:flutter/material.dart';

class MsgColors {
  static const primary = Color(0xFF2ECC71);
  static const primaryLight = Color(0xFFE8F8F0);
  static const primaryDark = Color(0xFF27AE60);
  static const bg = Color(0xFFF5F7F5);
  static const surface = Colors.white;
  static const textDark = Color(0xFF1A1A2E);
  static const textGrey = Color(0xFF9CA3AF);
  static const bubbleAI = Color(0xFFFFFFFF);
  static const bubbleUser = Color(0xFFE8F5EE);
  static const borderLight = Color(0xFFEEF0EE);
  static const online = Color(0xFF2ECC71);
}

class MsgTextStyles {
  static const appBarTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: MsgColors.textDark,
    letterSpacing: -0.5,
  );
  static const appBarSub = TextStyle(
    fontSize: 13,
    color: MsgColors.textGrey,
    fontWeight: FontWeight.w400,
  );
  static const bubbleUser = TextStyle(
    fontSize: 15,
    color: Color(0xFF1A4731),
    height: 1.45,
  );
  static const bubbleAI = TextStyle(
    fontSize: 15,
    color: MsgColors.textDark,
    height: 1.45,
  );
  static const timestamp = TextStyle(
    fontSize: 11,
    color: MsgColors.textGrey,
  );
  static const dateChip = TextStyle(
    fontSize: 12,
    color: MsgColors.textGrey,
    fontWeight: FontWeight.w500,
  );
  static const itineraryTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: MsgColors.textDark,
  );
  static const itinerarySub = TextStyle(
    fontSize: 12,
    color: MsgColors.textGrey,
  );
  static const cityName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: MsgColors.textDark,
  );
  static const cityDays = TextStyle(
    fontSize: 12,
    color: MsgColors.textGrey,
  );
  static const seeMore = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: MsgColors.primary,
  );
  static const dayChip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: MsgColors.primaryDark,
  );
  static const quickChip = TextStyle(
    fontSize: 13,
    color: MsgColors.primaryDark,
    fontWeight: FontWeight.w500,
  );
  static const inputHint = TextStyle(
    fontSize: 15,
    color: MsgColors.textGrey,
  );
  static const onlineDot = TextStyle(
    fontSize: 12,
    color: MsgColors.online,
    fontWeight: FontWeight.w500,
  );
}

class MsgDimens {
  static const bubbleRadius = 18.0;
  static const bubbleRadiusSmall = 4.0;
  static const inputRadius = 28.0;
  static const cardRadius = 16.0;
  static const avatarRadius = 20.0;
  static const hPad = 16.0;
  static const vPad = 12.0;
}
