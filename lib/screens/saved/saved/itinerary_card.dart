// ignore_for_file: use_string_in_part_of_directives
part of saved_screen;

class _ItineraryCard extends StatefulWidget {
  const _ItineraryCard({
    required this.item,
    required this.onOpen,
    required this.onRename,
    required this.onClone,
    required this.onShare,
    required this.onExportPdf,
    required this.onRemove,
  });

  final SavedItineraryItem item;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onClone;
  final VoidCallback onShare;
  final VoidCallback onExportPdf;
  final VoidCallback onRemove;

  @override
  State<_ItineraryCard> createState() => _ItineraryCardState();
}

class _ItineraryCardState extends State<_ItineraryCard> {
  var _scale = 1.0;
  var _hovered = false;

  String _getThumbnail(String title) {
    final t = title.toLowerCase();
    if (t.contains('phu') || t.contains('quoc')) {
      return 'https://images.unsplash.com/photo-1583212292454-1fe6229603b7?w=320';
    } else if (t.contains('ha noi')) {
      return 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=320';
    } else if (t.contains('da lat')) {
      return 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=320';
    } else if (t.contains('vung tau')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=320';
    }
    return 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=320';
  }

  String _getMainVehicle(Map<String, dynamic> itinerary) {
    final text = jsonEncode(itinerary).toLowerCase();
    if (text.contains('flight') || text.contains('bay')) return 'Flight';
    if (text.contains('bus')) return 'Bus';
    if (text.contains('motorbike')) return 'Motorbike';
    if (text.contains('train')) return 'Train';
    if (text.contains('car') || text.contains('taxi')) return 'Car';
    return 'Road trip';
  }

  int _getDestinationCount(Map<String, dynamic> itinerary) {
    final days = itinerary['days'];
    if (days is! List) return 0;
    var count = 0;
    for (final day in days) {
      if (day is Map) {
        final acts = day['activities'] ?? day['schedule'];
        if (acts is List) count += acts.length;
      }
    }
    return count;
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}y ago';
    if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}mo ago';
    if (difference.inDays > 0) return 'Updated ${difference.inDays}d ago';
    if (difference.inHours > 0) return 'Updated ${difference.inHours}h ago';
    if (difference.inMinutes > 0) return 'Updated ${difference.inMinutes}m ago';
    return 'Updated now';
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.item.itinerary['days'] is List
        ? (widget.item.itinerary['days'] as List).length
        : 0;
    final summary =
        '${widget.item.itinerary['summary'] ?? 'Open to review and fine tune this AI itinerary.'}';
    final vehicle = _getMainVehicle(widget.item.itinerary);
    final places = _getDestinationCount(widget.item.itinerary);
    final saveTime = _timeAgo(widget.item.savedAt);
    final thumbnail = _getThumbnail(widget.item.title);
    final aiScore = 88 + (days.clamp(0, 4) * 2);
    final budget = days > 0 ? '~${(days * 1.1).toStringAsFixed(1)}tr' : '~2.5tr';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.985),
          onTapUp: (_) {
            setState(() => _scale = 1.0);
            widget.onOpen();
          },
          onTapCancel: () => setState(() => _scale = 1.0),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hovered ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _hovered ? 0.055 : 0.025),
                    blurRadius: _hovered ? 22 : 16,
                    offset: Offset(0, _hovered ? 10 : 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: Stack(
                        children: [
                          NetworkImageCard(
                            imageUrl: thumbnail,
                            height: 112,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _MetaTag(
                              label: 'AI $aiScore',
                              color: const Color(0xFFECFDF5),
                              textColor: const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFFE11D48)),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 7,
                            runSpacing: 6,
                            children: [
                              const _MetaTag(label: 'AI generated', color: Color(0xFFF0FDF4), textColor: Color(0xFF047857)),
                              if (days > 0) _MetaTag(label: '$days days', color: const Color(0xFFF3F4F6)),
                              if (places > 0)
                                _MetaTag(label: '$places stops', color: const Color(0xFFECFDF5), textColor: const Color(0xFF047857)),
                              _MetaTag(label: vehicle, color: const Color(0xFFEFF6FF), textColor: const Color(0xFF1D4ED8)),
                              _MetaTag(label: budget, color: const Color(0xFFFFF7ED), textColor: const Color(0xFFC2410C)),
                              const _MetaTag(label: 'Good weather', color: Color(0xFFFFFBEB), textColor: Color(0xFFB45309)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.update_rounded, size: 13, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 4),
                              Text(
                                saveTime,
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF9CA3AF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (val) {
                        switch (val) {
                          case 'open':
                            widget.onOpen();
                          case 'rename':
                            widget.onRename();
                          case 'clone':
                            widget.onClone();
                          case 'share':
                            widget.onShare();
                          case 'pdf':
                            widget.onExportPdf();
                          case 'delete':
                            widget.onRemove();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'open', child: Text('Open')),
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'clone', child: Text('Clone')),
                        PopupMenuItem(value: 'share', child: Text('Share')),
                        PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({
    required this.label,
    required this.color,
    this.textColor = const Color(0xFF4B5563),
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor),
      ),
    );
  }
}
