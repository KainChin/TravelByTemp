import 'dart:async';

import 'package:assignment/services/api_client.dart';

import '../models/destination_model.dart';
import '../models/region_model.dart';

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

  static String _sourceImage(String query) {
    return _staticImages[query] ??
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600';
  }

  static const Map<String, String> _staticImages = {
    'hoi-an,lantern': 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=600',
    'hue-citadel': 'https://images.unsplash.com/photo-1555921015-5532091f6026?w=600',
    'da-nang,dragon-bridge': 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=600',
    'quy-nhon,beach': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
    'phong-nha,cave': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600',
    'hanoi,old-quarter': 'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?w=600',
    'ha-long-bay': 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=600',
    'sapa,rice-terrace': 'https://images.unsplash.com/photo-1508193638397-1c4234db14d8?w=600',
    'ninh-binh,trang-an': 'https://images.unsplash.com/photo-1540611025311-01df3cef54b5?w=600',
    'mu-cang-chai,rice-terrace': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
    'phu-quoc,beach': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
    'con-dao,island': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
    'vung-tau,beach': 'https://images.unsplash.com/photo-1526481280693-3bfa7568e0f3?w=600',
    'mui-ne,sand-dunes': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
    'da-lat,pine-forest': 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=600',
    'can-tho,floating-market': 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=600',
    'chau-doc,nui-sam': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600',
    'my-tho,mekong-river': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
    'ha-tien,beach': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
    'ben-tre,coconut-river': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=600',
  };

  static final Map<RegionType, List<DestinationModel>> _fakeData = {
    RegionType.central: [
      DestinationModel(id: 'd1', name: 'Hội An', province: 'Quảng Nam', imageUrl: _sourceImage('hoi-an,lantern'), rating: 4.9),
      DestinationModel(id: 'd2', name: 'Huế', province: 'Thừa Thiên Huế', imageUrl: _sourceImage('hue-citadel'), rating: 4.7),
      DestinationModel(id: 'd3', name: 'Đà Nẵng', province: 'Đà Nẵng', imageUrl: _sourceImage('da-nang,dragon-bridge'), rating: 4.8),
      DestinationModel(id: 'd4', name: 'Quy Nhơn', province: 'Bình Định', imageUrl: _sourceImage('quy-nhon,beach'), rating: 4.6),
      DestinationModel(id: 'd5', name: 'Phong Nha', province: 'Quảng Bình', imageUrl: _sourceImage('phong-nha,cave'), rating: 4.8),
    ],
    RegionType.north: [
      DestinationModel(id: 'd6', name: 'Hà Nội', province: 'Hà Nội', imageUrl: _sourceImage('hanoi,old-quarter'), rating: 4.8),
      DestinationModel(id: 'd7', name: 'Hạ Long', province: 'Quảng Ninh', imageUrl: _sourceImage('ha-long-bay'), rating: 4.9),
      DestinationModel(id: 'd8', name: 'Sapa', province: 'Lào Cai', imageUrl: _sourceImage('sapa,rice-terrace'), rating: 4.7),
      DestinationModel(id: 'd9', name: 'Ninh Bình', province: 'Ninh Bình', imageUrl: _sourceImage('ninh-binh,trang-an'), rating: 4.6),
      DestinationModel(id: 'd10', name: 'Mù Cang Chải', province: 'Yên Bái', imageUrl: _sourceImage('mu-cang-chai,rice-terrace'), rating: 4.8),
    ],
    RegionType.south: [
      DestinationModel(id: 'd11', name: 'Phú Quốc', province: 'Kiên Giang', imageUrl: _sourceImage('phu-quoc,beach'), rating: 4.9),
      DestinationModel(id: 'd12', name: 'Côn Đảo', province: 'Bà Rịa - Vũng Tàu', imageUrl: _sourceImage('con-dao,island'), rating: 4.8),
      DestinationModel(id: 'd13', name: 'Vũng Tàu', province: 'Bà Rịa - Vũng Tàu', imageUrl: _sourceImage('vung-tau,beach'), rating: 4.5),
      DestinationModel(id: 'd14', name: 'Mũi Né', province: 'Bình Thuận', imageUrl: _sourceImage('mui-ne,sand-dunes'), rating: 4.6),
      DestinationModel(id: 'd15', name: 'Đà Lạt', province: 'Lâm Đồng', imageUrl: _sourceImage('da-lat,pine-forest'), rating: 4.8),
    ],
    RegionType.west: [
      DestinationModel(id: 'd16', name: 'Cần Thơ', province: 'Cần Thơ', imageUrl: _sourceImage('can-tho,floating-market'), rating: 4.6),
      DestinationModel(id: 'd17', name: 'Châu Đốc', province: 'An Giang', imageUrl: _sourceImage('chau-doc,nui-sam'), rating: 4.5),
      DestinationModel(id: 'd18', name: 'Mỹ Tho', province: 'Tiền Giang', imageUrl: _sourceImage('my-tho,mekong-river'), rating: 4.4),
      DestinationModel(id: 'd19', name: 'Hà Tiên', province: 'Kiên Giang', imageUrl: _sourceImage('ha-tien,beach'), rating: 4.7),
      DestinationModel(id: 'd20', name: 'Bến Tre', province: 'Bến Tre', imageUrl: _sourceImage('ben-tre,coconut-river'), rating: 4.5),
    ],
  };
}
