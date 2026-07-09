// ignore_for_file: unnecessary_library_name
library saved_screen;

import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/utils/destination_images.dart';
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
part 'saved_screen_logic.dart';
part 'saved_screen_builders.dart';

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
                      totalDays: _totalItineraryDays,
                      totalActivities: _totalItineraryActivities,
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

}

