import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/models/destination.dart';
import 'package:assignment/screens/trips/screens/create_trip_screen.dart';
import 'package:assignment/services/api_client.dart';

class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({super.key, required this.destination});

  final Destination destination;

  @override
  State<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  late Destination _destination = widget.destination;
  var _loading = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDetail();
    });
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = VietaiScope.of(context).api;
      final isFavorite = await _isFavorite(api, _destination.id);
      final detail = await api.fetchDestination(_destination.id);
      if (!mounted) return;
      setState(() => _destination = detail.copyWith(isFavorite: isFavorite));
    } on ApiException {
      // Mock fallback ids are not available from the API; keep the passed item.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _isFavorite(ApiClient api, String destinationId) async {
    try {
      final favorites = await api.fetchFavorites();
      return favorites.any((f) => f.destination.id == destinationId);
    } catch (_) {
      return _destination.isFavorite;
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _saving = true);
    try {
      final api = VietaiScope.of(context).api;
      if (_destination.isFavorite) {
        await api.deleteFavorite(_destination.id);
      } else {
        await api.addFavorite(_destination.id);
      }
      if (!mounted) return;
      final saved = !_destination.isFavorite;
      setState(() => _destination = _destination.copyWith(isFavorite: saved));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? '${_destination.name} saved' : '${_destination.name} removed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(destination: _destination, loading: _loading),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _destination.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _destination.location ?? _destination.tagline,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _saving ? null : _toggleFavorite,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _destination.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _destination.isFavorite
                                    ? Colors.redAccent
                                    : null,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Stats(destination: _destination),
                  const SizedBox(height: 22),
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _destination.description.isEmpty
                        ? 'A recommended destination based on your travel style, budget, location, and current weather.'
                        : _destination.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _InfoGrid(destination: _destination),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Generate AI Itinerary',
                    icon: Icons.auto_awesome,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateTripScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.destination, required this.loading});

  final Destination destination;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkImageCard(
            imageUrl: destination.imageUrl,
            height: 300,
            borderRadius: BorderRadius.zero,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.32),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.46),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _RoundIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.maybePop(context),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.thermostat, size: 17, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('${destination.avgTempC.toStringAsFixed(0)}C'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(icon: Icons.star, label: 'Rating', value: destination.ratingLabel),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.near_me, label: 'Distance', value: destination.distanceLabel),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.payments_outlined,
          label: 'Budget',
          value: destination.price ?? 'Flexible',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 86,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const Spacer(),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.category_outlined, 'Type', destination.category),
      (Icons.place_outlined, 'Province', destination.location ?? 'Vietnam'),
      (Icons.cloud_outlined, 'Weather fit', _climateLabel(destination.climate)),
      (Icons.pin_drop_outlined, 'Coordinates', _coords(destination)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.85,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(item.$1, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _coords(Destination destination) {
    final lat = destination.latitude;
    final lon = destination.longitude;
    if (lat == null || lon == null) return 'Unknown';
    return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
  }

  String _climateLabel(DestinationClimate climate) {
    return switch (climate) {
      DestinationClimate.hot => 'Hot',
      DestinationClimate.warm => 'Warm',
      DestinationClimate.cool => 'Cool',
      DestinationClimate.cold => 'Cold',
    };
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(width: 48, height: 48, child: Icon(icon)),
      ),
    );
  }
}
