import 'package:flutter/material.dart';
import 'package:assignment/core/widgets/safe_memory_image.dart';
import 'package:assignment/services/firestore_service.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String tripId;
  final String tripName;
  final List<Map<String, dynamic>> photos;
  final bool isViewOnly; // ← thêm

  const VideoPreviewScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.photos,
    this.isViewOnly = false, // ← mặc định false
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  int _currentIndex = 0;
  bool _isSaving = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _startSlideshow() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SlideshowDialog(
          photos: widget.photos, tripName: widget.tripName),
    );
  }

  Future<void> _showSaveDialog() async {
    _nameCtrl.text = widget.tripName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đặt tên kỉ niệm',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tên này sẽ hiển thị trong My Memories',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'VD: Đà Nẵng hè 2024',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF3A7D5A)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A7D5A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _saveMemory();
  }

  Future<void> _saveMemory() async {
    final name = _nameCtrl.text.trim().isEmpty
        ? widget.tripName
        : _nameCtrl.text.trim();
    setState(() => _isSaving = true);
    try {
      await FirestoreService.saveVideoMetadata(
        tripId: widget.tripId,
        tripName: widget.tripName,
        videoName: name,
        thumbnailBase64: widget.photos.first['base64'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã lưu kỉ niệm "$name"!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: Text(widget.tripName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SafeBase64Image(
                      base64: widget.photos[i]['base64'] as String?,
                      source: 'VideoPreviewScreen page $i',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          Text('${_currentIndex + 1} / ${widget.photos.length}',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.photos.length,
              itemBuilder: (_, i) {
                final isActive = i == _currentIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 60, height: 60,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF3A7D5A)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SafeBase64Image(
                        base64: widget.photos[i]['base64'] as String?,
                        source: 'VideoPreviewScreen thumbnail $i',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startSlideshow,
                    icon: const Icon(Icons.play_circle_outline,
                        color: Colors.white),
                    label: const Text('Xem Slideshow',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                // -- ?n nút lưu khi đang xem lại từ Memories --
                if (!widget.isViewOnly) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _showSaveDialog,
                      icon: _isSaving
                          ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_outlined, color: Colors.white),
                      label: Text(_isSaving ? 'Đang lưu...' : 'Lưu kỉ niệm',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A7D5A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SlideshowDialog extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final String tripName;
  const _SlideshowDialog({required this.photos, required this.tripName});

  @override
  State<_SlideshowDialog> createState() => _SlideshowDialogState();
}

class _SlideshowDialogState extends State<_SlideshowDialog> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _nextSlide();
  }

  void _nextSlide() async {
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (_index < widget.photos.length - 1) {
      setState(() => _index++);
      _nextSlide();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: SafeBase64Image(
              base64: widget.photos[_index]['base64'] as String?,
              source: 'SlideshowDialog photo $_index',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 48, left: 16, right: 16,
            child: LinearProgressIndicator(
              value: (_index + 1) / widget.photos.length,
              backgroundColor: Colors.white24,
              color: const Color(0xFF3A7D5A),
            ),
          ),
          Positioned(
              top: 56, left: 16,
              child: Text(widget.tripName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16))),
          Positioned(
            top: 40, right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: Center(
              child: Text('${_index + 1} / ${widget.photos.length}',
                  style: const TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }
}

