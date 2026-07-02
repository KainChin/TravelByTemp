import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/trip_itinerary_service.dart';
import '../trip_itinerary_result_screen.dart';
import 'trip_tokens.dart';
import 'trip_shared_widgets.dart';

class TripRecentSection extends StatefulWidget {
  const TripRecentSection({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<TripRecentSection> createState() => _TripRecentSectionState();
}

class _TripRecentSectionState extends State<TripRecentSection> {
  late Future<List<TripItineraryHistoryItem>> _future;
  bool _init = false;
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _token = VietaiScope.of(context).auth?.accessToken;
    _future = TripItineraryService(authToken: _token).history();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TripItineraryHistoryItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snap.hasError) {
          return TripEmptyRecentState(onCreate: widget.onCreate);
        }

        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return TripEmptyRecentState(onCreate: widget.onCreate);
        }

        final recent = items.take(3).toList();
        return Column(
          children: List.generate(recent.length, (i) {
            final item = recent[i];
            return _RecentTripCard(
              item: item,
              index: i,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripItineraryResultScreen(
                    response: 'Saved itinerary',
                    itinerary: item.itinerary,
                    itineraryId: item.id,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kTripLine),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(kTripPrimary),
              backgroundColor: kTripPrimary.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dang tai...',
            style: TextStyle(
              color: kTripMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTripCard extends StatefulWidget {
  const _RecentTripCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final TripItineraryHistoryItem item;
  final int index;
  final VoidCallback onTap;

  @override
  State<_RecentTripCard> createState() => _RecentTripCardState();
}

class _RecentTripCardState extends State<_RecentTripCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final days = widget.item.itinerary['days'] is List
        ? (widget.item.itinerary['days'] as List).length
        : 0;
    final date =
        '${widget.item.createdAt.day}/${widget.item.createdAt.month}/${widget.item.createdAt.year}';
    final score = 88 + (widget.index * 3);
    final budget = days > 0 ? '~${(days * 1.2).toStringAsFixed(1)}tr' : '~2.8tr';
    final gradients = [kGradPrimary, kGradTeal, kGradCoral];
    final grad = gradients[widget.index % gradients.length];

    return Padding(
      padding: EdgeInsets.only(bottom: widget.index < 2 ? 12 : 0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.008 : 1,
          duration: const Duration(milliseconds: 160),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hovered ? grad.colors.first.withValues(alpha: 0.28) : kTripLine,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(_hovered ? 0x120F172A : 0x080F172A),
                      blurRadius: _hovered ? 24 : 16,
                      offset: Offset(0, _hovered ? 10 : 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: grad,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: grad.colors.first.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: kTripInk,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.favorite_border_rounded, size: 18, color: kTripMuted),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 7,
                            runSpacing: 6,
                            children: [
                              _MetaChip(icon: Icons.auto_awesome_rounded, label: 'AI $score', color: kTripPrimary),
                              if (days > 0)
                                _MetaChip(icon: Icons.schedule_rounded, label: '$days ngay', color: kTripTeal),
                              _MetaChip(icon: Icons.savings_rounded, label: budget, color: kTripCoral),
                              _MetaChip(icon: Icons.update_rounded, label: date, color: kTripMuted),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.item.aiModel ?? 'AI generated itinerary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTripMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kTripPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chevron_right_rounded, color: kTripPrimary, size: 19),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
          .animate(delay: (widget.index * 80).ms)
          .fadeIn(duration: 500.ms)
          .slideX(begin: 0.06, end: 0, curve: Curves.easeOut),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class TripEmptyRecentState extends StatelessWidget {
  const TripEmptyRecentState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kTripLine),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: kTripTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 10,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kTripCoral.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: kGradPrimary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: kTripPrimary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.luggage_rounded, color: Colors.white, size: 34),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chua co hanh trinh nao',
            style: TextStyle(color: kTripInk, fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chon diem den, ngay o va ngan sach. AI se dung lich trinh hop ly cho ban.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTripMuted, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TripPillButton(
            label: 'Tao ngay',
            icon: Icons.add_rounded,
            gradient: kGradPrimary,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}
