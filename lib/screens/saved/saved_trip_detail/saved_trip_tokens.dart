// ignore_for_file: use_string_in_part_of_directives
part of saved_trip_detail_screen;

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _bg          = Color(0xFFF8F9FA);
const _ink         = Color(0xFF1A1F36);
const _muted       = Color(0xFF6B7280);
const _line        = Color(0xFFE5E7EB);
const _indigo      = Color(0xFF4338CA);
const _indigoLight = Color(0xFF818CF8);
const _teal        = Color(0xFF0D9488);
const _tealLight   = Color(0xFF5EEAD4);
const _coral       = Color(0xFFF97316);
const _green       = Color(0xFF10B981);

const _gradIndigo = LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _gradTeal   = LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0891B2)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _gradBlue   = LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _gradRed    = LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _gradHero   = LinearGradient(colors: [Color(0xFF0F172A), Color(0x881E293B), Color(0x00000000)], begin: Alignment.bottomCenter, end: Alignment.topCenter);

// ─── Category helpers (used by State & part files) ────────────────────────────
int _parseCost(Map<String, dynamic> a) {
  final v = a['estimatedCost'] ?? a['cost'] ?? 0;
  if (v is num) return v.round();
  return int.tryParse('$v'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

String _parseCategory(Map<String, dynamic> a) {
  final raw = '${a['category'] ?? a['type'] ?? ''}'.toLowerCase();
  final norm = raw.replaceAll('đ', 'd').replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a').replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  if (norm == 'an uong' || norm.contains('food') || norm.contains('restaurant') || norm.contains('cafe')) return 'ăn uống';
  if (norm.contains('hotel') || norm.contains('khach') || norm.contains('accommodation')) return 'khách sạn';
  if (norm.contains('transport') || norm.contains('di chuyen')) return 'di chuyển';
  return 'tham quan';
}

String _fmtAmount(int v) {
  if (v <= 0) return '0đ';
  return '${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}

IconData _iconFor(String key) => switch (key) {
  'transport'     => Icons.directions_bus_outlined,
  'accommodation' => Icons.hotel_outlined,
  'food'          => Icons.restaurant_outlined,
  _               => Icons.local_activity_outlined,
};

String _labelFor(String key) => switch (key) {
  'transport'     => 'Di chuyển',
  'accommodation' => 'Lưu trú',
  'food'          => 'Ăn uống',
  _               => 'Vé & Hoạt động',
};

Color _colorFor(String key) => switch (key) {
  'transport'     => const Color(0xFF0EA5E9),
  'accommodation' => const Color(0xFFF472B6),
  'food'          => const Color(0xFF4ADE80),
  _               => const Color(0xFFA78BFA),
};
