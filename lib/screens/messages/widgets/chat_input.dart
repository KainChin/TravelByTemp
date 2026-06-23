import 'package:flutter/material.dart';

import '../messages_styles.dart';

/// Floating, pill-shaped input bar: "+" attachment button, text field,
/// emoji button and a mic / send button.
class ChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onMicTap;
  final String hintText;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onAttachmentTap,
    this.onEmojiTap,
    this.onMicTap,
    this.hintText = 'Nhắn tin với AI Travel Assistant...',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MessageSpacing.md,
        vertical: MessageSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: MessageColors.inputBackground,
        borderRadius: BorderRadius.circular(MessageRadius.input),
        boxShadow: MessageShadows.floating,
      ),
      child: Row(
        children: [
          _RoundButton(icon: Icons.add, onTap: widget.onAttachmentTap),
          const SizedBox(width: MessageSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              style: MessageTextStyles.bubbleText,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: MessageTextStyles.inputHint,
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined, color: MessageColors.textGrey),
            onPressed: widget.onEmojiTap,
          ),
          _RoundButton(
            icon: Icons.mic_none_rounded,
            iconColor: MessageColors.primaryGreen,
            onTap: widget.onMicTap ?? _handleSend,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;

  const _RoundButton({
    required this.icon,
    this.onTap,
    this.iconColor = MessageColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MessageColors.backgroundMint,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
