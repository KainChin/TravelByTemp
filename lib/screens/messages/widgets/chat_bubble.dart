import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:assignment/core/widgets/safe_memory_image.dart';

import '../message_assets.dart';
import '../messages_styles.dart';
import '../models/chat_message.dart';

/// Renders a single [ChatMessage] as either a left-aligned AI bubble (with
/// avatar) or a right-aligned user bubble (with sent checkmark).
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return message.isAi ? _buildAiBubble() : _buildUserBubble();
  }

  Widget _buildAiBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: MessageSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: MessageColors.tagBackground,
            child: ClipOval(
              child: Image.asset(
                MessageAssets.aiAvatar,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.smart_toy_outlined,
                  size: 18,
                  color: MessageColors.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: MessageSpacing.sm),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(MessageSpacing.md),
              decoration: BoxDecoration(
                color: MessageColors.aiBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(MessageRadius.bubble),
                  bottomLeft: Radius.circular(MessageRadius.bubble),
                  bottomRight: Radius.circular(MessageRadius.bubble),
                ),
                boxShadow: MessageShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(MessageRadius.card),
                      child: SafeMemoryImage(
                        bytes: message.imageBytes,
                        source: 'ChatBubble ${message.imageName ?? 'attachment'}',
                        width: 220,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: MessageSpacing.sm),
                  ],
                  Text(message.message, style: MessageTextStyles.bubbleText),
                  const SizedBox(height: MessageSpacing.sm),
                  Text(_formatTime(message.timestamp), style: MessageTextStyles.timestamp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: MessageSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(MessageSpacing.md),
              decoration: BoxDecoration(
                color: MessageColors.userBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(MessageRadius.bubble),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(MessageRadius.bubble),
                  bottomRight: Radius.circular(MessageRadius.bubble),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.message, style: MessageTextStyles.bubbleText),
                  const SizedBox(height: MessageSpacing.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatTime(message.timestamp), style: MessageTextStyles.timestamp),
                      if (message.isSent) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 14, color: MessageColors.onlineGreen),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);
}
