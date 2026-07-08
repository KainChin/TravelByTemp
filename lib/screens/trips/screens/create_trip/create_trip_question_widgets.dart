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
            borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: _AiInterviewViewState._line.withOpacity(0.5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x041A1F36),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: _AiInterviewViewState._ink,
                height: 1.45,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
    this.imagePath,
  });

  final String step;
  final String title;
  final String subtitle;
  final Widget child;
  final String? trailing;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7, // 70% width for the content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _AiInterviewViewState._primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: _AiInterviewViewState._primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _AiInterviewViewState._ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _AiInterviewViewState._primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trailing!,
                          style: const TextStyle(
                            color: _AiInterviewViewState._primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _AiInterviewViewState._muted,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
          if (imagePath != null) ...[
            const SizedBox(width: 32),
            Expanded(
              flex: 3, // 30% width for the image
              child: Container(
                constraints: const BoxConstraints(maxHeight: 180), // Prevent image from getting too tall on very wide screens
                alignment: Alignment.topRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath!,
                    fit: BoxFit.contain, // Shows the full image without cropping
                  ),
                ),
              ),
            ),
          ]
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
          elevation: isSelected ? 1 : 0,
          pressElevation: 2,
          shadowColor: _AiInterviewViewState._primary.withOpacity(0.1),
          side: BorderSide(
            color: isSelected
                ? _AiInterviewViewState._primary
                : _AiInterviewViewState._line.withOpacity(0.8),
            width: isSelected ? 1.5 : 1,
          ),
          labelStyle: TextStyle(
            color: isSelected
                ? _AiInterviewViewState._primary
                : _AiInterviewViewState._ink,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
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

