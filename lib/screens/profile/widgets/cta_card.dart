import 'package:flutter/material.dart';

class CtaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final List<String> imageUrls;
  final bool isOutlined;
  final bool showPlayButton;
  final VoidCallback? onPressed; // ← thêm mới

  const CtaCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.imageUrls,
    this.isOutlined = false,
    this.showPlayButton = false,
    this.onPressed, // ← thêm mới
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildContent()),
          const SizedBox(width: 12),
          _buildImages(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF3A7D5A), size: 22),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.4)),
        const SizedBox(height: 10),
        _buildButton(),
      ],
    );
  }

  Widget _buildButton() {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed, // ← sửa
        icon: const Icon(Icons.upload_outlined, size: 14, color: Color(0xFF3A7D5A)),
        label: Text(buttonLabel, style: const TextStyle(color: Color(0xFF3A7D5A), fontSize: 13)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3A7D5A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }
    return ElevatedButton(
      onPressed: onPressed, // ← sửa
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3A7D5A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        elevation: 0,
      ),
      child: Text(buttonLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _buildImages() {
    return SizedBox(
      width: 110, height: 90,
      child: Stack(
        children: [
          for (int i = 0; i < imageUrls.length && i < 3; i++)
            Positioned(
              left: i * 20.0,
              top: i == 1 ? 0 : (i == 0 ? 6 : 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrls[i], width: 68, height: 68, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 68, height: 68, color: Colors.grey[300]),
                ),
              ),
            ),
          if (showPlayButton)
            Center(
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, size: 16, color: Color(0xFF3A7D5A)),
              ),
            ),
        ],
      ),
    );
  }
}
