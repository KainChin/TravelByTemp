// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class _BottomSaveBar extends StatelessWidget {
  const _BottomSaveBar({
    required this.isSaved,
    required this.isSaving,
    required this.onSave,
    required this.onEdit,
    required this.onChat,
  });

  final bool isSaved;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SaveButton(
                    isSaved: isSaved,
                    isSaving: isSaving,
                    onTap: isSaving ? null : onSave,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Sửa',
                    color: const Color(0xFFF59E0B),
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.auto_awesome_outlined,
                    label: 'AI',
                    color: const Color(0xFF8B5CF6),
                    onTap: onChat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDock extends StatelessWidget implements PreferredSizeWidget {
  const _MiniDock({required this.onHome, required this.onSaved, required this.onProfile});

  final VoidCallback onHome;
  final VoidCallback onSaved;
  final VoidCallback onProfile;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF15221D),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _MiniDockItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: 'Khám phá',
              color: const Color(0xFF34D399),
              onTap: onHome,
            ),
            _MiniDockItem(
              icon: Icons.favorite_outline,
              activeIcon: Icons.favorite,
              label: 'Đã lưu',
              color: const Color(0xFFFB7185),
              onTap: onSaved,
            ),
            _MiniDockItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Tài khoản',
              color: const Color(0xFF60A5FA),
              onTap: onProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDockItem extends StatelessWidget {
  const _MiniDockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaved,
    required this.isSaving,
    required this.onTap,
  });

  final bool isSaved;
  final bool isSaving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final savedColor = const Color(0xFF10B981);
    final unsavedColor = _TripItineraryResultScreenState._primary;
    final color = isSaved ? savedColor : unsavedColor;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 50,
          child: Center(
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSaved ? 'Đã lưu hành trình' : 'Lưu hành trình',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 50,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.errorText,
    this.keyboardType,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _TripItineraryResultScreenState._bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: errorText != null ? Colors.red.shade400 : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: errorText != null ? Colors.red.shade400 : _TripItineraryResultScreenState._primary,
            width: 1.5,
          ),
        ),
        errorText: errorText,
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _TripItineraryResultScreenState._line),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF7FAF8), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, color: _TripItineraryResultScreenState._muted),
          const SizedBox(height: 8),
          const Text('Chưa có hoạt động cho ngày này', style: TextStyle(fontWeight: FontWeight.w900)),
          if (onAdd != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Thêm hoạt động', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}




class _AddMenuTile extends StatelessWidget {
  const _AddMenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15221D),
                  ),
                ),
              ),
              Icon(Icons.add_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityValidationErrors {
  const _ActivityValidationErrors({
    this.time,
    this.destination,
    this.cost,
    this.duration,
    this.timeConflict,
  });

  final String? time;
  final String? destination;
  final String? cost;
  final String? duration;
  final String? timeConflict;

  bool get hasError =>
      time != null ||
      destination != null ||
      cost != null ||
      duration != null ||
      timeConflict != null;

  String? get first => time ?? destination ?? cost ?? duration ?? timeConflict;
}

_ActivityValidationErrors _validateActivityFields({
  required String time,
  required String destination,
  required String costText,
  required String durationText,
  required List<Map<String, dynamic>> existingActivities,
  int? editingIndex,
}) {
  final timeRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  final timeError = timeRegex.hasMatch(time.trim())
      ? null
      : ItineraryStrings.errorTimeFormat;

  final destError = destination.trim().isEmpty
      ? ItineraryStrings.errorDestinationEmpty
      : null;

  String? costError;
  final rawCost = costText.replaceAll(RegExp(r'[^0-9]'), '');
  final costNum = num.tryParse(rawCost);
  if (costNum == null) {
    costError = ItineraryStrings.errorCostNotNumber;
  } else if (costNum < 0) {
    costError = ItineraryStrings.errorCostNegative;
  }

  String? durationError;
  final durTrim = durationText.trim();
  if (durTrim.isNotEmpty) {
    final durDigits = durTrim.replaceAll(RegExp(r'[^0-9]'), '');
    final durNum = num.tryParse(durDigits.isEmpty ? durTrim : durDigits);
    if (durNum == null || durNum <= 0 || durNum != durNum.roundToDouble()) {
      durationError = ItineraryStrings.errorDurationNotPositiveInt;
    }
  }

  String? timeConflictError;
  if (timeError == null) {
    final newStart = _parseTimeToMinutes(time.trim());
    if (newStart != null) {
      final newDuration = _parseDurationToMinutes(durationText);
      final newEnd = newDuration != null ? newStart + newDuration : newStart;
      Map<String, dynamic>? overlap;
      for (final entry in existingActivities.asMap().entries) {
        if (entry.key == editingIndex) continue;
        final other = entry.value;
        final otherStart = _parseTimeToMinutes('${other['time'] ?? ''}'.trim());
        if (otherStart == null) continue;
        final otherDuration = _parseDurationToMinutes('${other['duration'] ?? other['durationMinutes'] ?? ''}');
        final otherEnd = otherDuration != null ? otherStart + otherDuration : otherStart;
        final isExactMatch = otherStart == newStart;
        final isOverlap = newStart < otherEnd && otherStart < newEnd;
        if (isExactMatch || isOverlap) {
          overlap = other;
          break;
        }
      }
      if (overlap != null) {
        timeConflictError = ItineraryStrings.errorTimeConflict(
          _titleFromActivity(overlap),
          '${overlap['time'] ?? ''}',
        );
      }
    }
  }

  return _ActivityValidationErrors(
    time: timeError,
    destination: destError,
    cost: costError,
    duration: durationError,
    timeConflict: timeConflictError,
  );
}

int? _parseTimeToMinutes(String text) {
  final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(text.trim());
  if (match == null) return null;
  return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
}

int? _parseDurationToMinutes(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 60;
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  final value = int.tryParse(digits.isEmpty ? trimmed : digits);
  if (value == null || value <= 0) return null;
  return value;
}

/// Parse duration string ("60", "90 phút", "1h30p", ...) → số phút.
/// Trả về null nếu không parse được.
int? _durationToMinutes(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  // Thử trước dạng số đơn (phút).
  final asInt = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
  if (asInt != null && asInt > 0 && text == asInt.toString()) return asInt;
  // Dạng "1h30p" / "1 giờ 30 phút".
  final hourMatch = RegExp(r'(\d+)\s*(?:h|giờ|gio)').firstMatch(text);
  final minMatch = RegExp(r'(\d+)\s*(?:p|phút|phut)').firstMatch(text);
  if (hourMatch == null && minMatch == null) return asInt;
  var minutes = 0;
  if (hourMatch != null) minutes += int.parse(hourMatch.group(1)!) * 60;
  if (minMatch != null) minutes += int.parse(minMatch.group(1)!);
  return minutes > 0 ? minutes : asInt;
}

String _titleFromActivity(Map<String, dynamic> activity) {
  return '${activity['destination'] ?? activity['title'] ?? activity['name'] ?? ''}'.trim();
}




