import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/services/firestore_service.dart';
import 'package:assignment/screens/profile/upload/upload_screen.dart';
import 'package:assignment/screens/profile/video/select_photos_screen.dart';
import 'package:assignment/screens/profile/memories_screen.dart';
import 'widgets/profile_header.dart';
import 'widgets/stats_card.dart';
import 'widgets/my_trips_section.dart';
import 'widgets/cta_card.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final session = VietaiScope.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Do you want to log out of this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await session.logout();
    }
  }

  // ── Hiện bottom sheet chọn trip để tạo video ──
  void _showSelectTripDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn chuyến đi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.getTrips(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Chưa có chuyến đi nào!\nHãy upload ảnh trước.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.luggage_outlined,
                          color: Color(0xFF3A7D5A)),
                      title: Text(data['name'] ?? ''),
                      subtitle: Text('${data['photoCount'] ?? 0} ảnh'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectPhotosScreen(
                              tripId: docs[i].id,
                              tripName: data['name'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Section My Memories (dạng story tròn) ──
  Widget _buildMemoriesSection(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined,
                  color: Color(0xFF3A7D5A), size: 20),
              const SizedBox(width: 6),
              const Text('My Memories',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MemoriesScreen())),
                child: const Row(children: [
                  Text('View all',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3A7D5A),
                          fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFF3A7D5A)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Story circles ──
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.getVideos(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('Chưa có kỉ niệm nào',
                    style: TextStyle(color: Colors.grey, fontSize: 13));
              }
              return SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final thumbnail = data['thumbnail'] as String? ?? '';
                    final name = data['videoName'] as String? ?? '';
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const MemoriesScreen())),
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            // ── Story ring ──
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3A7D5A), Color(0xFF4CAF7A)],
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle),
                                child: ClipOval(
                                  child: thumbnail.isNotEmpty
                                      ? Image.memory(
                                    base64Decode(thumbnail),
                                    width: 54, height: 54,
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    width: 54, height: 54,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.photo,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // ── Tên ──
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final user = session.auth?.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──
            ProfileHeader(
              fullName: user?.fullName ?? 'Traveler',
              username: user?.username ?? 'traveler',
              email: user?.email ?? '',
              bio: user?.bio,
              role: user?.role ?? 'Traveler',
              location: session.locationName,
              onLogoutTap: () => _confirmLogout(context),
              onEditTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            // ── Stats ──
            const StatsCard(),
            // ── My Trips ──
            const MyTripsSection(),
            // ── My Memories ──
            _buildMemoriesSection(context),
            // ── Create Travel Video ──
            CtaCard(
              icon: Icons.video_library_outlined,
              title: 'Create Travel Video',
              description: 'Turn your memories into short videos in just a few taps.',
              buttonLabel: 'Create New Video ✨',
              imageUrls: const [
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200',
                'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=200',
                'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=200',
              ],
              showPlayButton: true,
              onPressed: () => _showSelectTripDialog(context),
            ),
            // ── Upload Photos ──
            CtaCard(
              icon: Icons.cloud_upload_outlined,
              title: 'Upload Photos',
              description: 'Save your favorite moments from your trips.',
              buttonLabel: '↑  Upload Now',
              isOutlined: true,
              imageUrls: const [
                'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=200',
                'https://images.unsplash.com/photo-1508193638397-1c4234db14d8?w=200',
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200',
              ],
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadScreen()),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
