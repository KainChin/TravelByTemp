import 'dart:async';

import '../models/destination_model.dart';
import '../models/region_model.dart';
import 'package:assignment/services/api_client.dart';

class DestinationService {
  final ApiClient _api = ApiClient();

  Future<List<DestinationModel>> getDestinationsByRegion(RegionType region) async {
    try {
      final apiRegion = _apiRegion(region);
      if (apiRegion == null) return [];

      final destinations = await _api
          .fetchDestinations(region: apiRegion)
          .timeout(const Duration(seconds: 5));
      final apiItems = destinations
          .map(
            (item) => DestinationModel(
              id: item.id,
              name: item.name,
              province: item.location ?? item.tagline,
              imageUrl: item.imageUrl,
              rating: item.rating,
              isFavorite: item.isFavorite,
            ),
          )
          .toList();
      return _mergeWithFallback(region, apiItems);
    } catch (_) {
      return _fakeData[region] ?? [];
    }
  }

  static String? _apiRegion(RegionType region) => switch (region) {
        RegionType.north => 'North',
        RegionType.central => 'Central',
        RegionType.south => 'South',
        RegionType.west => 'West',
      };

  static List<DestinationModel> _mergeWithFallback(
    RegionType region,
    List<DestinationModel> apiItems,
  ) {
    final fallback = _fakeData[region] ?? const <DestinationModel>[];
    if (apiItems.length >= fallback.length) return apiItems;

    final names = apiItems.map((item) => item.name.toLowerCase()).toSet();
    final extras = fallback
        .where((item) => !names.contains(item.name.toLowerCase()))
        .take(fallback.length - apiItems.length);
    return [...apiItems, ...extras];
  }

  static final Map<RegionType, List<DestinationModel>> _fakeData = {
    RegionType.central: [
      const DestinationModel(id: 'd1', name: 'Hội An', province: 'Quảng Nam', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', rating: 4.9),
      const DestinationModel(id: 'd2', name: 'Huế', province: 'Thừa Thiên Huế', imageUrl: 'https://images.unsplash.com/photo-1555921015-5532091f6026?w=400', rating: 4.7),
      const DestinationModel(id: 'd3', name: 'Đà Nẵng', province: 'Đà Nẵng', imageUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=400', rating: 4.8),
      const DestinationModel(id: 'd4', name: 'Quy Nhơn', province: 'Bình Định', imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400', rating: 4.6),
      const DestinationModel(id: 'd5', name: 'Phong Nha', province: 'Quảng Bình', imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400', rating: 4.8),
    ],
    RegionType.north: [
      const DestinationModel(id: 'd6', name: 'Hà Nội', province: 'Hà Nội', imageUrl: 'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?w=400', rating: 4.8),
      const DestinationModel(id: 'd7', name: 'Hạ Long', province: 'Quảng Ninh', imageUrl: 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=400', rating: 4.9),
      const DestinationModel(id: 'd8', name: 'Sapa', province: 'Lào Cai', imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400', rating: 4.7),
      const DestinationModel(id: 'd9', name: 'Ninh Bình', province: 'Ninh Bình', imageUrl: 'https://images.unsplash.com/photo-1540611025311-01df3cef54b5?w=400', rating: 4.6),
      const DestinationModel(id: 'd10', name: 'Mù Cang Chải', province: 'Yên Bái', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', rating: 4.8),
    ],
    RegionType.south: [
      const DestinationModel(id: 'd11', name: 'Phú Quốc', province: 'Kiên Giang', imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400', rating: 4.9),
      const DestinationModel(id: 'd12', name: 'Côn Đảo', province: 'Bà Rịa - Vũng Tàu', imageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400', rating: 4.8),
      const DestinationModel(id: 'd13', name: 'Vũng Tàu', province: 'Bà Rịa - Vũng Tàu', imageUrl: 'https://images.unsplash.com/photo-1526481280693-3bfa7568e0f3?w=400', rating: 4.5),
      const DestinationModel(id: 'd14', name: 'Mũi Né', province: 'Bình Thuận', imageUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=400', rating: 4.6),
      const DestinationModel(id: 'd15', name: 'Đà Lạt', province: 'Lâm Đồng', imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400', rating: 4.8),
    ],
    RegionType.west: [
      const DestinationModel(id: 'd16', name: 'Cần Thơ', province: 'Cần Thơ', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', rating: 4.6),
      const DestinationModel(id: 'd17', name: 'Châu Đốc', province: 'An Giang', imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400', rating: 4.5),
      const DestinationModel(id: 'd18', name: 'Mỹ Tho', province: 'Tiền Giang', imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400', rating: 4.4),
      const DestinationModel(id: 'd19', name: 'Hà Tiên', province: 'Kiên Giang', imageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400', rating: 4.7),
      const DestinationModel(id: 'd20', name: 'Bến Tre', province: 'Bến Tre', imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400', rating: 4.5),
    ],
  };
}
