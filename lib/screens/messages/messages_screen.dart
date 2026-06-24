import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'messages_styles.dart';
import 'providers/chat_provider.dart';
import 'widgets/ai_info_card.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_input.dart';
import 'widgets/itinerary_card.dart';
import 'widgets/typing_indicator.dart';

/// Messages (AI Chat) screen.
///
/// [currentUserName] must come from the authenticated user — e.g.
/// `MessagesScreen(currentUserName: userModel.fullName)` — never hardcode it.
class MessagesScreen extends StatelessWidget {
  final String currentUserName;

  const MessagesScreen({super.key, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>(
      create: (_) => ChatProvider()..addInitialGreeting(currentUserName),
      child: const _MessagesView(),
    );
  }
}

class _MessagesView extends StatefulWidget {
  const _MessagesView();

  @override
  State<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<_MessagesView> {
  final ScrollController _scrollController = ScrollController();
  String? _lastShownError;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    final error = chatProvider.errorMessage;
    if (error != null && error != _lastShownError) {
      _lastShownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      });
    }

    _scrollToBottom();

    return Scaffold(
      backgroundColor: MessageColors.backgroundMint,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ChatHeader(onClearChat: () => context.read<ChatProvider>().clearChat()),
                Positioned(
                  left: MessageSpacing.lg,
                  right: MessageSpacing.lg,
                  bottom: -36,
                  child: AiInfoCard(onBack: () => Navigator.maybePop(context)),
                ),
              ],
            ),
            const SizedBox(height: 52),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  MessageSpacing.lg,
                  MessageSpacing.lg,
                  MessageSpacing.lg,
                  MessageSpacing.lg,
                ),
                itemCount: chatProvider.messages.length + (chatProvider.isTyping ? 2 : 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const _DatePill(label: 'Hôm nay');
                  }

                  final messageIndex = index - 1;
                  if (messageIndex < chatProvider.messages.length) {
                    final message = chatProvider.messages[messageIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChatBubble(message: message),
                        if (message.itinerary != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: MessageSpacing.lg),
                            child: ItineraryCard(plan: message.itinerary!),
                          ),
                      ],
                    );
                  }

                  return const TypingIndicator();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MessageSpacing.lg,
                0,
                MessageSpacing.lg,
                MessageSpacing.lg,
              ),
              child: ChatInput(
                onSend: (text) => context.read<ChatProvider>().sendMessage(text),
                onImageSend: (text, image) =>
                    context.read<ChatProvider>().sendImageMessage(text: text, image: image),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String label;
  const _DatePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: MessageSpacing.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: MessageSpacing.lg,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: MessageColors.tagBackground,
          borderRadius: BorderRadius.circular(MessageRadius.pill),
        ),
        child: Text(label, style: MessageTextStyles.datePill),
      ),
    );
  }
}
