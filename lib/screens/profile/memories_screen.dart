import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignment/services/firestore_service.dart';
import 'package:assignment/screens/profile/video/video_preview_screen.dart';

class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Kỉ niệm của tôi',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF3A7D5A)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmpty(context);
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) => _MemoryCard(
              docId: docs[i].id,
              data: docs[i].data() as Map<String, dynamic>,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_album_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Chưa có kỉ niệm nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Upload ảnh và tạo slideshow để lưu kỉ niệm!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('Quay lại Profile',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A7D5A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _MemoryCard({required this.docId, required this.data});

  Future<void> _openMemory(BuildContext context) async {
    final tripId = data['tripId'] as String? ?? '';
    final tripName = data['tripName'] as String? ?? '';
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? 'backend-session-user';

    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa đăng nhập!')));
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripId)
          .collection('photos')
          .get();

      if (snap.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chuyến "$tripName" chưa có ảnh!')));
        }
        return;
      }

      final photos = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'base64': d['base64'] as String,
          'fileName': d['fileName'] as String,
        };
      }).toList();

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPreviewScreen(
              tripId: tripId,
              tripName: tripName,
              photos: photos,
              isViewOnly: true, // ← không hiện nút lưu khi xem lại
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = data['thumbnail'] as String? ?? '';
    final tripName = data['tripName'] as String? ?? 'Chuyến đi';
    final videoName = data['videoName'] as String? ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final dateStr = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : '';

    return GestureDetector(
      onTap: () => _openMemory(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // ── Thumbnail ──
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: thumbnail.isNotEmpty
                  ? Image.memory(base64Decode(thumbnail),
                  width: 100, height: 90, fit: BoxFit.cover)
                  : Container(
                  width: 100, height: 90,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_outlined,
                      color: Colors.grey)),
            ),
            const SizedBox(width: 12),
            // ── Info ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tripName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(videoName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(dateStr,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            // ── Play ──
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A7D5A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow,
                    color: Color(0xFF3A7D5A), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
