/// Centralized asset path configuration for the Messages (AI Chat) screen.
///
/// Replace each constant below with the real asset path once you add the
/// images to your `assets/` folder and register them in `pubspec.yaml`.
/// Every widget in `screens/messages/` reads images through this class —
/// never hardcode an asset path inside a widget.
class MessageAssets {
  MessageAssets._();

  /// Avatar shown in the AI info card, chat bubbles and typing indicator.
  static const String aiAvatar = 'assets/images/travel_bag.jpg';

  /// Background image behind the "Messages" header (mountains / lake).
  static const String headerBackground = 'assets/images/banner_bac.png';

  /// Thumbnail used for the "Đà Lạt" destination row in the itinerary card.
  static const String dalatThumbnail = 'assets/images/danang.png';

  /// Thumbnail used for the "Nha Trang" destination row in the itinerary card.
  static const String nhatrangThumbnail = 'assets/images/phuquoc.jpg';
}
