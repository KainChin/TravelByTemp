import 'package:flutter/material.dart';

class TripItem {
  final String name;
  final String country;
  final String date;
  final String imageUrl;

  const TripItem({required this.name, required this.country, required this.date, required this.imageUrl});
}

class MyTripsSection extends StatelessWidget {
  const MyTripsSection({super.key});

  static const _trips = [
    TripItem(name: 'Da Nang', country: 'Vietnam',  date: 'May 2024', imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200'),
    TripItem(name: 'Sapa',    country: 'Vietnam',  date: 'Apr 2024', imageUrl: 'https://images.unsplash.com/photo-1508193638397-1c4234db14d8?w=200'),
    TripItem(name: 'Japan',   country: 'Japan',    date: 'Mar 2024', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=200'),
    TripItem(name: 'Hoi An',  country: 'Vietnam',  date: 'Feb 2024', imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=200'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _trips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _TripCard(trip: _trips[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.map_outlined, color: Color(0xFF3A7D5A), size: 20),
        const SizedBox(width: 6),
        const Text('My Trips', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: const Row(
            children: [
              Text('View all', style: TextStyle(fontSize: 13, color: Color(0xFF3A7D5A), fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right, size: 16, color: Color(0xFF3A7D5A)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripItem trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(trip.imageUrl, width: 90, height: 80, fit: BoxFit.cover),
              ),
              Positioned(
                bottom: 4, left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00643C).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(trip.date, style: const TextStyle(color: Colors.white, fontSize: 9)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(trip.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF888888)),
              Text(trip.country, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
            ],
          ),
        ],
      ),
    );
  }
}