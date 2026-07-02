import 'dart:ui';
import 'package:flutter/material.dart';
import 'trip_tokens.dart';

// ─── Glass Tag ───────────────────────────────────────────────────────────────
class TripGlassTag extends StatelessWidget {
  const TripGlassTag({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = kTripAmber,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

// ─── Pill Button ─────────────────────────────────────────────────────────────
class TripPillButton extends StatelessWidget {
  const TripPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = gradient.colors.first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                  color: c.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────
class TripSectionHeader extends StatelessWidget {
  const TripSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title,
          style: const TextStyle(
              color: kTripInk, fontSize: 18, fontWeight: FontWeight.w900)),
      const Spacer(),
      if (action != null)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: kTripPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(action!,
                  style: const TextStyle(
                      color: kTripPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ),
    ]);
  }
}

// ─── Gradient Icon Button ────────────────────────────────────────────────────
class TripGradIconBtn extends StatelessWidget {
  const TripGradIconBtn({
    super.key,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = gradient.colors.first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: c.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
