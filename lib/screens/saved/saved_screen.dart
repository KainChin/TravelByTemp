import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/destinations/destination_detail_screen.dart';
import 'package:assignment/screens/trips/screens/trip_itinerary_result_screen.dart';
import 'package:assignment/screens/trips/services/saved_itinerary_store.dart';
import 'package:assignment/services/api_client.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  var _loading = true;
  String? _error;
  List<FavoriteDestination> _favorites = [];
  List<SavedItineraryItem> _itineraries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant SavedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        VietaiScope.of(context).api.fetchFavorites(),
        SavedItineraryStore.load(),
      ]);
      if (!mounted) return;
      setState(() {
        _favorites = results[0] as List<FavoriteDestination>;
        _itineraries = results[1] as List<SavedItineraryItem>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeItinerary(SavedItineraryItem item) async {
    await SavedItineraryStore.remove(item.id);
    if (!mounted) return;
    setState(() => _itineraries.removeWhere((saved) => saved.id == item.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} removed')),
    );
  }

  Future<void> _remove(FavoriteDestination item) async {
    try {
      await VietaiScope.of(context).api.deleteFavorite(item.destination.id);
      if (!mounted) return;
      setState(() => _favorites.removeWhere((f) => f.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.destination.name} removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const Text(
              'Saved Places',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your favorite destinations appear here.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MessageCard(
                icon: Icons.cloud_off_outlined,
                title: 'Cannot load saved places',
                subtitle: 'Start the backend API, then pull to refresh.',
                actionLabel: 'Try again',
                onPressed: _load,
              )
            else if (_favorites.isEmpty && _itineraries.isEmpty)
              _MessageCard(
                icon: Icons.favorite_border,
                title: 'No saved items yet',
                subtitle: 'Save a destination or itinerary to see it here.',
                actionLabel: 'Refresh',
                onPressed: _load,
              )
            else
              ...[
                if (_itineraries.isNotEmpty) ...[
                  const Text(
                    'Saved Trips',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ..._itineraries.map(
                    (item) => _ItineraryCard(
                      item: item,
                      onOpen: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripItineraryResultScreen(
                              response: '${item.itinerary['summary'] ?? ''}',
                              itinerary: item.itinerary,
                              itineraryId: item.id,
                            ),
                          ),
                        );
                      },
                      onRemove: () => _removeItinerary(item),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_favorites.isNotEmpty)
                  const Text(
                    'Saved Places',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                if (_favorites.isNotEmpty) const SizedBox(height: 10),
              ],
            if (!_loading && _error == null)
              ..._favorites.map(
                (item) => _FavoriteCard(
                  favorite: item,
                  onOpen: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DestinationDetailScreen(
                          destination: item.destination,
                        ),
                      ),
                    );
                  },
                  onRemove: () => _remove(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.onOpen,
    required this.onRemove,
  });

  final FavoriteDestination favorite;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final destination = favorite.destination;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
        children: [
          SizedBox(
            width: 92,
            child: NetworkImageCard(
              imageUrl: destination.imageUrl,
              height: 92,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  destination.location ?? destination.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(destination.ratingLabel),
                    const SizedBox(width: 12),
                    const Icon(Icons.near_me_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(destination.distanceLabel),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
          ),
        ],
        ),
      ),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({
    required this.item,
    required this.onOpen,
    required this.onRemove,
  });

  final SavedItineraryItem item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final days = item.itinerary['days'] is List ? (item.itinerary['days'] as List).length : 0;
    final summary = '${item.itinerary['summary'] ?? 'Tap to review and edit this itinerary.'}';
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.route_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    days == 0 ? summary : '$days days • $summary',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 38, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
