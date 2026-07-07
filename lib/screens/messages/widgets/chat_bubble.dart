import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:assignment/core/widgets/safe_memory_image.dart';

import '../message_assets.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return message.isAi ? _buildAiBubble(context) : _buildUserBubble();
  }

  Widget _buildAiBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // AI Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1976D2),
            child: ClipOval(
              child: Image.asset(
                MessageAssets.aiAvatar,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.smart_toy_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF attachment if present
                if (message.message.contains('pdf_attachment:'))
                  _PdfAttachmentCard(message: message),
                // Regular text
                if (!message.message.startsWith('pdf_attachment:'))
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.imageBytes != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SafeMemoryImage(
                              bytes: message.imageBytes,
                              source: 'ChatBubble ${message.imageName ?? 'img'}',
                              width: 220,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        MarkdownBody(
                          data: message.message,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                                color: Color(0xFF1A2340),
                                fontSize: 14.5,
                                height: 1.6),
                            h1: const TextStyle(
                                color: Color(0xFF1A2340),
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            h2: const TextStyle(
                                color: Color(0xFF1A2340),
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            h3: const TextStyle(
                                color: Color(0xFF1A2340),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            strong: const TextStyle(
                                color: Color(0xFF1A2340),
                                fontWeight: FontWeight.bold),
                            em: const TextStyle(
                                fontStyle: FontStyle.italic),
                            listBullet: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 16),
                            code: TextStyle(
                                backgroundColor: Colors.grey.shade200,
                                fontFamily: 'monospace',
                                color: const Color(0xFFD32F2F)),
                            codeblockDecoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8)),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                    color: const Color(0xFF1565C0), width: 4),
                              ),
                              color: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(message.timestamp),
                          style: const TextStyle(
                              color: Color(0xFF90A4AE), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SafeMemoryImage(
                        bytes: message.imageBytes,
                        source: 'UserBubble ${message.imageName ?? 'img'}',
                        width: 220,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.message,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11),
                      ),
                      if (message.isSent) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.85)),
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

  String _formatTime(DateTime t) => DateFormat('HH:mm').format(t);
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF Attachment Card
// ─────────────────────────────────────────────────────────────────────────────
class _PdfAttachmentCard extends StatelessWidget {
  final ChatMessage message;
  const _PdfAttachmentCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFF1976D2), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Lịch trình chi tiết 3N2Đ Đà Nẵng - Hội An',
                      style: TextStyle(
                          color: Color(0xFF1A2340),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'PDF • 1.2 MB',
                      style: TextStyle(
                          color: Color(0xFF78909C), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFECEFF1), height: 1),
          const SizedBox(height: 10),
          const Text(
            'Đây là lịch trình chi tiết kèm gợi ý khách sạn và chi phí dự kiến. Bạn xem nhé!',
            style: TextStyle(
                color: Color(0xFF37474F), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
