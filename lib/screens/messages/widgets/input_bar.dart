import 'package:flutter/material.dart';
import '../messages_styles.dart';

class InputBar extends StatefulWidget {
  final Future<void> Function(String) onSend;
  final VoidCallback onMic;
  final VoidCallback onImage;
  final bool isLoading;

  const InputBar({
    super.key,
    required this.onSend,
    required this.onMic,
    required this.onImage,
    required this.isLoading,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    _ctrl.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MsgColors.surface,
        border: Border(
          top: BorderSide(color: MsgColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // + Button (image picker)
            _IconBtn(
              icon: Icons.add,
              onTap: widget.onImage,
              outlined: true,
            ),
            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: MsgColors.bg,
                  borderRadius:
                  BorderRadius.circular(MsgDimens.inputRadius),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                    fontSize: 15,
                    color: MsgColors.textDark,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nhắn tin với AI Travel Assistant...',
                    hintStyle: MsgTextStyles.inputHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Mic or Send
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _hasText
                  ? _SendBtn(onTap: _submit, key: const ValueKey('send'))
                  : _IconBtn(
                key: const ValueKey('mic'),
                icon: Icons.mic,
                onTap: widget.onMic,
                color: MsgColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;
  final Color color;

  const _IconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.outlined = false,
    this.color = MsgColors.textGrey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: outlined
              ? Border.all(color: MsgColors.borderLight, width: 1.5)
              : null,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SendBtn({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: MsgColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
