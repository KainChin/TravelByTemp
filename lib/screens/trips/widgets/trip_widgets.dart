import 'package:flutter/material.dart';

const _primary = Color(0xFF2ECC71);
const _textDark = Color(0xFF1A1A1A);
const _textGrey = Color(0xFF888888);
const _border = Color(0xFFE0E0E0);
const _white = Color(0xFFFFFFFF);

// ── Search Bar ────────────────────────────────────────────────
class TripSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const TripSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        const Icon(Icons.location_on_outlined, color: _primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search destination...',
              hintStyle: TextStyle(color: _textGrey, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (controller.text.isNotEmpty)
          GestureDetector(
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.close, size: 18, color: _textGrey),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.near_me_outlined, size: 18, color: _textGrey),
          ),
      ]),
    );
  }
}

// ── Suggestion List ───────────────────────────────────────────
class SuggestionList extends StatelessWidget {
  final List<Map<String, String>> suggestions;
  final ValueChanged<Map<String, String>> onSelect;

  const SuggestionList({super.key, required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 44),
        itemBuilder: (_, i) {
          final s = suggestions[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on, color: _primary, size: 20),
            title: Text(s['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(s['address']!, style: const TextStyle(fontSize: 11, color: _textGrey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => onSelect(s),
          );
        },
      ),
    );
  }
}

// ── Current Location Row ──────────────────────────────────────
class CurrentLocationRow extends StatelessWidget {
  final String locationText;
  final VoidCallback onChange;

  const CurrentLocationRow({super.key, required this.locationText, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(width: 10, height: 10,
            decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current location', style: TextStyle(fontSize: 11, color: _textGrey)),
            Text(locationText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textDark)),
          ],
        )),
        GestureDetector(
          onTap: onChange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('Change', style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ── Destination Card ──────────────────────────────────────────
class DestinationInfoCard extends StatelessWidget {
  final String name;
  final String address;
  final String? duration;
  final String? distance;
  final String? bestRoute;
  final String imagePath;

  const DestinationInfoCard({
    super.key,
    required this.name,
    required this.address,
    this.duration,
    this.distance,
    this.bestRoute,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              'https://maps.googleapis.com/maps/api/staticmap'
                  '?center=${Uri.encodeComponent(address)}&zoom=12&size=80x80&key=AIzaSyC-sZpjiTqOpPHQ0D3KuavSgKOHm9KPPjA',
              width: 70, height: 70, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 70, height: 70,
                  color: const Color(0xFFE8F5EE),
                  child: const Icon(Icons.landscape, color: _primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  const Icon(Icons.favorite_border, size: 20, color: _textGrey),
                ]),
                Text(address, style: const TextStyle(fontSize: 12, color: _textGrey),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                if (duration != null && distance != null)
                  Row(children: [
                    const Icon(Icons.drive_eta, size: 15, color: _primary),
                    const SizedBox(width: 4),
                    Text('$duration ($distance)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                  ]),
                if (bestRoute != null)
                  Text(bestRoute!, style: const TextStyle(fontSize: 11, color: _textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Planner Banner ─────────────────────────────────────────
class AiPlannerBanner extends StatelessWidget {
  const AiPlannerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, color: _primary, size: 18)),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Trip Planner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Get a personalized itinerary\nbased on your budget, time and style',
                  style: TextStyle(fontSize: 11, color: _textGrey)),
            ]),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Generate with AI', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
