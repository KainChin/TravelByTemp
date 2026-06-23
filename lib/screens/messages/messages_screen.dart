import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_colors.dart';
import 'package:assignment/data/mock_data.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildListHeader(context),
        Expanded(child: _ChatView()),
      ],
    );
  }

  Widget _buildListHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Messages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  'Chat with your AI travel assistant.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showMessage(context, 'Chat cleared'),
              child: const Icon(Icons.delete_outline, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ChatView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showMessage(context, 'Already in the active chat'),
                  icon: const Icon(Icons.arrow_back, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.smart_toy, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('AI Travel Assistant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          SizedBox(width: 4),
                          Icon(Icons.verified, size: 16, color: AppColors.primary),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Online', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showMessage(context, 'Voice call is not available yet'),
                  icon: const Icon(Icons.phone_outlined, size: 22),
                ),
                IconButton(
                  onPressed: () => _showMessage(context, 'Conversation options opened'),
                  icon: const Icon(Icons.more_vert, size: 22),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Today', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(height: 16),
              _BotBubble(
                'Xin chào ${MockData.userName}! 👋 Mình có thể giúp gì cho chuyến đi của bạn hôm nay?',
                '09:28',
              ),
              _UserBubble(
                'Mình đang lên kế hoạch đi Đà Lạt 2 ngày sau đó ghé Nha Trang 1 ngày. Bạn có thể gợi ý lịch trình chi tiết giúp mình được không?',
                '09:29',
              ),
              _BotBubble('Tuyệt vời! Mình sẽ gợi ý lịch trình chi tiết cho bạn ngay đây ✨', '09:30'),
              const SizedBox(height: 8),
              _ItineraryCard(),
              const SizedBox(height: 8),
              _UserBubble(
                'Cảm ơn bạn! Mình muốn đổi khách sạn ở Đà Lạt sang gần trung tâm hơn thì sao?',
                '09:32',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.smart_toy, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (i) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppColors.textHint.withValues(alpha: 0.5 + i * 0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildInputBar(context),
      ],
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showMessage(context, 'Attachment picker is not available yet'),
            icon: const Icon(Icons.add_circle_outline),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin với AI Travel Assistant...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showMessage(context, 'Emoji picker is not available yet'),
                    icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.primary),
                  ),
                  IconButton(
                    onPressed: () => _showMessage(context, 'Voice input is not available yet'),
                    icon: const Icon(Icons.mic, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BotBubble extends StatelessWidget {
  const _BotBubble(this.text, this.time);

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.smart_toy, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.text, this.time);

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: AppColors.primary),
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
}

class _ItineraryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 36),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đà Lạt 2N1Đ + Nha Trang 1N',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('Lịch trình được cá nhân hóa cho bạn',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.landscape, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          _destRow('Đà Lạt ⛰️', '2 Ngày • 1 Đêm', 'Ngày 1 - 2'),
          const Divider(height: 20),
          _destRow('Nha Trang 🏖️', '1 Ngày', 'Ngày 3'),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text('Xem chi tiết lịch trình',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _destRow(String title, String sub, String tag) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.image, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(tag, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
      ],
    );
  }
}
