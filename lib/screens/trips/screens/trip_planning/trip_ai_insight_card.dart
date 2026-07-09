import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:assignment/core/config/api_config.dart';
import 'package:assignment/models/destination.dart';
import 'package:assignment/data/mock_data.dart';
import 'trip_tokens.dart';

class TripAiInsightCard extends StatefulWidget {
  const TripAiInsightCard({super.key, required this.onCreate});

  final VoidCallback onCreate;

  // Add back the removed field just to satisfy Hot Reload
  static const _insights = [
    _InsightData(
      Icons.trending_down_rounded,
      'Gia ve dang giam',
      'Thap hon khoang 15% so voi tuan truoc.',
      Color(0xFF22C55E),
    )
  ];

  @override
  State<TripAiInsightCard> createState() => _TripAiInsightCardState();
}

// Add back the removed class just to satisfy Hot Reload
class _InsightData {
  const _InsightData(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _WeatherInfo {
  final double temperature;
  final int weatherCode;
  
  _WeatherInfo(this.temperature, this.weatherCode);

  String get description {
    if (weatherCode <= 3) return 'Quang đãng, ít mây';
    if (weatherCode <= 48) return 'Sương mù';
    if (weatherCode <= 57) return 'Mưa phùn';
    if (weatherCode <= 67) return 'Mưa rào';
    if (weatherCode <= 77) return 'Tuyết rơi';
    if (weatherCode <= 82) return 'Mưa lớn';
    if (weatherCode <= 86) return 'Mưa tuyết';
    if (weatherCode >= 95) return 'Có dông bão';
    return 'Không rõ';
  }

  IconData get icon {
    if (weatherCode <= 3) return Icons.wb_sunny_rounded;
    if (weatherCode <= 48) return Icons.foggy;
    if (weatherCode <= 67) return Icons.water_drop_rounded;
    if (weatherCode <= 82) return Icons.thunderstorm_rounded;
    if (weatherCode >= 95) return Icons.flash_on_rounded;
    return Icons.cloud_rounded;
  }

  Color get color {
    if (weatherCode <= 3) return const Color(0xFFF59E0B);
    if (weatherCode <= 48) return const Color(0xFF94A3B8);
    if (weatherCode <= 82) return const Color(0xFF3B82F6);
    return const Color(0xFF6366F1);
  }
}

class _TripAiInsightCardState extends State<TripAiInsightCard> {
  final TextEditingController _searchController = TextEditingController();
  List<Destination> _allDestinations = [];
  String _searchQuery = '';
  
  final Map<String, _WeatherInfo?> _weatherData = {};
  final Set<String> _loadingWeather = {};
  
  bool _isLoadingDestinations = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');

  bool _matches(Destination destination) {
    final queryText = _searchQuery ?? '';
    if (queryText.trim().isEmpty) return true;
    final query = _normalize(queryText);
    final haystack = _normalize(destination.name);
    return haystack.contains(query);
  }

  Future<void> _loadDestinations() async {
    setState(() {
      _isLoadingDestinations = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/destinations'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Cannot load destinations from backend.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw StateError('Invalid payload format.');
      }

      final list = decoded.whereType<Map<String, dynamic>>().map((json) {
        return Destination(
          id: json['id'] as String? ?? '',
          name: json['name'] as String? ?? '',
          latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
          tagline: '',
          description: '',
          category: '',
          distanceKm: 0,
          rating: 0,
          reviewCount: 0,
          imageUrl: '',
          avgTempC: 0,
          climate: DestinationClimate.warm,
        );
      }).where((d) => d.id.isNotEmpty && d.name.isNotEmpty && d.latitude != 0 && d.longitude != 0).toList();

      if (mounted) {
        setState(() {
          _allDestinations = list;
          _isLoadingDestinations = false;
        });
      }
    } catch (e) {
      // Fallback to MockData if API fails
      importMockData();
    }
  }
  
  void importMockData() {
    // We already have mock_data.dart imported
    final list = MockData.destinations
      .where((d) => d.latitude != null && d.longitude != null)
      .toList();
    if (mounted) {
      setState(() {
        _allDestinations = list;
        _isLoadingDestinations = false;
        // Don't show error, just use mock data gracefully
        _error = null;
      });
    }
  }

  void _fetchWeatherFor(Destination dest) async {
    if (_weatherData.containsKey(dest.name) || _loadingWeather.contains(dest.name)) return;
    
    _loadingWeather.add(dest.name);
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${dest.latitude}&longitude=${dest.longitude}&current_weather=true');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        if (current != null) {
          if (mounted) {
            setState(() {
              _weatherData[dest.name] = _WeatherInfo(
                (current['temperature'] as num).toDouble(),
                current['weathercode'] as int,
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching weather for ${dest.name}: $e');
    } finally {
      _loadingWeather.remove(dest.name);
      if (mounted) {
        setState(() {}); // trigger rebuild to remove loading indicator
      }
    }
  }
  
  List<Destination> get _defaultProminentDestinations {
    const prominentNames = ['Đà Lạt', 'Phú Quốc', 'Hà Nội', 'Đà Nẵng', 'Hồ Chí Minh', 'Nha Trang'];
    final prominent = _allDestinations.where((d) => prominentNames.any((name) => d.name.contains(name))).toList();
    if (prominent.length >= 5) return prominent.take(5).toList();
    
    // Fallback if not found
    final combined = {...prominent, ..._allDestinations}.toList();
    return combined.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final queryText = _searchQuery ?? '';
    final filteredDestinations = queryText.trim().isEmpty 
        ? _defaultProminentDestinations 
        : _allDestinations.where(_matches).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: kGradDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331A1F36),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kTripPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF2ECC71),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Gợi ý thời tiết',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kTripPrimary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Live',
                    style: TextStyle(
                      color: Color(0xFF2ECC71),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm theo tỉnh, thành phố...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingDestinations)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: kTripPrimary),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            )
          else if (filteredDestinations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Không tìm thấy tỉnh nào.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredDestinations.length,
                itemBuilder: (context, index) {
                  final dest = filteredDestinations[index];
                  
                  if (!_weatherData.containsKey(dest.name) && !_loadingWeather.contains(dest.name)) {
                    _fetchWeatherFor(dest);
                  }
                  
                  final weather = _weatherData[dest.name];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dest.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (weather != null) ...[
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: weather.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(weather.icon, size: 16, color: weather.color),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${weather.temperature.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                weather.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ] else if (_loadingWeather.contains(dest.name))
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Text(
                            'Không có dữ liệu',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
