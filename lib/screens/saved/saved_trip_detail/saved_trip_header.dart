// ignore_for_file: use_string_in_part_of_directives
part of saved_trip_detail_screen;

// ─── Hero SliverAppBar ────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.title, required this.activities});
  final String title;
  final List<Map<String, dynamic>> activities;

  int get _totalCost => activities.fold(0, (s, a) => s + _parseCost(a));

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280, pinned: true, stretch: true,
      backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(fit: StackFit.expand, children: [
          SafeNetworkImage(
            url: 'https://images.unsplash.com/photo-1540202404-d0c7fe46a087?auto=format&fit=crop&w=1400&q=80',
            fit: BoxFit.cover,
            source: 'saved trip detail hero',
            fallback: Container(decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F4C81), Color(0xFF006B52), Color(0xFF0891B2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
            )),
          ),
          const DecoratedBox(decoration: BoxDecoration(gradient: _gradHero)),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            colors: [Colors.transparent, const Color(0xFF4338CA).withValues(alpha: 0.15)],
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
          ))),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                _GlassBadge(icon: Icons.bookmark_rounded, label: 'Đã lưu'),
                const SizedBox(height: 8),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900,
                        height: 1.15, shadows: [Shadow(color: Color(0x88000000), blurRadius: 12)])),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _StatBadge(icon: Icons.calendar_today_outlined, label: '1 ngày', color: _indigoLight),
                  _StatBadge(icon: Icons.explore_outlined, label: '${activities.length} hoạt động', color: _tealLight),
                  _StatBadge(icon: Icons.payments_outlined, label: _fmtAmount(_totalCost), color: const Color(0xFFFBBF24)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      ),
    ),
  );
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label, required this.color});
  final IconData icon; final String label; final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ),
    ),
  );
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onEdit, required this.onShare, required this.onDelete});
  final VoidCallback onEdit, onShare, onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(color: Color(0x0A1A1F36), blurRadius: 32, offset: Offset(0, 12)),
      ],
    ),
    child: Row(children: [
      _ActionBtn(label: 'Dùng & Sửa',    icon: Icons.copy_outlined,         gradient: _gradIndigo, onTap: onEdit),
      const SizedBox(width: 8),
      _ActionBtn(label: 'Chat AI & Bill', icon: Icons.camera_alt_outlined,   gradient: _gradTeal,   onTap: () {}),
      const SizedBox(width: 8),
      _ActionBtn(label: 'Chia sẻ',       icon: Icons.ios_share_rounded,     gradient: _gradBlue,   onTap: onShare),
      const SizedBox(width: 8),
      _ActionBtn(label: 'Xóa',           icon: Icons.delete_outline_rounded, gradient: _gradRed,    onTap: onDelete),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.icon, required this.gradient, required this.onTap});
  final String label; final IconData icon; final LinearGradient gradient; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = gradient.colors.first;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.withValues(alpha: 0.12), c.withValues(alpha: 0.06)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withValues(alpha: 0.2)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: c, fontSize: 9.5, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

// ─── Map Card ─────────────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  const _MapCard({required this.day});
  final Map<String, dynamic>? day;

  static const _daNang  = LatLng(16.0544, 108.2022);
  static const _phuQuoc = LatLng(10.2899, 103.9840);

  Marker _marker(LatLng pt, String lbl, Color c) => Marker(
    point: pt, width: 50, height: 50,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 8)]),
        child: Text(lbl, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
      ),
      Container(width: 2, height: 8, color: c),
    ]),
  );

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionLabel(icon: Icons.map_rounded, label: 'Bản đồ hành trình'),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(height: 200, child: FlutterMap(
          options: const MapOptions(initialCenter: LatLng(13.0, 106.0), initialZoom: 5.5),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.vietai.travel'),
            PolylineLayer(polylines: [
              Polyline(points: const [_daNang, _phuQuoc], color: _indigo, strokeWidth: 3.5,
                  pattern: StrokePattern.dashed(segments: [12, 6])),
            ]),
            MarkerLayer(markers: [_marker(_daNang, 'ĐN', _coral), _marker(_phuQuoc, 'PQ', _teal)]),
          ],
        )),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: _indigo.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.flight_takeoff_rounded, size: 15, color: _indigo),
          const SizedBox(width: 7),
          Text('Chuyến bay: Đà Nẵng → Phú Quốc (Ngày 1)',
              style: TextStyle(fontSize: 12, color: _indigo, fontWeight: FontWeight.w800)),
        ]),
      ),
    ]),
  );
}
