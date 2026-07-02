// ignore_for_file: unnecessary_library_name
library destination_detail_screen;

import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/gradient_button.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/models/destination.dart';
import 'package:assignment/screens/trips/screens/create_trip_screen.dart';
import 'package:assignment/services/api_client.dart';

part 'destination_detail/destination_detail_widgets.dart';

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
