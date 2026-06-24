import 'package:flutter/material.dart';

class TripItineraryResultScreen extends StatelessWidget {
  const TripItineraryResultScreen({
    super.key,
    required this.response,
    required this.itinerary,
  });

  final String response;
  final Map<String, dynamic> itinerary;

  @override
  Widget build(BuildContext context) {
    final days = itinerary['days'] is List ? itinerary['days'] as List : const [];
    final cost = itinerary['costBreakdown'] is Map
        ? itinerary['costBreakdown'] as Map
        : const {};
    final warnings = itinerary['warnings'] is List
        ? itinerary['warnings'] as List
        : const [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('AI Itinerary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            title: '${itinerary['title'] ?? 'Itinerary'}',
            summary: '${itinerary['summary'] ?? response}',
          ),
          const SizedBox(height: 12),
          if (cost.isNotEmpty) _CostCard(cost: cost),
          if (cost.isNotEmpty) const SizedBox(height: 12),
          ...days.map((day) => _DayCard(day: day)),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _WarningsCard(warnings: warnings),
          ],
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.summary});

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(color: Color(0xFF647067))),
        ],
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  const _CostCard({required this.cost});

  final Map cost;

  @override
  Widget build(BuildContext context) {
    final entries = cost.entries.toList();
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(_label('${entry.key}'))),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final Object? day;

  @override
  Widget build(BuildContext context) {
    final data = day is Map ? day as Map : const {};
    final activities = data['activities'] is List
        ? data['activities'] as List
        : const [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day ${data['day'] ?? ''} - ${data['date'] ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...activities.map((activity) => _ActivityTile(activity: activity)),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final Object? activity;

  @override
  Widget build(BuildContext context) {
    final data = activity is Map ? activity as Map : const {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              '${data['time'] ?? ''}',
              style: const TextStyle(
                color: Color(0xFF0FA958),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['activity'] ?? data['destination'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if ('${data['destination'] ?? ''}'.isNotEmpty)
                  Text(
                    '${data['destination']}',
                    style: const TextStyle(color: Color(0xFF647067)),
                  ),
                if ('${data['note'] ?? ''}'.isNotEmpty)
                  Text(
                    '${data['note']}',
                    style: const TextStyle(color: Color(0xFF647067)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.warnings});

  final List warnings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warnings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('- $warning'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: child,
    );
  }
}

String _label(String value) {
  return value
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .trim()
      .toLowerCase();
}
