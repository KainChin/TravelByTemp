import 'package:flutter/material.dart';

import '../message_assets.dart';
import '../messages_styles.dart';

/// Bubble with three animated dots shown while the AI is "typing".
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MessageSpacing.lg),
      child: Row(
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MessageSpacing.lg,
              vertical: MessageSpacing.md,
            ),
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final t = (_controller.value - delay) % 1.0;
                    final normalized = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
                    final scale = 0.6 + 0.4 * normalized;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: MessageColors.textGrey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
