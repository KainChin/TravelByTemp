import 'package:flutter/material.dart';

import '../message_assets.dart';
import '../messages_styles.dart';

/// Top header: travel-themed background image, "Messages" title and the
/// two subtitle lines. Includes the trash/clear-chat button in the corner.
class ChatHeader extends StatelessWidget {
  final VoidCallback? onClearChat;

  const ChatHeader({super.key, this.onClearChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        MessageSpacing.xl,
        MessageSpacing.xxl,
        MessageSpacing.xl,
        MessageSpacing.xxl * 2,
      ),
      decoration: const BoxDecoration(color: MessageColors.backgroundMint),
      child: Stack(
        children: [
          // Background artwork — falls back to a transparent box if the
          // asset hasn't been added yet, so the layout never breaks.
          Positioned.fill(
            child: Image.asset(
              MessageAssets.headerBackground,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('Messages', style: MessageTextStyles.headerTitle),
                        SizedBox(width: MessageSpacing.sm),
                        Icon(Icons.flight, color: MessageColors.primaryGreen, size: 22),
                      ],
                    ),
                    const SizedBox(height: MessageSpacing.md),
                    const Text(
                      'Chat với AI Travel Assistant',
                      style: MessageTextStyles.headerSubtitle,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Bạn cần đi đâu hôm nay?',
                      style: MessageTextStyles.headerSubtitleMuted,
                    ),
                  ],
                ),
              ),
              _ClearButton(onTap: onClearChat),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ClearButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MessageColors.cardWhite,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(MessageSpacing.md),
          child: Icon(Icons.delete_outline, size: 20, color: MessageColors.textDark),
        ),
      ),
    );
  }
}
