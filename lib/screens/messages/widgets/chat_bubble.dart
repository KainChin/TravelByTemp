import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../messages_styles.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _userBubble() : _aiBubble();
  }

  Widget _userBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 60,
          right: MsgDimens.hPad,
          bottom: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: MsgColors.bubbleUser,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(MsgDimens.bubbleRadius),
                  topRight: Radius.circular(MsgDimens.bubbleRadius),
                  bottomLeft: Radius.circular(MsgDimens.bubbleRadius),
                  bottomRight: Radius.circular(MsgDimens.bubbleRadiusSmall),
                ),
              ),
              child: Text(message.content, style: MsgTextStyles.bubbleUser),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatTime(message.timestamp),
                    style: MsgTextStyles.timestamp),
                const SizedBox(width: 4),
                const Icon(Icons.done_all,
                    size: 14, color: MsgColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          left: MsgDimens.hPad,
          right: 60,
          bottom: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: MsgDimens.avatarRadius,
              backgroundColor: MsgColors.primaryLight,
              child: const Text('🤖', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: MsgColors.bubbleAI,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(MsgDimens.bubbleRadius),
                        topRight: Radius.circular(MsgDimens.bubbleRadius),
                        bottomRight: Radius.circular(MsgDimens.bubbleRadius),
                        bottomLeft:
                        Radius.circular(MsgDimens.bubbleRadiusSmall),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(message.content, style: MsgTextStyles.bubbleAI),
                  ),
                  const SizedBox(height: 4),
                  Text(_formatTime(message.timestamp),
                      style: MsgTextStyles.timestamp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
