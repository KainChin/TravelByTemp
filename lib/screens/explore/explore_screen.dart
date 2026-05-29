import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/core/widgets/network_image_card.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/data/mock_data.dart';
import 'package:assignment/models/destination.dart';
import 'package:assignment/screens/filter/search_filter_screen.dart';
import 'package:assignment/screens/trips/ai_itinerary_screen.dart';
import 'package:assignment/services/app_session.dart';
import 'package:assignment/services/temperature_destination_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _tempService = const TemperatureDestinationService();
  String _selectedCategory = 'all';
  List<Destination> _allDestinations = [];
  List<Destination> _recommended = [];
  var _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDestinations());
  }

  Future<void> _loadDestinations() async {
    final session = VietaiScope.of(context);
    try {
      final list = await session.api.fetchDestinations();
      if (!mounted) return;
      setState(() {
        _allDestinations = list;
        _applyRecommendations(session.userTemperatureC);
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allDestinations = MockData.destinations;
        _applyRecommendations(session.userTemperatureC);
        _loading = false;
        _loadError = 'Dùng dữ liệu offline (API chưa sẵn sàng)';
      });
    }
  }

  void _applyRecommendations(double tempC) {
    _recommended = _tempService.recommend(
      userTempC: tempC,
      all: _allDestinations.isEmpty ? MockData.destinations : _allDestinations,
    );
  }

  List<Destination> get _filteredDestinations {
    if (_selectedCategory == 'all') return _recommended;
    final cat = MockData.categories
        .firstWhere((c) => c.id == _selectedCategory)
        .label;
    return _recommended.where((d) => d.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final tempMsg = _tempService.recommendationMessage(
      session.userTemperatureC,
      session.locationName,
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await session.refreshLocationAndWeather();
          await _loadDestinations();
        },
        child: CustomScrollView(
        slivers: [
          if (_loadError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(_loadError!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ),
            ),
          SliverToBoxAdapter(child: _buildHeader(session)),
          SliverToBoxAdapter(child: _buildGreeting()),
          SliverToBoxAdapter(child: _buildSearch(context)),
          SliverToBoxAdapter(child: _buildCategories()),
          SliverToBoxAdapter(child: _buildTempBanner(tempMsg, session)),
          SliverToBoxAdapter(child: _buildAiBanner(context)),
          SliverToBoxAdapter(child: _buildSectionHeader('Popular Destinations')),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            )
          else
            SliverToBoxAdapter(child: _buildDestinationsList()),
          SliverToBoxAdapter(
            child: _buildSectionHeader('Top Experiences for You'),
          ),
          SliverToBoxAdapter(child: _buildExperiencesList()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader(AppSession session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        session.locationName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              children: [
                TextSpan(text: 'Discover\n'),
                TextSpan(
                  text: 'Your Escape ',
                  style: TextStyle(color: AppColors.primary),
                ),
                WidgetSpan(
                  child: Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.auto_awesome,
                        size: 18, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Local getaways, unforgettable memories.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textHint.withValues(alpha: 0.8)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Where do you want to go?',
                  style: TextStyle(color: AppColors.textHint, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        itemCount: MockData.categories.length,
        itemBuilder: (_, i) {
          final cat = MockData.categories[i];
          final selected = _selectedCategory == cat.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat.id),
            child: Container(
              width: 72,
              margin: EdgeInsets.only(right: i < MockData.categories.length - 1 ? 10 : 0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.cardBorder,
                  width: selected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat.icon,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTempBanner(String message, AppSession session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.thermostat, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session.userTemperatureC.toStringAsFixed(0)}°C · ${session.weatherDescription}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan smarter with AI',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Get your perfect\nitinerary in seconds',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personalized suggestions, just for you.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.luggage, size: 48, color: AppColors.primary),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AiItineraryScreen()),
                ),
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Try AI\nPlanner',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Text(
            'See All >',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsList() {
    final list = _filteredDestinations;
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        itemBuilder: (_, i) => _DestinationCard(destination: list[i]),
      ),
    );
  }

  Widget _buildExperiencesList() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: MockData.experiences.length,
        itemBuilder: (_, i) {
          final exp = MockData.experiences[i];
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: i < MockData.experiences.length - 1 ? 14 : 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    NetworkImageCard(
                      imageUrl: exp.imageUrl,
                      height: 110,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          exp.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        exp.location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${exp.distanceKm.toStringAsFixed(0)}km',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          Text(' ${exp.rating}', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exp.price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '~${exp.avgTempC.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              NetworkImageCard(
                imageUrl: destination.imageUrl,
                height: 130,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, size: 18),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '~${destination.avgTempC.toStringAsFixed(0)}°C',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        destination.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.park, size: 16, color: AppColors.primary),
                  ],
                ),
                Text(
                  destination.tagline,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      destination.distanceLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(
                      ' ${destination.ratingLabel}',
                      style: const TextStyle(fontSize: 11),
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
