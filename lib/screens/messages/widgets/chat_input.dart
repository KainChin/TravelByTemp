import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../messages_styles.dart';

/// Floating, pill-shaped input bar: "+" attachment button, text field,
/// emoji button and a mic / send button.
class ChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final Future<void> Function(String text, XFile image)? onImageSend;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onMicTap;
  final String hintText;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onImageSend,
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
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isSendingImage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAttachmentTap() async {
    if (widget.onAttachmentTap != null) {
      widget.onAttachmentTap!();
      return;
    }

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;
    setState(() => _selectedImage = image);
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    final image = _selectedImage;
    if (text.isEmpty && image == null) return;

    if (image != null && widget.onImageSend != null) {
      setState(() => _isSendingImage = true);
      try {
        await widget.onImageSend!(text, image);
        if (!mounted) return;
        _controller.clear();
        setState(() => _selectedImage = null);
      } finally {
        if (mounted) setState(() => _isSendingImage = false);
      }
      return;
    }

    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty || _selectedImage != null;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null) ...[
            _SelectedImagePreview(
              name: _selectedImage!.name,
              onRemove: () => setState(() => _selectedImage = null),
            ),
            const SizedBox(height: MessageSpacing.sm),
          ],
          Row(
            children: [
              _RoundButton(icon: Icons.add_photo_alternate_outlined, onTap: _handleAttachmentTap),
              const SizedBox(width: MessageSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: MessageTextStyles.bubbleText,
                  textInputAction: TextInputAction.send,
                  onChanged: (_) => setState(() {}),
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
                icon: _isSendingImage
                    ? Icons.hourglass_empty_rounded
                    : canSend
                        ? Icons.send_rounded
                        : Icons.mic_none_rounded,
                iconColor: MessageColors.primaryGreen,
                onTap: _isSendingImage ? null : (canSend ? _handleSend : widget.onMicTap),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _SelectedImagePreview({
    required this.name,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.image_outlined, size: 18, color: MessageColors.primaryGreen),
        const SizedBox(width: MessageSpacing.sm),
        Expanded(
          child: Text(
            name.isEmpty ? 'Ảnh đã chọn' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MessageTextStyles.inputHint,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, size: 18, color: MessageColors.textGrey),
          onPressed: onRemove,
        ),
      ],
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
