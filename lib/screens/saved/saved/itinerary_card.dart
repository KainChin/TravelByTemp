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

  static const Set<String> _flightKeywords = {'flight', 'may bay', 'máy bay', 'bay'};
  static const Set<String> _trainKeywords = {'train', 'tau hoa', 'tàu hỏa'};
  static const Set<String> _busKeywords = {'bus', 'xe khach', 'xe khách', 'coach'};
  static const Set<String> _carKeywords = {'taxi', 'o to', 'ô tô', 'car'};
  static const Set<String> _motorbikeKeywords = {'motorbike', 'xe may', 'xe máy'};

  /// Picks the first activity whose category marks "transport" and returns a
  /// human label. Falls back to scanning the title for keywords.
  static String detectMainVehicle(Map<String, dynamic> itinerary, String title) {
    final days = itinerary['days'];
    if (days is List) {
      for (final day in days) {
        if (day is Map) {
          final activities = day['activities'] ?? day['schedule'];
          if (activities is List) {
            for (final a in activities) {
              if (a is Map) {
                final cat = (a['category'] ?? '').toString().toLowerCase();
                if (cat == 'di chuyển' ||
                    cat == 'di chuyen' ||
                    cat == 'flight' ||
                    cat == 'bus' ||
                    cat == 'train' ||
                    cat == 'car' ||
                    cat == 'motorbike' ||
                    cat == 'transport') {
                  return _modeLabel(cat);
                }
              }
            }
          }
        }
      }
    }
    return _vehicleFromText(title);
  }

  static String _modeLabel(String category) {
    switch (category) {
      case 'flight':
        return 'Máy bay';
      case 'train':
        return 'Tàu hỏa';
      case 'bus':
      case 'coach':
        return 'Xe khách';
      case 'car':
        return 'Ô tô';
      case 'motorbike':
        return 'Xe máy';
      default:
        return 'Đường bộ';
    }
  }

  static String _vehicleFromText(String text) {
    final lower = text.toLowerCase();
    if (_flightKeywords.any(lower.contains)) return 'Máy bay';
    if (_trainKeywords.any(lower.contains)) return 'Tàu hỏa';
    if (_busKeywords.any(lower.contains)) return 'Xe khách';
    if (_carKeywords.any(lower.contains)) return 'Ô tô';
    if (_motorbikeKeywords.any(lower.contains)) return 'Xe máy';
    return 'Đường bộ';
  }

  /// Sums the estimatedCost on every activity across all days. Falls back to
  /// `costBreakdown.total` when activity costs are absent (older payloads).
  static double computeBudgetVnd(Map<String, dynamic> itinerary) {
    var total = 0.0;
    final days = itinerary['days'];
    if (days is List) {
      for (final day in days) {
        if (day is Map) {
          final activities = day['activities'] ?? day['schedule'];
          if (activities is List) {
            for (final a in activities) {
              if (a is Map) {
                final cost = (a['estimatedCost'] ??
                        a['cost'] ??
                        a['price'])
                    as num?;
                if (cost != null) total += cost.toDouble();
              }
            }
          }
        }
      }
    }
    if (total <= 0) {
      final breakdown = itinerary['costBreakdown'];
      if (breakdown is Map) {
        final t = breakdown['total'];
        if (t is num) total = t.toDouble();
      }
    }
    return total;
  }

  static String formatBudgetVnd(double vnd) {
    if (vnd <= 0) return '—';
    if (vnd >= 1000000000) return '${(vnd / 1000000000).toStringAsFixed(1)}tỷ';
    if (vnd >= 1000000) return '${(vnd / 1000000).toStringAsFixed(1)}tr';
    if (vnd >= 1000) return '${(vnd / 1000).toStringAsFixed(0)}k';
    return '${vnd.round()}đ';
  }

  /// Mirrors TripItineraryResultScreen._aiScore so the saved card stays
  /// consistent with the in-app header.
  static double computeAiScore(Map<String, dynamic> itinerary) {
    var score = 8.2;
    final daysRaw = itinerary['days'];
    if (daysRaw is List && daysRaw.isNotEmpty) {
      final totalActs = daysRaw.fold<int>(0, (sum, day) {
        if (day is Map) {
          final acts = day['activities'] ?? day['schedule'];
          return sum + (acts is List ? acts.length : 0);
        }
        return sum;
      });
      if (totalActs >= daysRaw.length * 5) score += 0.4;
      final hasTransport = daysRaw.any((day) {
        if (day is! Map) return false;
        final acts = day['activities'] ?? day['schedule'];
        if (acts is! List) return false;
        return acts.any((a) {
          if (a is! Map) return false;
          final cat = a['category']?.toString().toLowerCase() ?? '';
          return cat == 'di chuyển' || cat == 'di chuyen';
        });
      });
      if (hasTransport) score += 0.2;
    }
    if (computeBudgetVnd(itinerary) > 0) score += 0.3;
    return score.clamp(7.5, 9.6).toDouble();
  }

  /// Pulls the first place name from activities and uses DestinationImages
  /// to resolve an Unsplash cover. Falls back to a generic photo when the
  /// itinerary has no destinations.
  static String _coverFor(Map<String, dynamic> itinerary, String title) {
    final names = <String>[];
    final days = itinerary['days'];
    if (days is List) {
      for (final day in days) {
        if (day is Map) {
          final acts = day['activities'] ?? day['schedule'];
          if (acts is List) {
            for (final a in acts) {
              if (a is Map) {
                final n = (a['destination'] ?? a['placeName'] ?? '')
                    .toString()
                    .trim();
                if (n.isNotEmpty && n.toLowerCase() != 'null') {
                  names.add(n);
                  if (names.length >= 3) break;
                }
              }
            }
            if (names.length >= 3) break;
          }
        }
      }
    }
    if (names.isEmpty) names.add(title);
    return DestinationImages.urlFor(names.first);
  }

  static int dayCountOf(Map<String, dynamic> itinerary) =>
      itinerary['days'] is List ? (itinerary['days'] as List).length : 0;

  static int activityCountOf(Map<String, dynamic> itinerary) {
    final days = itinerary['days'];
    if (days is! List) return 0;
    return days.fold<int>(0, (sum, day) {
      if (day is Map) {
        final acts = day['activities'] ?? day['schedule'];
        return sum + (acts is List ? acts.length : 0);
      }
      return sum;
    });
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) return '${(difference.inDays / 365).floor()} năm trước';
    if (difference.inDays > 30) return '${(difference.inDays / 30).floor()} tháng trước';
    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours} giờ trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes} phút trước';
    return 'Vừa lưu';
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.item.itinerary;
    final days = dayCountOf(itinerary);
    final summary = (itinerary['summary'] ??
            'Nhấn để mở và xem chi tiết hành trình AI của bạn.')
        .toString();
    final vehicle = detectMainVehicle(itinerary, widget.item.title);
    final acts = activityCountOf(itinerary);
    final saveTime = _timeAgo(widget.item.savedAt);
    final thumbnail = _coverFor(itinerary, widget.item.title);
    final aiScore = computeAiScore(itinerary);
    final budget = formatBudgetVnd(computeBudgetVnd(itinerary));
    final feasibility = itinerary['feasibility'];
    final feasibilityLabel = feasibility is Map
        ? (feasibility['status'] ?? feasibility['message'])?.toString()
        : null;

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
                              label: 'AI ${aiScore.toStringAsFixed(1)}',
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
                              const _MetaTag(
                                label: 'AI tạo',
                                color: Color(0xFFF0FDF4),
                                textColor: Color(0xFF047857),
                              ),
                              if (days > 0)
                                _MetaTag(label: '$days ngày', color: const Color(0xFFF3F4F6)),
                              if (acts > 0)
                                _MetaTag(
                                  label: '$acts hoạt động',
                                  color: const Color(0xFFECFDF5),
                                  textColor: const Color(0xFF047857),
                                ),
                              _MetaTag(
                                label: vehicle,
                                color: const Color(0xFFEFF6FF),
                                textColor: const Color(0xFF1D4ED8),
                              ),
                              _MetaTag(
                                label: budget,
                                color: const Color(0xFFFFF7ED),
                                textColor: const Color(0xFFC2410C),
                              ),
                              if (feasibilityLabel != null && feasibilityLabel.isNotEmpty)
                                _MetaTag(
                                  label: feasibilityLabel,
                                  color: const Color(0xFFEFF6FF),
                                  textColor: const Color(0xFF1D4ED8),
                                ),
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
                        PopupMenuItem(value: 'open', child: Text('Mở')),
                        PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                        PopupMenuItem(value: 'clone', child: Text('Sao chép')),
                        PopupMenuItem(value: 'share', child: Text('Chia sẻ')),
                        PopupMenuItem(value: 'pdf', child: Text('Xuất văn bản')),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Xóa',
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
