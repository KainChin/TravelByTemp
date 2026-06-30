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
    required this.onTap,
  });

  final TransportOption option;
  final bool selected;
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


