// ignore_for_file: use_string_in_part_of_directives

part of trip_route_analysis_screen;

class _TransportPickerSheet extends StatelessWidget {
  const _TransportPickerSheet({
    required this.leg,
    required this.options,
    required this.onSelected,
  });

  final RouteLeg leg;
  final List<TransportOption> options;
  final ValueChanged<TransportOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              leg.routeLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B1F1C),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chỉ các phương tiện khả thi mới có thể chọn.',
              style: TextStyle(color: Color(0xFF647067), fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = option.mode == leg.recommendedMode;
                  return _TransportOptionTile(
                    option: option,
                    selected: selected,
                    origin: leg.from,
                    destination: leg.to,
                    onTap: option.isAvailable ? () => onSelected(option) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportOptionTile extends StatelessWidget {
  const _TransportOptionTile({
    required this.option,
    required this.selected,
    required this.origin,
    required this.destination,
    this.onTap,
  });

  final TransportOption option;
  final bool selected;
  final Destination? origin;
  final Destination? destination;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = option.isAvailable;
    final foreground = enabled ? const Color(0xFF1B1F1C) : const Color(0xFF8A948D);
    final border = selected ? const Color(0xFF0B7D4B) : const Color(0xFFE2E8E4);
    final background = selected ? const Color(0xFFEAF5F0) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? background : const Color(0xFFF6F8F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFE0F4E9) : const Color(0xFFE9EEE9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _transportIcon(option.mode),
                color: enabled ? const Color(0xFF0B7D4B) : const Color(0xFF8A948D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transportLabel(option.mode),
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: Color(0xFF0B7D4B), size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatHours(option.durationHours)} • ${BudgetTier.formatCurrency(option.estimatedCostVnd)}',
                    style: TextStyle(
                      color: enabled ? const Color(0xFF0B7D4B) : const Color(0xFF8A948D),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.reason,
                    style: TextStyle(
                      color: enabled ? const Color(0xFF647067) : const Color(0xFF9AA39D),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  // Multi-leg breakdown (chỉ với máy bay / phà)
                  if (enabled &&
                      origin != null &&
                      (option.mode == TransportMode.flight ||
                          option.mode == TransportMode.ferry)) ...[
                    const SizedBox(height: 8),
                    _JourneyBreakdown(
                      mode: option.mode,
                      origin: origin!,
                      destination: destination,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini breakdown cho multi-leg journey (chỉ hiển thị với flight/ferry).
class _JourneyBreakdown extends StatelessWidget {
  const _JourneyBreakdown({
    required this.mode,
    required this.origin,
    required this.destination,
  });

  final TransportMode mode;
  final Destination origin;
  final Destination? destination;

  @override
  Widget build(BuildContext context) {
    final dest = destination;
    if (dest == null) return const SizedBox.shrink();
    final journey = buildMultiLegJourney(
      mode: mode, origin: origin, destination: dest,
    );
    if (journey == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCEEE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.alt_route, size: 12, color: Color(0xFF0B7D4B)),
            SizedBox(width: 4),
            Text(
              'Chi tiết từng chặng',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B7D4B),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          ...journey.legs.asMap().entries.map((entry) {
            final i = entry.key;
            final leg = entry.value;
            final subLabel = leg.subMode == TransitSubMode.na
                ? ''
                : ' (${leg.subMode.label})';
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F4E9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B7D4B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${leg.note ?? '${leg.fromLabel} → ${leg.toLabel}'}$subLabel',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1F1C),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            if (leg.distanceKm > 0)
                              '${leg.distanceKm.toStringAsFixed(0)} km',
                            leg.durationLabel,
                            if (leg.costVnd > 0) leg.costLabel,
                          ].where((s) => s.isNotEmpty).join(' • '),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF647067),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}


