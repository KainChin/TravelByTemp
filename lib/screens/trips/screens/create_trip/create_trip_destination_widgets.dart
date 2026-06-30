// ignore_for_file: use_string_in_part_of_directives

part of create_trip_screen;

class _EmptyDestinationAnswer extends StatelessWidget {
  const _EmptyDestinationAnswer({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _AiInterviewViewState._line),
        ),
        child: const Row(
          children: [
            Icon(Icons.travel_explore, color: _AiInterviewViewState._primary, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chọn điểm đến hoặc thêm nhiều chặng để tối ưu tuyến đường.',
                style: TextStyle(
                  color: _AiInterviewViewState._ink,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationAnswerCard extends StatelessWidget {
  const _DestinationAnswerCard({
    required this.index,
    required this.item,
    required this.error,
    required this.onPickDate,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onRemove,
  });

  final int index;
  final SelectedDestination item;
  final String? error;
  final VoidCallback onPickDate;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: error == null ? _AiInterviewViewState._line : const Color(0xFFFFC9B8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _AiInterviewViewState._primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _AiInterviewViewState._primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AiInterviewViewState._ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.destination.region,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AiInterviewViewState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DestinationDateStrip(
            start: item.startDate,
            end: item.endDate,
            onPickRange: onPickDate,
            onPickStart: onPickStartDate,
            onPickEnd: onPickEndDate,
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: _AiInterviewViewState._accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: _AiInterviewViewState._accent,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DestinationDateStrip extends StatelessWidget {
  const _DestinationDateStrip({
    required this.start,
    required this.end,
    required this.onPickRange,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime? start;
  final DateTime? end;
  final VoidCallback onPickRange;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AiInterviewViewState._line),
      ),
      child: Row(
        children: [
          _DateMiniCard(
            icon: Icons.login_rounded,
            label: 'Ngày đến',
            value: start == null ? 'Chọn ngày' : _formatDate(start!),
            onTap: onPickStart,
          ),
          Container(
            width: 24,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: _AiInterviewViewState._muted,
            ),
          ),
          _DateMiniCard(
            icon: Icons.logout_rounded,
            label: 'Ngày rời',
            value: end == null ? 'Chọn ngày' : _formatDate(end!),
            onTap: onPickEnd,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onPickRange,
            tooltip: 'Chọn khoảng ngày',
            icon: const Icon(Icons.edit_calendar_outlined),
            color: _AiInterviewViewState._primary,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}


class _DateMiniCard extends StatelessWidget {
  const _DateMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _AiInterviewViewState._line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: _AiInterviewViewState._primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AiInterviewViewState._muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AiInterviewViewState._ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



