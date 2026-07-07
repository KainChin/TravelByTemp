import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignment/core/widgets/safe_memory_image.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/services/firestore_service.dart';
import 'package:assignment/screens/profile/upload/upload_screen.dart';
import 'package:assignment/screens/profile/video/select_photos_screen.dart';
import 'package:assignment/screens/profile/memories_screen.dart';
import 'widgets/profile_header.dart';
import 'widgets/stats_card.dart';
import 'widgets/my_trips_section.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.refreshToken,
  });

  final int refreshToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _profileLoading = false;
  String? _profileError;
  bool _profileLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileLoaded) return;
    _profileLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshProfile();
    });
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshProfile();
      });
    }
  }

  Future<void> _refreshProfile() async {
    final session = VietaiScope.of(context);
    if (session.auth == null) return;

    setState(() {
      _profileLoading = true;
      _profileError = null;
    });

    try {
      await session.refreshProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _profileError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _profileLoading = false);
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final session = VietaiScope.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất khỏi tài khoản này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await WidgetsBinding.instance.endOfFrame;
        if (!context.mounted) return;
        await session.logout();
      } catch (error, stackTrace) {
        debugPrint('[Profile] Logout failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  void _shareProfile(BuildContext context) {
    final user = VietaiScope.of(context).auth?.user;
    final name = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : user?.username ?? 'Traveler';
    final text = 'VietAI Travel profile: $name';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép thông tin hồ sơ.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openUpload(BuildContext context) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadScreen()),
      );
      if (!context.mounted) return;
      _refreshProfile();
    } catch (error, stackTrace) {
      debugPrint('[Profile] Could not open upload flow: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _showSelectTripDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2540),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn chuyến đi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
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
                        'Chưa có chuyến đi nào!\nHãy tải ảnh lên trước.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
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
                      leading: const Icon(Icons.luggage_outlined, color: Color(0xFF4CAF7A)),
                      title: Text(data['name'] ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${data['photoCount'] ?? 0} ảnh', style: const TextStyle(color: Colors.white54)),
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

  // ── Kỷ niệm của tôi (Story) ──
  Widget _buildMemoriesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF243050), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined, color: Color(0xFF4CAF7A), size: 20),
              const SizedBox(width: 6),
              const Text(
                'Kỷ niệm của tôi (Story)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemoriesScreen()),
                ),
                child: const Row(children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4CAF7A), fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFF4CAF7A)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Story circles
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.getVideos(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              return SizedBox(
                height: 98,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.isEmpty ? 1 : docs.length + 1,
                  itemBuilder: (_, i) {
                    // First item: "Thêm mới"
                    if (i == 0) {
                      return GestureDetector(
                        onTap: () => _openUpload(context),
                        child: Container(
                          width: 68,
                          margin: const EdgeInsets.only(right: 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF243050),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF3A7D5A),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.add, color: Color(0xFF4CAF7A), size: 26),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Thêm mới',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Story items
                    final data = docs[i - 1].data() as Map<String, dynamic>;
                    final thumbnail = data['thumbnail'] as String? ?? '';
                    final name = data['videoName'] as String? ?? '';

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MemoriesScreen()),
                      ),
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Story ring
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF3A7D5A), Color(0xFF4CAF7A)],
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A2540),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: thumbnail.isNotEmpty
                                      ? SafeBase64Image(
                                          base64: thumbnail,
                                          source: 'ProfileScreen video thumbnail',
                                          width: 54,
                                          height: 54,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 54,
                                          height: 54,
                                          color: const Color(0xFF243050),
                                          child: const Icon(Icons.photo, color: Colors.white38),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
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

  // ── Tính năng nhanh ──
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.auto_stories_outlined, 'Tạo story\nmới', const Color(0xFF4CAF7A)),
      (Icons.cloud_upload_outlined, 'Tải ảnh\nlên', const Color(0xFF9C88FF)),
      (Icons.video_library_outlined, 'Tạo video\ndu lịch', const Color(0xFFEF5350)),
      (Icons.add_location_alt_outlined, 'Thêm\nchuyến đi', const Color(0xFF4CAF7A)),
      (Icons.star_border_rounded, 'Đánh giá\nđiểm đến', const Color(0xFFFFB74D)),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF243050), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tính năng nhanh',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((a) {
              final (icon, label, color) = a;
              return GestureDetector(
                onTap: () {
                  if (label.contains('Tải ảnh')) {
                    _openUpload(context);
                  } else if (label.contains('video')) {
                    _showSelectTripDialog(context);
                  } else if (label.contains('story')) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoriesScreen()));
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      width: 60,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
      backgroundColor: const Color(0xFF0F1729),
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
              avatarUrl: user?.avatarUrl,
              onLogoutTap: () => _confirmLogout(context),
              onShareTap: () => _shareProfile(context),
              onAvatarTap: () => _openUpload(context),
              onEditTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ).then((_) => _refreshProfile()),
            ),
            // ── API status ──
            if (_profileLoading || _profileError != null)
              _ProfileApiStatus(
                loading: _profileLoading,
                error: _profileError,
                onRetry: _refreshProfile,
              ),
            // ── Stats ──
            StatsCard(refreshToken: widget.refreshToken),
            // ── Kỷ niệm ──
            _buildMemoriesSection(context),
            // ── Chuyến đi ──
            MyTripsSection(refreshToken: widget.refreshToken),
            // ── Tính năng nhanh ──
            _buildQuickActions(context),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _ProfileApiStatus extends StatelessWidget {
  const _ProfileApiStatus({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: LinearProgressIndicator(
          minHeight: 2,
          color: Color(0xFF4CAF7A),
          backgroundColor: Color(0xFF243050),
        ),
      );
    }

    final message = error;
    if (message == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2800),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFFFFB74D)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Không thể làm mới hồ sơ từ server.',
              style: TextStyle(
                color: Color(0xFFFFCC80),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại', style: TextStyle(color: Color(0xFFFFB74D))),
          ),
        ],
      ),
    );
  }
}
