import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/data/mock_data.dart';
import 'package:assignment/models/destination.dart';
import 'package:assignment/screens/filter/search_filter_screen.dart';
import 'package:assignment/screens/trips/ai_itinerary_screen.dart';
import 'package:assignment/screens/trips/map_view_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Destination> _destinations = MockData.destinations;
  DestinationSearchFilter? _filter;
  var _loading = true;

  static const _heroImage =
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = VietaiScope.of(context);
    try {
      final filter = _filter;
      final items = await session.api.fetchDestinations(
        category: filter?.category,
        maxBudget: filter?.maxBudget,
        latitude: filter == null ? null : session.latitude,
        longitude: filter == null ? null : session.longitude,
        radiusKm: filter?.radiusKm,
      );
      if (!mounted) return;
      setState(() {
        _destinations = items.isEmpty && _filter == null ? MockData.destinations : items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final featured = _destinations.isNotEmpty ? _destinations.first : MockData.destinations.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await session.refreshLocationAndWeather();
            await _load();
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _HeroHeader(
                location: session.locationName,
                heroImage: _heroImage,
                onRefresh: () async {
                  await session.refreshLocationAndWeather();
                  await _load();
                },
              ),
              _SearchBar(onTap: () async {
                final filter = await Navigator.push<DestinationSearchFilter>(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
                );
                if (filter == null || !mounted) return;
                setState(() {
                  _filter = filter;
                  _loading = true;
                });
                await _load();
              }),
              _CurrentLocation(
                location: session.locationName,
                weather: '${session.userTemperatureC.toStringAsFixed(0)}C - ${session.weatherDescription}',
                onRefresh: session.refreshLocationAndWeather,
              ),
              _SectionHeader(title: 'Popular destinations', action: 'See all'),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_destinations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: _EmptyDestinations(),
                )
              else
                _PopularDestinations(destinations: _destinations),
              _SectionHeader(title: 'Map & Route', action: 'View full map'),
              _RouteMap(destination: featured),
              _DestinationConfirm(destination: featured),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  children: [
                    Text('Or let AI plan for you', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(width: 6),
                    Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
              _AiPlannerCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiItineraryScreen()),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.location,
    required this.heroImage,
    required this.onRefresh,
  });

  final String location;
  final String heroImage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(heroImage, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.92),
                  Colors.white.withValues(alpha: 0.58),
                  const Color(0xFFF7FAF8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconButton(icon: Icons.refresh, onTap: () => onRefresh()),
                    const Spacer(),
                    Text(location, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Plan Your Trip',
                        style: TextStyle(
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Where do you want to go?',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search destination...',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ),
                  Icon(Icons.my_location, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentLocation extends StatelessWidget {
  const _CurrentLocation({
    required this.location,
    required this.weather,
    required this.onRefresh,
  });

  final String location;
  final String weather;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: Color(0xFFEAF3FF), shape: BoxShape.circle),
              child: const Icon(Icons.radio_button_checked, color: Color(0xFF2878FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current location', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(weather, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            TextButton(onPressed: () => onRefresh(), child: const Text('Change')),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}

class _EmptyDestinations extends StatelessWidget {
  const _EmptyDestinations();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.travel_explore, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No destinations match this filter. Try a larger radius or budget.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularDestinations extends StatelessWidget {
  const _PopularDestinations({required this.destinations});

  final List<Destination> destinations;

  @override
  Widget build(BuildContext context) {
    final list = destinations.take(6).toList();
    return SizedBox(
      height: 172,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (_, index) => _SmallDestinationCard(destination: list[index]),
      ),
    );
  }
}

class _SmallDestinationCard extends StatelessWidget {
  const _SmallDestinationCard({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkImageCard(
            imageUrl: destination.imageUrl,
            height: 94,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(destination.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.primary),
                    Expanded(
                      child: Text(
                        destination.distanceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 330,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _VietnamMapPainter()),
              CustomPaint(painter: _RoutePainter()),
              const Positioned(
                left: 28,
                bottom: 30,
                child: _MapPin(label: 'Ho Chi Minh City', icon: Icons.my_location, color: Color(0xFF2878FF)),
              ),
              Positioned(
                right: 52,
                top: 52,
                child: _MapPin(label: destination.name, icon: Icons.location_on, color: Colors.redAccent),
              ),
              const Positioned(left: 190, top: 170, child: _MapLabel('Bao Loc')),
              const Positioned(right: 74, bottom: 92, child: _MapLabel('Phan Thiet')),
              const Positioned(left: 46, bottom: 78, child: _MapLabel('Ho Chi Minh City')),
              const Positioned(right: 30, bottom: 24, child: _MapLabel('East Sea')),
              Positioned(
                left: 116,
                top: 108,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.directions_car, size: 18),
                      SizedBox(width: 8),
                      Text('6h 35m\n294 km', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const Positioned(right: 18, top: 70, child: _FloatingRound(icon: Icons.layers_outlined)),
              const Positioned(right: 18, bottom: 86, child: _ZoomControl()),
              const Positioned(right: 18, bottom: 24, child: _FloatingRound(icon: Icons.navigation, filled: true)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationConfirm extends StatelessWidget {
  const _DestinationConfirm({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: NetworkImageCard(
                      imageUrl: destination.imageUrl,
                      height: 92,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(destination.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            ),
                            const Icon(Icons.verified, size: 16, color: AppColors.primary),
                          ],
                        ),
                        Text(destination.location ?? 'Vietnam', style: const TextStyle(color: AppColors.textSecondary)),
                        const Text('City of eternal spring', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.directions_car, size: 16),
                            SizedBox(width: 8),
                            Text('6h 35m (294 km)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${destination.name} saved')),
                      );
                    },
                    icon: const Icon(Icons.favorite_border),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapViewScreen()),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm Destination', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiPlannerCard extends StatelessWidget {
  const _AiPlannerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFFF7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.smart_toy_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Trip Planner', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      Text('Get a personalized itinerary based on your budget, time and style.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(label: 'Generate with AI', icon: Icons.auto_awesome, onPressed: onTap),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 52, height: 52, child: Icon(icon)),
      ),
    );
  }
}

class _FloatingRound extends StatelessWidget {
  const _FloatingRound({required this.icon, this.filled = false});

  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
      ),
      child: Icon(icon, color: filled ? Colors.white : AppColors.textPrimary),
    );
  }
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: const Column(
        children: [
          SizedBox(height: 10),
          Icon(Icons.add),
          Divider(height: 12),
          Icon(Icons.remove),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 34),
        Container(
          constraints: const BoxConstraints(maxWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _VietnamMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFCFEAF2));

    final landPaint = Paint()..color = const Color(0xFFEAF5DC);
    final land = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.56, 0)
      ..cubicTo(size.width * 0.52, size.height * 0.12, size.width * 0.48, size.height * 0.18, size.width * 0.52, size.height * 0.28)
      ..cubicTo(size.width * 0.60, size.height * 0.45, size.width * 0.48, size.height * 0.56, size.width * 0.40, size.height * 0.68)
      ..cubicTo(size.width * 0.31, size.height * 0.80, size.width * 0.22, size.height * 0.88, size.width * 0.18, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(land, landPaint);

    final coastPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final coast = Path()
      ..moveTo(size.width * 0.56, 0)
      ..cubicTo(size.width * 0.52, size.height * 0.12, size.width * 0.48, size.height * 0.18, size.width * 0.52, size.height * 0.28)
      ..cubicTo(size.width * 0.60, size.height * 0.45, size.width * 0.48, size.height * 0.56, size.width * 0.40, size.height * 0.68)
      ..cubicTo(size.width * 0.31, size.height * 0.80, size.width * 0.22, size.height * 0.88, size.width * 0.18, size.height);
    canvas.drawPath(coast, coastPaint);

    final provincePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(size.width * 0.02, y), Offset(size.width * 0.50, y - 18), provincePaint);
    }

    final islandPaint = Paint()..color = const Color(0xFFEAF5DC);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.80, size.height * 0.58), width: 34, height: 46),
      islandPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.88, size.height * 0.76), width: 18, height: 24),
      islandPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapLabel extends StatelessWidget {
  const _MapLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary.withValues(alpha: 0.58),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.82)
      ..cubicTo(size.width * 0.28, size.height * 0.72, size.width * 0.32, size.height * 0.67, size.width * 0.39, size.height * 0.62)
      ..cubicTo(size.width * 0.52, size.height * 0.52, size.width * 0.46, size.height * 0.38, size.width * 0.62, size.height * 0.30)
      ..cubicTo(size.width * 0.72, size.height * 0.24, size.width * 0.78, size.height * 0.17, size.width * 0.84, size.height * 0.12);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = Colors.white;
    for (final p in [
      Offset(size.width * 0.28, size.height * 0.72),
      Offset(size.width * 0.43, size.height * 0.58),
      Offset(size.width * 0.58, size.height * 0.33),
      Offset(size.width * 0.72, size.height * 0.23),
    ]) {
      canvas.drawCircle(p, 6, dotPaint);
      canvas.drawCircle(p, 3.5, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
