import 'package:flutter/material.dart';

import '../message_assets.dart';
import '../messages_styles.dart';

/// Floating card with the AI avatar, name, verified badge, online status,
/// a back button and call / more action buttons.
class AiInfoCard extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onMore;
  final bool isOnline;

  const AiInfoCard({
    super.key,
    this.onBack,
    this.onCall,
    this.onMore,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MessageSpacing.md,
        vertical: MessageSpacing.md,
      ),
      decoration: BoxDecoration(
        color: MessageColors.cardWhite,
        borderRadius: BorderRadius.circular(MessageRadius.card),
        boxShadow: MessageShadows.floating,
      ),
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.arrow_back, onTap: onBack),
          const SizedBox(width: MessageSpacing.md),
          CircleAvatar(
            radius: 26,
            backgroundColor: MessageColors.tagBackground,
            child: ClipOval(
              child: Image.asset(
                MessageAssets.aiAvatar,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.smart_toy_outlined,
                  color: MessageColors.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: MessageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Flexible(
                      child: Text(
                        'AI Travel Assistant',
                        style: MessageTextStyles.aiName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.verified, size: 16, color: MessageColors.onlineGreen),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: MessageColors.onlineGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: MessageTextStyles.onlineStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _RoundIconButton(icon: Icons.call_outlined, onTap: onCall),
          const SizedBox(width: MessageSpacing.sm),
          _RoundIconButton(icon: Icons.more_horiz, onTap: onMore),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundIconButton({required this.icon, this.onTap});

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
          child: Icon(icon, size: 18, color: MessageColors.textDark),
        ),
      ),
    );
  }
}
