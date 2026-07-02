import 'package:flutter/material.dart';

import 'trip_tokens.dart';

class TripQuickActions extends StatelessWidget {
  const TripQuickActions({
    super.key,
    required this.onCreate,
    required this.onHistory,
  });

  final VoidCallback onCreate;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(kGradPrimary, Icons.add_location_alt_rounded, 'Tao hanh trinh',
          'AI lap lich', onCreate),
      _ActionData(kGradTeal, Icons.auto_awesome_rounded, 'AI Planner',
          'Goi y thong minh', onCreate),
      _ActionData(kGradCoral, Icons.map_rounded, 'Ban do', 'Tuyen duong',
          onCreate),
      _ActionData(
        const LinearGradient(
          colors: [Color(0xFF2D8B69), Color(0xFF1B7A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        Icons.history_rounded,
        'Lich su AI',
        'Da tao gan day',
        onHistory,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final crossCount = constraints.maxWidth > 560 ? 4 : 2;
      const spacing = 12.0;
      final itemWidth =
          (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: actions
            .map((a) => SizedBox(width: itemWidth, child: _QuickActionCard(data: a)))
            .toList(),
      );
    });
  }
}

class _ActionData {
  const _ActionData(this.gradient, this.icon, this.title, this.subtitle, this.onTap);

  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({required this.data});

  final _ActionData data;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.data.gradient.colors.first;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.015 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.data.onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(minHeight: 132),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hovered ? c.withValues(alpha: 0.32) : kTripLine,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(_hovered ? 0x140F172A : 0x080F172A),
                    blurRadius: _hovered ? 24 : 18,
                    offset: Offset(0, _hovered ? 10 : 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: widget.data.gradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: c.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(widget.data.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTripInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTripMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
