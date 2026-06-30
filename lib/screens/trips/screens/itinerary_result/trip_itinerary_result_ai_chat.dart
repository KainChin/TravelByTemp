// ignore_for_file: use_string_in_part_of_directives

part of trip_itinerary_result_screen;

class _AiChatSheet extends StatefulWidget {
  const _AiChatSheet({
    required this.title,
    required this.dayLabel,
    required this.budgetLabel,
    required this.onApply,
    this.initialPrompt,
  });

  final String title;
  final String dayLabel;
  final String budgetLabel;
  final String? initialPrompt;
  final ValueChanged<List<_AiChange>> onApply;

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _SendAiIntent extends Intent {
  const _SendAiIntent();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  late final TextEditingController _controller;
  String? _reply;
  List<_AiChange> _changes = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final prompt = (text ?? _controller.text).trim();
    if (prompt.isEmpty) return;
    final draft = _draftFor(prompt);
    setState(() {
      _controller.text = prompt;
      _reply = draft.message;
      _changes = draft.changes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    const quickActions = [
      'Tối ưu lịch trình',
      'Giảm chi phí',
      'Đổi phương tiện',
      'Thêm quán ăn',
      'Thêm khách sạn',
      'Thêm điểm tham quan',
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: _TripItineraryResultScreenState._primarySoft,
                    child: Icon(Icons.auto_awesome, color: _TripItineraryResultScreenState._primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('AI chỉnh lịch trình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ContextChip(icon: Icons.luggage_outlined, text: widget.title),
                  _ContextChip(icon: Icons.today_outlined, text: widget.dayLabel),
                  _ContextChip(icon: Icons.account_balance_wallet_outlined, text: widget.budgetLabel),
                ],
              ),
              const SizedBox(height: 12),
              Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.enter): const _SendAiIntent(),
                },
                child: Actions(
                  actions: {
                    _SendAiIntent: CallbackAction<_SendAiIntent>(
                      onInvoke: (intent) {
                        _send();
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText:
                          'Bạn muốn AI giúp gì?\n\nVí dụ:\n• Tối ưu lịch trình\n• Giảm ngân sách\n• Đổi phương tiện\n• Thêm địa điểm gần đây\n• Thêm quán ăn\n• Đổi khách sạn',
                      filled: true,
                      fillColor: _TripItineraryResultScreenState._bg,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 64),
                        child: Icon(Icons.auto_awesome, color: _TripItineraryResultScreenState._primary),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 64),
                        child: IconButton(
                          tooltip: 'Nhập bằng giọng nói',
                          onPressed: () {},
                          icon: const Icon(Icons.mic_none_outlined),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickActions
                    .map(
                      (action) => ActionChip(
                        label: Text(action),
                        avatar: const Icon(Icons.flash_on_outlined, size: 15),
                        onPressed: () => _send(action),
                        backgroundColor: const Color(0xFFF1F6F3),
                        side: BorderSide.none,
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    )
                    .toList(),
              ),
              if (_reply != null) ...[
                const SizedBox(height: 14),
                _AiResponseCard(
                  reply: _reply!,
                  changes: _changes,
                  onCancel: () => setState(() {
                    _reply = null;
                    _changes = const [];
                  }),
                  onApply: () => widget.onApply(_changes),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _send(),
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: const Text('Gửi yêu cầu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _TripItineraryResultScreenState._primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

class _AiResponseCard extends StatelessWidget {
  const _AiResponseCard({
    required this.reply,
    required this.changes,
    required this.onCancel,
    required this.onApply,
  });

  final String reply;
  final List<_AiChange> changes;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TripItineraryResultScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phản hồi của AI', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            reply,
            style: const TextStyle(
              color: _TripItineraryResultScreenState._muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Đề xuất thay đổi', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...changes.map((change) => _AiChangeRow(change: change)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: onCancel, child: const Text('Hủy')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _TripItineraryResultScreenState._primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Áp dụng thay đổi'),
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

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _TripItineraryResultScreenState._primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChangeRow extends StatelessWidget {
  const _AiChangeRow({required this.change});

  final _AiChange change;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: _TripItineraryResultScreenState._primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(change.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  change.description,
                  style: const TextStyle(color: _TripItineraryResultScreenState._muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
