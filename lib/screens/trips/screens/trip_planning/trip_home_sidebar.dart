import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;

import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/core/config/api_config.dart';
import 'package:assignment/models/destination.dart';
import 'package:assignment/data/mock_data.dart';
import '../../services/trip_itinerary_service.dart';
import 'trip_tokens.dart';
import 'trip_ai_insight_card.dart';

class HomeSidebar extends StatefulWidget {
  const HomeSidebar({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<HomeSidebar> createState() => _HomeSidebarState();
}

class _HomeSidebarState extends State<HomeSidebar> {
  bool _init = false;
  String? _token;
  
  List<TripItineraryHistoryItem> _history = [];
  List<Destination> _topDestinations = [];
  bool _isLoadingHistory = true;

  
  double? _weatherTemp;
  int? _weatherCode;
  Destination? _topDestWeather;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _token = VietaiScope.of(context).auth?.accessToken;
    _fetchHistory();
    _fetchDestinations();
  }

  Future<void> _fetchHistory() async {
    try {
      final items = await TripItineraryService(authToken: _token).history();
      if (mounted) {
        setState(() {
          _history = items;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _fetchDestinations() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/destinations'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final list = decoded.whereType<Map<String, dynamic>>().map((json) {
            return Destination(
              id: json['id'] as String? ?? '',
              name: json['name'] as String? ?? '',
              latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
              longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
              tagline: '', description: '', category: '', distanceKm: 0, 
              rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
              reviewCount: 0, imageUrl: '', avgTempC: 0, climate: DestinationClimate.warm,
            );
          }).where((d) => d.id.isNotEmpty && d.name.isNotEmpty).toList();
          
          list.sort((a, b) => b.rating.compareTo(a.rating));
          
          if (mounted) {
            setState(() {
              _topDestinations = list.take(3).toList();
              if (_topDestinations.isNotEmpty) {
                _topDestWeather = _topDestinations.first;
                _fetchWeather(_topDestWeather!);
              }
            });
            return;
          }
        }
      }
    } catch (_) {}
    
    // Fallback
    final fallback = MockData.destinations.toList();
    fallback.sort((a, b) => b.rating.compareTo(a.rating));
    if (mounted) {
      setState(() {
        _topDestinations = fallback.take(3).toList();
        if (_topDestinations.isNotEmpty) {
          _topDestWeather = _topDestinations.first;
          _fetchWeather(_topDestWeather!);
        }
      });
    }
  }
  
  Future<void> _fetchWeather(Destination dest) async {
    if (dest.latitude == null || dest.longitude == null) return;
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=${dest.latitude}&longitude=${dest.longitude}&current_weather=true');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        if (current != null && mounted) {
          setState(() {
            _weatherTemp = (current['temperature'] as num).toDouble();
            _weatherCode = current['weathercode'] as int;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TripAiInsightCard(onCreate: widget.onCreate)
            .animate()
            .fadeIn(delay: 220.ms, duration: 500.ms)
            .slideX(begin: 0.04, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 16),
        
        _SidebarStatsCard(history: _history, isLoading: _isLoadingHistory),
        const SizedBox(height: 16),
        
        if (_topDestWeather != null) ...[
          _SidebarWeatherCard(
            destination: _topDestWeather!, 
            temp: _weatherTemp, 
            code: _weatherCode
          ),
          const SizedBox(height: 16),
        ],
        
        if (_topDestinations.isNotEmpty) ...[
          _SidebarListCard(
            title: 'Điểm đến thịnh hành',
            icon: Icons.local_fire_department_rounded,
            items: _topDestinations.map((d) => _SidebarListItem(
              d.name,
              '${d.rating.toStringAsFixed(1)} sao đánh giá',
              Icons.trending_up_rounded,
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        _SidebarListCard(
          title: 'Hoạt động gần đây',
          icon: Icons.history_rounded,
          items: _history.isEmpty 
              ? [const _SidebarListItem('Chưa có hoạt động', 'Hãy tạo lịch trình đầu tiên', Icons.info_outline)]
              : _history.take(3).map((h) {
                  final days = h.itinerary['days'] is List ? (h.itinerary['days'] as List).length : 0;
                  return _SidebarListItem(
                    'Đã tạo lịch trình',
                    '${h.title} ($days ngày)',
                    Icons.auto_awesome_rounded,
                  );
                }).toList(),
        ),
        const SizedBox(height: 16),
        const _TravelTipCard(),
      ],
    );
  }
}

// Stats Card
class _SidebarStatsCard extends StatelessWidget {
  const _SidebarStatsCard({required this.history, required this.isLoading});
  final List<TripItineraryHistoryItem> history;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final aiCount = history.length;
    int totalDays = 0;
    for (var h in history) {
      if (h.itinerary['days'] is List) totalDays += (h.itinerary['days'] as List).length;
    }
    
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SidebarTitle(icon: Icons.insights_rounded, title: 'Thống kê cá nhân'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MetricTile(value: isLoading ? '-' : '$aiCount', label: 'Lịch trình đã tạo')),
              const SizedBox(width: 10),
              Expanded(child: _MetricTile(value: isLoading ? '-' : '$totalDays', label: 'Tổng số ngày đi')),
            ],
          ),
        ],
      ),
    );
  }
}

// Weather Card
class _SidebarWeatherCard extends StatelessWidget {
  const _SidebarWeatherCard({required this.destination, this.temp, this.code});
  
  final Destination destination;
  final double? temp;
  final int? code;
  
  String get _desc {
    if (code == null) return 'Đang cập nhật...';
    if (code! <= 3) return 'Quang đãng, ít mây';
    if (code! <= 48) return 'Sương mù';
    if (code! <= 67) return 'Có mưa';
    return 'Thời tiết xấu';
  }

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kTripAmber.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời tiết điểm đến hot',
                  style: TextStyle(
                    color: kTripInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${destination.name} ${temp != null ? '${temp!.toStringAsFixed(1)}°C' : ''}',
                  style: const TextStyle(color: kTripMuted, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          Text(
            _desc,
            style: const TextStyle(
              color: kTripPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// List Card
class _SidebarListCard extends StatelessWidget {
  const _SidebarListCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_SidebarListItem> items;

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarTitle(icon: icon, title: title),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: kTripPrimary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(item.icon, size: 17, color: kTripPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: kTripInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kTripMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SidebarListItem {
  const _SidebarListItem(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

// Travel Tip
class _TravelTipCard extends StatefulWidget {
  const _TravelTipCard();

  @override
  State<_TravelTipCard> createState() => _TravelTipCardState();
}

class _TravelTipCardState extends State<_TravelTipCard> {
  static const _tips = [
    'Đặt chuyến đi biển vào ngày trong tuần thường rẻ hơn và khách sạn cũng yên tĩnh hơn.',
    'Du lịch mùa thấp điểm giúp bạn tiết kiệm đến 30% chi phí di chuyển.',
    'Hệ thống AI có thể tự động gộp các điểm du lịch gần nhau để tiết kiệm thời gian di chuyển của bạn.',
    'Sử dụng tính năng lên lịch trình bằng AI để khám phá các địa điểm ít người biết đến.'
  ];
  
  late String _tip;

  @override
  void initState() {
    super.initState();
    _tip = _tips[Random().nextInt(_tips.length)];
  }

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SidebarTitle(icon: Icons.tips_and_updates_rounded, title: 'Mẹo du lịch hữu ích'),
          const SizedBox(height: 10),
          Text(
            _tip,
            style: const TextStyle(color: kTripMuted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}

// Shared Metrics
class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kTripPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: kTripInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: kTripMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTitle extends StatelessWidget {
  const _SidebarTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: kTripPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: kTripInk,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SidebarCard extends StatelessWidget {
  const _SidebarCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kTripLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
