// ignore_for_file: use_string_in_part_of_directives

part of create_trip_screen;

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _AiInterviewViewState._primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 18,
            color: _AiInterviewViewState._primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: _AiInterviewViewState._line),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: _AiInterviewViewState._ink,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String step;
  final String title;
  final String subtitle;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _AiInterviewViewState._primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  step,
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
                      title,
                      style: const TextStyle(
                        color: _AiInterviewViewState._ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _AiInterviewViewState._muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: _AiInterviewViewState._primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.onSelected,
    this.labelFor,
    this.multi = false,
  });

  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onSelected;
  final String Function(String value)? labelFor;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = selected.contains(value);
        return ChoiceChip(
          label: Text(labelFor?.call(value) ?? value),
          selected: isSelected,
          showCheckmark: multi,
          selectedColor: _AiInterviewViewState._primarySoft,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected
                ? _AiInterviewViewState._primary
                : _AiInterviewViewState._line,
          ),
          labelStyle: TextStyle(
            color: isSelected
                ? _AiInterviewViewState._primary
                : _AiInterviewViewState._ink,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AiInterviewViewState._line),
      ),
      child: child,
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

