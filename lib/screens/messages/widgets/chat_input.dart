import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_bubble.dart';

class ChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final Future<void> Function(String text, XFile image)? onImageSend;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onMicTap;
  final String hintText;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onImageSend,
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
  Uint8List? _selectedImageBytes;
  bool _isSendingImage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAttachmentTap() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
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
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });
      } finally {
        if (mounted) setState(() => _isSendingImage = false);
      }
      return;
    }

    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        _controller.text.trim().isNotEmpty || _selectedImage != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null && _selectedImageBytes != null) ...[
            _SelectedImagePreview(
              name: _selectedImage!.name,
              imageBytes: _selectedImageBytes!,
              onRemove: () => setState(() {
                _selectedImage = null;
                _selectedImageBytes = null;
              }),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              // Sparkle / AI icon
              Container(
                margin: const EdgeInsets.only(left: 6),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              // Image Attachment
              IconButton(
                icon: const Icon(Icons.image_outlined,
                    color: Color(0xFF1976D2), size: 22),
                onPressed: _handleAttachmentTap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF1A2340)),
                  textInputAction: TextInputAction.send,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                        color: Color(0xFF90A4AE), fontSize: 14),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              // Emoji icon
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined,
                    color: Color(0xFF90A4AE), size: 22),
                onPressed: widget.onEmojiTap,
                visualDensity: VisualDensity.compact,
              ),
              // Mic icon (shown when nothing to send)
              if (!canSend)
                IconButton(
                  icon: const Icon(Icons.mic_none_rounded,
                      color: Color(0xFF90A4AE), size: 22),
                  onPressed: widget.onMicTap,
                  visualDensity: VisualDensity.compact,
                ),
              // Send button (blue circle)
              GestureDetector(
                onTap: _isSendingImage
                    ? null
                    : (canSend ? _handleSend : null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canSend
                        ? const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFFB0BEC5),
                              const Color(0xFFCFD8DC),
                            ],
                          ),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF1565C0).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: _isSendingImage
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                ),
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
  final Uint8List imageBytes;
  final VoidCallback onRemove;

  const _SelectedImagePreview({
    required this.name,
    required this.imageBytes,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => FullScreenImageViewer(
                        bytes: imageBytes,
                        title: name,
                        heroTag: 'preview_attached_img',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'preview_attached_img',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imageBytes,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ảnh đính kèm',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF78909C),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF78909C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
