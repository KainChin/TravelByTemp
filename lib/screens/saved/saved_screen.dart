// ignore_for_file: unnecessary_library_name
library saved_screen;

import 'dart:convert';

import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/destinations/destination_detail_screen.dart';
import 'package:assignment/screens/saved/saved_trip_detail_screen.dart';
import 'package:assignment/screens/trips/services/saved_itinerary_store.dart';
import 'package:assignment/screens/trips/services/trip_itinerary_service.dart';
import 'package:assignment/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'saved/saved_header.dart';
part 'saved/stat_card.dart';
part 'saved/quick_action_chip.dart';
part 'saved/favorite_card.dart';
part 'saved/itinerary_card.dart';
part 'saved/message_card.dart';
part 'saved/ai_suggestion_card.dart';

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
  
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    } catch (error, stackTrace) {
      debugPrint('[Saved] Could not load remote itineraries: $error');
      debugPrintStack(stackTrace: stackTrace);
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
    try {
    await _removeRemoteItinerary(item.id);
    await SavedItineraryStore.remove(item.id);
    if (!mounted) return;
    setState(() => _itineraries.removeWhere((saved) => saved.id == item.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa ${item.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    } catch (error, stackTrace) {
      debugPrint('[Saved] Could not remove itinerary ${item.id}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _removeRemoteItinerary(String id) async {
    try {
      final token = VietaiScope.of(context).auth?.accessToken;
      await TripItineraryService(authToken: token).deleteItinerary(id);
    } catch (error, stackTrace) {
      debugPrint('[Saved] Could not delete remote itinerary $id: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _remove(FavoriteDestination item) async {
    try {
      await VietaiScope.of(context).api.deleteFavorite(item.destination.id);
      if (!mounted) return;
      setState(() => _favorites.removeWhere((favorite) => favorite.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${item.destination.name}'),
          behavior: SnackBarBehavior.floating,
        ),
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

  Future<void> _renameItinerary(SavedItineraryItem item) async {
    final token = VietaiScope.of(context).auth?.accessToken;
    final controller = TextEditingController(text: item.title);
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên hành trình'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên hành trình mới',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF16A34A)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu', style: TextStyle(color: Color(0xFF16A34A))),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (nextName != null && nextName.isNotEmpty && nextName != item.title) {
      final map = {
        ...item.itinerary,
        'title': nextName,
        'id': item.id,
      };
      try {
        await TripItineraryService(authToken: token).saveItinerary(
          itineraryId: item.id,
          itinerary: map,
        );
      } catch (error, stackTrace) {
        debugPrint('[Saved] Could not rename remote itinerary ${item.id}: $error');
        debugPrintStack(stackTrace: stackTrace);
        await SavedItineraryStore.remove(item.id);
        await SavedItineraryStore.save(map);
      }
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đổi tên thành "$nextName"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cloneItinerary(SavedItineraryItem item) async {
    final clonedTitle = '${item.title} (Bản sao)';
    final clonedId = '${item.id}-copy-${DateTime.now().millisecondsSinceEpoch}';
    final map = {
      ...item.itinerary,
      'title': clonedTitle,
      'id': clonedId,
    };
    try {
      final token = VietaiScope.of(context).auth?.accessToken;
      final saved = await TripItineraryService(authToken: token).saveItinerary(
        itinerary: map,
      );
      await SavedItineraryStore.save({
        ...saved.itinerary,
        'id': saved.id,
        'title': saved.title,
      });
    } catch (error, stackTrace) {
      debugPrint('[Saved] Could not clone itinerary remotely: $error');
      debugPrintStack(stackTrace: stackTrace);
      await SavedItineraryStore.save(map);
    }
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép hành trình thành công!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareItinerary(SavedItineraryItem item) {
    Clipboard.setData(ClipboardData(text: 'Khám phá hành trình: ${item.title} \n${item.itinerary['summary'] ?? ''}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép liên kết chia sẻ hành trình!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportItineraryPdf(SavedItineraryItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang xuất PDF hành trình "${item.title}"...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<SavedItineraryItem> get _filteredItineraries {
    final query = _searchQuery.toLowerCase().trim();
    if (query.isEmpty) return _itineraries;
    return _itineraries.where((item) {
      final title = item.title.toLowerCase();
      final summary = (item.itinerary['summary'] ?? '').toString().toLowerCase();
      return title.contains(query) || summary.contains(query);
    }).toList();
  }

  List<FavoriteDestination> get _filteredFavorites {
    final query = _searchQuery.toLowerCase().trim();
    if (query.isEmpty) return _favorites;
    return _favorites.where((item) {
      final name = item.destination.name.toLowerCase();
      final location = (item.destination.location ?? '').toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 260,
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
      ),
    );
  }

  Widget _buildError() {
    return _MessageCard(
      icon: Icons.cloud_off_rounded,
      title: 'Chưa tải được danh sách đã lưu',
      subtitle: 'Kiểm tra kết nối và kéo xuống để tải lại dữ liệu.',
      actionLabel: 'Thử lại',
      onPressed: _load,
    );
  }

  Widget _buildEmptyState() {
    return _MessageCard(
      icon: Icons.favorite_border_rounded,
      title: 'Bạn chưa lưu hành trình nào',
      subtitle: 'Hãy tạo hoặc lưu hành trình đầu tiên để AI có thể hỗ trợ bạn nhanh hơn.',
      actionLabel: 'Tạo hành trình',
      onPressed: _goHome,
    );
  }

  Widget _buildItinerarySection() {
    final showInlineSuggestion = MediaQuery.of(context).size.width < 1024;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showInlineSuggestion) ...[
          const _AISuggestionCard(),
          const SizedBox(height: 20),
        ],
        const _SectionTitle(
          title: 'Hành trình đã lưu',
          icon: Icons.map_rounded,
        ),
        const SizedBox(height: 12),
        if (_filteredItineraries.isEmpty && _searchQuery.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Không tìm thấy hành trình phù hợp',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
          )
        else
          ..._filteredItineraries.map(
            (item) => _ItineraryCard(
              item: item,
              onOpen: () => _openItinerary(item),
              onRename: () => _renameItinerary(item),
              onClone: () => _cloneItinerary(item),
              onShare: () => _shareItinerary(item),
              onExportPdf: () => _exportItineraryPdf(item),
              onRemove: () => _removeItinerary(item),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Địa điểm yêu thích',
          icon: Icons.favorite_border_rounded,
        ),
        const SizedBox(height: 12),
        if (_filteredFavorites.isEmpty && _searchQuery.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Không tìm thấy địa điểm phù hợp',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
          )
        else
          ..._filteredFavorites.map(
            (item) => _FavoriteCard(
              favorite: item,
              onOpen: () => _openFavorite(item),
              onRemove: () => _remove(item),
            ),
          ),
      ],
    );
  }

  Widget _buildSavedBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_favorites.isEmpty && _itineraries.isEmpty) return _buildEmptyState();
    return Column(
      children: [
        if (_itineraries.isNotEmpty) _buildItinerarySection(),
        if (_favorites.isNotEmpty) _buildFavoritesSection(),
      ],
    );
  }

  Widget _buildSavedSidebar() {
    return Column(
      children: [
        const _AISuggestionCard(),
        const SizedBox(height: 16),
        _SavedDashboardPanel(
          trips: _itineraries.length,
          places: _favorites.length,
        ),
        const SizedBox(height: 16),
        const _SavedInsightPanel(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final isDesktop = width >= 1024;
    final padding = isTablet
        ? const EdgeInsets.symmetric(horizontal: 28, vertical: 32)
        : const EdgeInsets.all(16);
    final maxWidth = isDesktop ? 1240.0 : (isTablet ? 900.0 : double.infinity);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF7FBF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF16A34A),
                child: ListView(
                  padding: padding,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _SavedHeader(
                      savedTrips: _itineraries.length,
                      savedPlaces: _favorites.length,
                      onHomePressed: _goHome,
                      searchController: _searchController,
                      onQuickAction: (action) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đang kích hoạt: $action'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildSavedBody()),
                          const SizedBox(width: 28),
                          SizedBox(width: 360, child: _buildSavedSidebar()),
                        ],
                      )
                    else
                      _buildSavedBody(),
                  ],
                ),
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
