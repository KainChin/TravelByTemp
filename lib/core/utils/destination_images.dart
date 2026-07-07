import 'package:flutter/foundation.dart';

/// Look up a destination image URL.
///
/// Tries a small static map keyed by Vietnamese destination slug or name.
/// Returns `null` when no match is found so callers can fall back to a
/// gradient placeholder.
@immutable
class DestinationImages {
  const DestinationImages._();

  static const Map<String, String> _queries = {
    'hue': 'hue-citadel',
    'da-nang': 'da-nang,dragon-bridge',
    'da nang': 'da-nang,dragon-bridge',
    'quy-nhon': 'quy-nhon,beach',
    'quy nhon': 'quy-nhon,beach',
    'phong-nha': 'phong-nha,cave',
    'phong nha': 'phong-nha,cave',
    'ha-noi': 'hanoi,old-quarter',
    'ha noi': 'hanoi,old-quarter',
    'vinh-ha-long': 'ha-long-bay',
    'ha-long': 'ha-long-bay',
    'ha long': 'ha-long-bay',
    'sapa': 'sapa,rice-terrace',
    'ninh-binh': 'ninh-binh,trang-an',
    'ninh binh': 'ninh-binh,trang-an',
    'mu-cang-chai': 'mu-cang-chai,rice-terrace',
    'mu cang chai': 'mu-cang-chai,rice-terrace',
    'phu-quoc': 'phu-quoc,beach',
    'phu quoc': 'phu-quoc,beach',
    'con-dao': 'con-dao,island',
    'con dao': 'con-dao,island',
    'vung-tau': 'vung-tau,beach',
    'vung tau': 'vung-tau,beach',
    'mui-ne': 'mui-ne,sand-dunes',
    'mui ne': 'mui-ne,sand-dunes',
    'da-lat': 'da-lat,pine-forest',
    'da lat': 'da-lat,pine-forest',
    'can-tho': 'can-tho,floating-market',
    'can tho': 'can-tho,floating-market',
    'chau-doc': 'chau-doc,nui-sam',
    'chau doc': 'chau-doc,nui-sam',
    'my-tho': 'my-tho,mekong-river',
    'my tho': 'my-tho,mekong-river',
    'ha-tien': 'ha-tien,beach',
    'ha tien': 'ha-tien,beach',
    'ben-tre': 'ben-tre,coconut-river',
    'ben tre': 'ben-tre,coconut-river',
    'hoi-an': 'hoi-an,lantern',
    'hoi an': 'hoi-an,lantern',
  };

  static const Map<String, String> _images = {
    'hoi-an,lantern': 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=1200&q=80',
    'hue-citadel': 'https://images.unsplash.com/photo-1555921015-5532091f6026?w=1200&q=80',
    'da-nang,dragon-bridge': 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=1200&q=80',
    'quy-nhon,beach': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=80',
    'phong-nha,cave': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=1200&q=80',
    'hanoi,old-quarter': 'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?w=1200&q=80',
    'ha-long-bay': 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=1200&q=80',
    'sapa,rice-terrace': 'https://images.unsplash.com/photo-1508193638397-1c4234db14d8?w=1200&q=80',
    'ninh-binh,trang-an': 'https://images.unsplash.com/photo-1540611025311-01df3cef54b5?w=1200&q=80',
    'mu-cang-chai,rice-terrace': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1200&q=80',
    'phu-quoc,beach': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=1200&q=80',
    'con-dao,island': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=1200&q=80',
    'vung-tau,beach': 'https://images.unsplash.com/photo-1526481280693-3bfa7568e0f3?w=1200&q=80',
    'mui-ne,sand-dunes': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=80',
    'da-lat,pine-forest': 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200&q=80',
    'can-tho,floating-market': 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=1200&q=80',
    'chau-doc,nui-sam': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&q=80',
    'my-tho,mekong-river': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=1200&q=80',
    'ha-tien,beach': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=1200&q=80',
    'ben-tre,coconut-river': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=1200&q=80',
  };

  static const String _defaultImage =
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&q=80';

  /// Returns an Unsplash URL whose look matches [destinationName], or
  /// [genericFallback] (default generic landscape) when nothing matches.
  static String urlFor(String destinationName,
      {String? genericFallback}) {
    final fallback = genericFallback ?? _defaultImage;
    final key = destinationName.toLowerCase().trim();
    if (key.isEmpty) return fallback;
    for (final entry in _queries.entries) {
      if (key.contains(entry.key)) {
        return _images[entry.value] ?? fallback;
      }
    }
    return fallback;
  }
}
