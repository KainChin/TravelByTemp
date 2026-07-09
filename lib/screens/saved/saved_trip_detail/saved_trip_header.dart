// ignore_for_file: use_string_in_part_of_directives
part of saved_trip_detail_screen;

// ─── Hero SliverAppBar ────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.totalActivities,
    required this.allActivities,
    required this.dayCount,
    required this.isDirty,
  });
  final String title;
  final int totalActivities;
  final List<Map<String, dynamic>> allActivities;
  final int dayCount;
  final bool isDirty;

  /// Tổng chi phí của toàn trip (không phải của ngày đang chọn).
  int get _totalCost => allActivities.fold(0, (s, a) => s + _parseCost(a));

  String get _dayLabel => dayCount <= 1 ? '1 ngày' : '$dayCount ngày';

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF16A34A),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      // Title hiển thị ở collapsed (pinned) state. Khi expanded bị hero che
      // bởi layer khác, nên ta chỉ set title ngắn gọn.
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      leading: Navigator.of(context).canPop()
          ? IconButton(
              tooltip: 'Quay lại',
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: [
        if (isDirty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 6),
                Text('Đang lưu…',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ),
          )
        else
          IconButton(
            tooltip: 'Chia sẻ',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.ios_share_rounded, size: 16, color: Colors.white),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: title));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép tên hành trình.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        // Tắt title của FlexibleSpaceBar – ta dùng title riêng ở AppBar cho
        // collapsed state, tránh title đúp khi expanded.
        titlePadding: EdgeInsets.zero,
        background: Stack(fit: StackFit.expand, children: [
          // Background image
          SafeNetworkImage(
            url: 'https://images.unsplash.com/photo-1540202404-d0c7fe46a087?auto=format&fit=crop&w=1400&q=80',
            fit: BoxFit.cover,
            source: 'saved trip detail hero',
            fallback: Container(decoration: const BoxDecoration(gradient: _gradHero)),
          ),
          // Tint gradient xanh lá
          const DecoratedBox(decoration: BoxDecoration(gradient: _gradHero)),
          // Subtle bottom shadow for text readability
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glass badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.bookmark_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Hành trình đã lưu',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        )),
                    const SizedBox(height: 14),
                    // Stats row thay thế cũ
                    Row(children: [
                      Expanded(child: _HeroStat(icon: Icons.calendar_today_rounded, label: _dayLabel)),
                      const SizedBox(width: 8),
                      Expanded(child: _HeroStat(icon: Icons.event_note_rounded, label: '$totalActivities hoạt động')),
                      const SizedBox(width: 8),
                      Expanded(child: _HeroStat(icon: Icons.payments_rounded, label: _fmtAmount(_totalCost))),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
// Style mới: pill button trắng + icon gradient + label, đồng bộ với saved_header
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
    required this.onRename,
    required this.onClone,
  });
  final VoidCallback onEdit, onShare, onDelete, onRename, onClone;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _PillAction(
        label: 'Sửa',
        icon: Icons.edit_outlined,
        gradient: _gradPrimary,
        onTap: onEdit,
      ),
      _PillAction(
        label: 'Đổi tên',
        icon: Icons.drive_file_rename_outline_rounded,
        gradient: _gradTeal,
        onTap: onRename,
      ),
      _PillAction(
        label: 'Sao chép',
        icon: Icons.content_copy_rounded,
        gradient: _gradBlue,
        onTap: onClone,
      ),
      _PillAction(
        label: 'Chia sẻ',
        icon: Icons.ios_share_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: onShare,
      ),
      _PillAction(
        label: 'Xóa',
        icon: Icons.delete_outline_rounded,
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: onDelete,
      ),
    ];
    // Bố cục: 2 hàng × 3 cột cho tối đa 6 nút. Với 5 nút sẽ là 2 hàng 3-2.
    const columns = 3;
    final rows = <List<_PillAction>>[];
    for (var i = 0; i < buttons.length; i += columns) {
      rows.add(buttons.sublist(
        i,
        i + columns > buttons.length ? buttons.length : i + columns,
      ));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (var c = 0; c < rows[r].length; c++) ...[
                  if (c > 0) const SizedBox(width: 8),
                  Expanded(child: rows[r][c]),
                ],
                // Nếu hàng cuối không đủ cột thì thêm Spacer để giãn đều
                for (var c = rows[r].length; c < columns; c++) ...[
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = gradient.colors.first;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withValues(alpha: 0.1), c.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
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
