import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'messages_styles.dart';
import 'models/message_model.dart';
import 'providers/chat_provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/input_bar.dart';
import 'widgets/typing_indicator.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _scrollCtrl = ScrollController();
  bool _isRecording = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text, ChatProvider provider) async {
    await provider.send(text);
    _scrollToBottom();
  }

  Future<void> _handleMic() async {
    setState(() => _isRecording = !_isRecording);
    // TODO: tích hợp speech_to_text package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording
            ? '🎙️ Đang ghi âm...'
            : '⏹️ Dừng ghi âm'),
        duration: const Duration(seconds: 1),
        backgroundColor: MsgColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📷 Đã chọn: ${file.name}'),
          backgroundColor: MsgColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // TODO: gửi ảnh kèm tin nhắn
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: MsgColors.bg,
            appBar: _buildAppBar(provider),
            body: Column(
              children: [
                Expanded(
                  child: provider.messages.isEmpty
                      ? _buildWelcome(provider)
                      : _buildChat(provider),
                ),
                InputBar(
                  onSend: (text) => _handleSend(text, provider),
                  onMic: _handleMic,
                  onImage: _handleImage,
                  isLoading: provider.isLoading,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatProvider provider) {
    return AppBar(
      backgroundColor: MsgColors.surface,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Messages', style: MsgTextStyles.appBarTitle),
              const SizedBox(width: 6),
              const Text('✨', style: TextStyle(fontSize: 18)),
            ],
          ),
          const Text('Chat with your AI travel assistant.',
              style: MsgTextStyles.appBarSub),
        ],
      ),
      actions: [
        // 🗑️ Refresh/clear chat
        GestureDetector(
          onTap: () => _showClearDialog(provider),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: MsgColors.borderLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: MsgColors.textDark, size: 20),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: MsgColors.borderLight),
      ),
    );
  }

  Widget _buildChat(ChatProvider provider) {
    _scrollToBottom();
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 16),
      itemCount: provider.messages.length + (provider.isLoading ? 1 : 0) + 1,
      itemBuilder: (_, i) {
        // Date separator
        if (i == 0) return _dateSeparator('Today');

        final msgIndex = i - 1;

        // Typing indicator
        if (provider.isLoading && msgIndex == provider.messages.length) {
          return const TypingIndicator();
        }

        if (msgIndex >= provider.messages.length) return const SizedBox();

        return ChatBubble(message: provider.messages[msgIndex]);
      },
    );
  }

  Widget _buildWelcome(ChatProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // AI "card" header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MsgColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _aiHeader(),
                const SizedBox(height: 16),
                // Welcome bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: MsgColors.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Xin chào! 👋\nMình có thể giúp gì cho chuyến đi của bạn hôm nay?',
                    style: MsgTextStyles.bubbleAI,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Gợi ý nhanh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MsgColors.textGrey,
                )),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.quickSuggestions
                .map((s) => GestureDetector(
              onTap: () => _handleSend(s, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: MsgColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MsgColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(s, style: MsgTextStyles.quickChip),
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _aiHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MsgColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('🤖', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('AI Travel Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MsgColors.textDark,
                      )),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified,
                      color: MsgColors.primary, size: 16),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: const BoxDecoration(
                      color: MsgColors.online,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Text('Online', style: MsgTextStyles.onlineDot),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: MsgColors.borderLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: MsgColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MsgColors.borderLight),
              ),
              child: Text(label, style: MsgTextStyles.dateChip),
            ),
          ),
          const Expanded(child: Divider(color: MsgColors.borderLight)),
        ],
      ),
    );
  }

  void _showClearDialog(ChatProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Làm mới đoạn chat?'),
        content: const Text('Toàn bộ lịch sử trò chuyện sẽ bị xoá.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ', style: TextStyle(color: MsgColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              provider.clear();
              Navigator.pop(context);
            },
            child: const Text('Xoá',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}