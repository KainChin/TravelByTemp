
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/chat_provider.dart';
import 'widgets/airplane_animation.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/chat_sidebar.dart';

class MessagesScreen extends StatelessWidget {
  final String currentUserName;

  const MessagesScreen({super.key, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>(
      create: (_) {
        final provider = ChatProvider();
        provider.initialize(currentUserName);
        return provider;
      },
      child: _MessagesView(currentUserName: currentUserName),
    );
  }
}

class _MessagesView extends StatefulWidget {
  final String currentUserName;
  const _MessagesView({required this.currentUserName});

  @override
  State<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<_MessagesView> {
  final ScrollController _scrollController = ScrollController();
  String? _lastShownError;
  int _selectedChatIndex = 0;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    // Show loading spinner while restoring chat history from storage
    if (!chatProvider.isReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D47A1),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final error = chatProvider.errorMessage;
    if (error != null && error != _lastShownError) {
      _lastShownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      });
    }

    _scrollToBottom();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return _buildWideLayout(context, chatProvider);
        } else {
          return _buildNarrowLayout(context, chatProvider);
        }
      },
    );
  }

  Widget _buildWideLayout(BuildContext context, ChatProvider chatProvider) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/chatAI.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          // Airplane Animation
          const AirplaneAnimation(),
          // Layout
          SafeArea(
            child: Row(
              children: [
                // Sidebar
                SizedBox(
                  width: 300,
                  child: ChatSidebar(
                    historyItems: chatProvider.history,
                    selectedIndex: _selectedChatIndex,
                    onItemSelected: (i) {
                      setState(() => _selectedChatIndex = i);
                      context.read<ChatProvider>().loadSession(chatProvider.history[i].id);
                    },
                    onNewChat: () {
                      context.read<ChatProvider>().clearAndRestart();
                      setState(() => _selectedChatIndex = -1);
                    },
                  ),
                ),
                // Main panel without glassmorphism (fully transparent)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      color: Colors.transparent,
                      child: _buildChatPanel(context, chatProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, ChatProvider chatProvider) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: Drawer(
        width: 290,
        backgroundColor: Colors.transparent,
        child: ChatSidebar(
          historyItems: chatProvider.history,
          selectedIndex: _selectedChatIndex,
          onItemSelected: (i) {
            setState(() => _selectedChatIndex = i);
            context.read<ChatProvider>().loadSession(chatProvider.history[i].id);
            Navigator.of(context).pop();
          },
          onNewChat: () {
            context.read<ChatProvider>().clearAndRestart();
            setState(() => _selectedChatIndex = -1);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Full-screen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/chatAI.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          // Airplane Animation
          const AirplaneAnimation(),
          SafeArea(
            child: Container(
              color: Colors.transparent,
              child: _buildChatPanel(context, chatProvider, showMenuButton: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(BuildContext context, ChatProvider chatProvider,
      {bool showMenuButton = false}) {
    return Column(
      children: [
        // Top Bar
        _ChatTopBar(
          showMenuButton: showMenuButton,
          onNewChat: () => context.read<ChatProvider>().clearAndRestart(),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: chatProvider.messages.length +
                (chatProvider.isTyping ? 2 : 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _DatePill(label: 'Hôm nay');
              }
              final msgIndex = index - 1;
              if (msgIndex < chatProvider.messages.length) {
                final message = chatProvider.messages[msgIndex];
                return ChatBubble(message: message);
              }
              return const TypingIndicator();
            },
          ),
        ),
        // Quick chip suggestions shown only when greeting exists alone
        if (chatProvider.messages.length == 1 &&
            chatProvider.messages.first.isAi)
          _QuickChips(
            onChipTap: (text) =>
                context.read<ChatProvider>().sendMessage(text),
          ),
        // Input
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 100), // Pushes the input bar up above the 72px dock
          child: ChatInput(
            onSend: (text) => context.read<ChatProvider>().sendMessage(text),
            onImageSend: (text, image) => context
                .read<ChatProvider>()
                .sendImageMessage(text: text, image: image),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _ChatTopBar extends StatelessWidget {
  final bool showMenuButton;
  final VoidCallback onNewChat;

  const _ChatTopBar({required this.onNewChat, this.showMenuButton = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.maybePop(context),
            ),
          const SizedBox(width: 4),
          // Avatar with status dot
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF1976D2),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/chatAI.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI Travel Assistant',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF4CAF50), size: 16),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFF00C853), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Online',
                        style: TextStyle(color: Color(0xFF00C853), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Làm mới chat button
          OutlinedButton.icon(
            onPressed: onNewChat,
            icon: const Icon(Icons.refresh_rounded,
                size: 16, color: Colors.white),
            label: const Text('Làm mới chat',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK CHIPS
// ─────────────────────────────────────────────────────────────────────────────
class _QuickChips extends StatelessWidget {
  final ValueChanged<String> onChipTap;
  const _QuickChips({required this.onChipTap});

  static const _chips = [
    '🏖 Lịch trình Đà Nẵng',
    '🌴 Review Phú Quốc',
    '🗾 Du lịch Nhật Bản',
    '🎌 Visa Châu Âu',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _chips
            .map(
              (chip) => GestureDetector(
                onTap: () => onChipTap(chip),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    chip,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE PILL
// ─────────────────────────────────────────────────────────────────────────────
class _DatePill extends StatelessWidget {
  final String label;
  const _DatePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
