import 'package:flutter/material.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────
const kTripBg = Color(0xFFF8F9FA);
const kTripInk = Color(0xFF1A1F36);
const kTripMuted = Color(0xFF6B7280);
const kTripLine = Color(0xFFE5E7EB);
const kTripPrimary = Color(0xFF2D9F75); // Green — app primary
const kTripTeal = Color(0xFF0D9488);
const kTripCoral = Color(0xFFF97316);
const kTripAmber = Color(0xFFFBBF24);

// ─── Gradients ───────────────────────────────────────────────────────────────
const kGradPrimary = LinearGradient(
  colors: [Color(0xFF2D9F75), Color(0xFF059669)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const kGradTeal = LinearGradient(
  colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const kGradCoral = LinearGradient(
  colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const kGradDark = LinearGradient(
  colors: [Color(0xFF0F172A), Color(0xFF1A3A2A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Responsive helpers ──────────────────────────────────────────────────────
double tripHPadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= 1200) return 40;
  if (w >= 768) return 24;
  return 16;
}

double tripMaxWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= 1200) return 1240;
  if (w >= 1024) return 1040;
  if (w >= 768) return 860;
  return double.infinity;
}

bool tripIsDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 1024;
