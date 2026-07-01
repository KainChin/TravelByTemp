import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/destinations/destination_detail_screen.dart';
import 'package:assignment/screens/saved/saved_trip_detail_screen.dart';
import 'package:assignment/screens/trips/services/saved_itinerary_store.dart';
import 'package:assignment/screens/trips/services/trip_itinerary_service.dart';
import 'package:assignment/services/api_client.dart';
import 'package:flutter/material.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({
    super.key,
    required this.refreshToken,
    this.onHomePressed,
  });

  final int refreshToken;
  final VoidCallback? onHomePressed;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant SavedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        VietaiScope.of(context).api.fetchFavorites(),
        SavedItineraryStore.load(),
        _loadRemoteItineraries(),
      ]);
      if (!mounted) return;
      final localItineraries = results[1] as List<SavedItineraryItem>;
      final remoteItineraries = results[2] as List<SavedItineraryItem>;
      setState(() {
        _favorites = results[0] as List<FavoriteDestination>;
        _itineraries = _mergeItineraries(remoteItineraries, localItineraries);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<SavedItineraryItem>> _loadRemoteItineraries() async {
    try {
      final token = VietaiScope.of(context).auth?.accessToken;
      final remote = await TripItineraryService(authToken: token).history();
      return remote.map((item) {
        return SavedItineraryItem(
          id: item.id,
          title: item.title,
          savedAt: item.createdAt,
          itinerary: item.itinerary,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  List<SavedItineraryItem> _mergeItineraries(
    List<SavedItineraryItem> remote,
    List<SavedItineraryItem> local,
  ) {
    final byId = <String, SavedItineraryItem>{};
    for (final item in [...local, ...remote]) {
      byId[item.id] = item;
    }
    final items = byId.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  Future<void> _removeItinerary(SavedItineraryItem item) async {
    await _removeRemoteItinerary(item.id);
    await SavedItineraryStore.remove(item.id);
    if (!mounted) return;
    setState(() => _itineraries.removeWhere((saved) => saved.id == item.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa ${item.title}')),
    );
  }

  Future<void> _removeRemoteItinerary(String id) async {
    try {
      final token = VietaiScope.of(context).auth?.accessToken;
      await TripItineraryService(authToken: token).deleteItinerary(id);
    } catch (_) {
      // Keep local deletion responsive even when backend is offline.
    }
  }

  Future<void> _remove(FavoriteDestination item) async {
    try {
      await VietaiScope.of(context).api.deleteFavorite(item.destination.id);
      if (!mounted) return;
      setState(() => _favorites.removeWhere((favorite) => favorite.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa ${item.destination.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _openItinerary(SavedItineraryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedTripDetailScreen(item: item),
      ),
    ).then((_) => _load()); // reload if deleted inside detail
  }

  void _openFavorite(FavoriteDestination item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationDetailScreen(destination: item.destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  _SavedHeader(
                    savedTrips: _itineraries.length,
                    savedPlaces: _favorites.length,
                    onHomePressed: _goHome,
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _MessageCard(
                      icon: Icons.cloud_off_outlined,
                      title: 'Chưa tải được danh sách đã lưu',
                      subtitle: 'Kiểm tra backend API rồi kéo xuống để tải lại.',
                      actionLabel: 'Thử lại',
                      onPressed: _load,
                    )
                  else if (_favorites.isEmpty && _itineraries.isEmpty)
                    _MessageCard(
                      icon: Icons.favorite_border,
                      title: 'Chưa có mục đã lưu',
                      subtitle: 'Lưu địa điểm hoặc hành trình để xem lại tại đây.',
                      actionLabel: 'Tải lại',
                      onPressed: _load,
                    )
                  else ...[
                    if (_itineraries.isNotEmpty) ...[
                      const _SectionTitle(
                        title: 'Hành trình đã lưu',
                        icon: Icons.route_outlined,
                      ),
                      const SizedBox(height: 10),
                      ..._itineraries.map(
                        (item) => _ItineraryCard(
                          item: item,
                          onOpen: () => _openItinerary(item),
                          onRemove: () => _removeItinerary(item),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_favorites.isNotEmpty) ...[
                      const _SectionTitle(
                        title: 'Địa điểm yêu thích',
                        icon: Icons.favorite_border,
                      ),
                      const SizedBox(height: 10),
                      ..._favorites.map(
                        (item) => _FavoriteCard(
                          favorite: item,
                          onOpen: () => _openFavorite(item),
                          onRemove: () => _remove(item),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goHome() {
    if (widget.onHomePressed != null) {
      widget.onHomePressed!();
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _SavedHeader extends StatelessWidget {
  const _SavedHeader({
    required this.savedTrips,
    required this.savedPlaces,
    required this.onHomePressed,
  });

  final int savedTrips;
  final int savedPlaces;
  final VoidCallback onHomePressed;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (canPop) ...[
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(width: 10),
            ],
            const Expanded(
              child: Text(
                'Đã lưu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: onHomePressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text(
                'Trang chủ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Xem lại hành trình và địa điểm bạn muốn giữ cho chuyến đi sau.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SummaryChip(
              icon: Icons.route_outlined,
              label: '$savedTrips hành trình',
            ),
            _SummaryChip(
              icon: Icons.favorite_border,
              label: '$savedPlaces địa điểm',
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.location ?? destination.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _InlineMeta(
                            icon: Icons.star,
                            label: destination.ratingLabel,
                            color: Colors.amber,
                          ),
                          _InlineMeta(
                            icon: Icons.near_me_outlined,
                            label: destination.distanceLabel,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa khỏi đã lưu',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          ),
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
    final days = item.itinerary['days'] is List
        ? (item.itinerary['days'] as List).length
        : 0;
    final summary =
        '${item.itinerary['summary'] ?? 'Mở để xem lại và chỉnh sửa hành trình.'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        days == 0 ? summary : '$days ngày • $summary',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa hành trình',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 38, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
