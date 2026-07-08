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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _AiInterviewViewState._primarySoft.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _AiInterviewViewState._primary.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.travel_explore, color: _AiInterviewViewState._primary, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Chọn điểm đến hoặc thêm nhiều chặng để tối ưu tuyến đường.',
                style: TextStyle(
                  color: _AiInterviewViewState._ink,
                  fontSize: 13,
                  height: 1.4,
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
    final hasError = error != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError
              ? _AiInterviewViewState._accent.withOpacity(0.6)
              : _AiInterviewViewState._line.withOpacity(0.6),
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x051A1F36),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _AiInterviewViewState._primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _AiInterviewViewState._primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.destination.region,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AiInterviewViewState._muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: _AiInterviewViewState._muted,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  backgroundColor: _AiInterviewViewState._line.withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DestinationDateStrip(
            start: item.startDate,
            end: item.endDate,
            onPickRange: onPickDate,
            onPickStart: onPickStartDate,
            onPickEnd: onPickEndDate,
          ),
          if (hasError) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _AiInterviewViewState._accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: _AiInterviewViewState._accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: _AiInterviewViewState._accent,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _AiInterviewViewState._line.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AiInterviewViewState._line.withOpacity(0.4)),
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
              size: 16,
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
            icon: const Icon(Icons.edit_calendar_outlined, size: 20),
            color: _AiInterviewViewState._primary,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shadowColor: Colors.black.withOpacity(0.04),
              elevation: 1,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _AiInterviewViewState._line.withOpacity(0.4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x02000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: _AiInterviewViewState._primary),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AiInterviewViewState._ink,
                        fontSize: 12,
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



