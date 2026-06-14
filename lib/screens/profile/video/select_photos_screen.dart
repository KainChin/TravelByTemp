import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignment/services/firestore_service.dart';
import 'video_preview_screen.dart';

class SelectPhotosScreen extends StatefulWidget {
  final String tripId;
  final String tripName;

  const SelectPhotosScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<SelectPhotosScreen> createState() => _SelectPhotosScreenState();
}

class _SelectPhotosScreenState extends State<SelectPhotosScreen> {
  final Set<String> _selectedIds = {};
  final Map<String, Map<String, dynamic>> _photoData = {};

  void _toggleSelect(String id) {
    setState(() {
      _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    });
  }

  void _goToPreview() {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất 1 ảnh!')),
      );
      return;
    }

    // Lấy base64 của các ảnh đã chọn theo thứ tự
    final selectedPhotos = _selectedIds
        .where((id) => _photoData.containsKey(id))
        .map((id) => {
      'id': id,
      'base64': _photoData[id]!['base64'] as String,
      'fileName': _photoData[id]!['fileName'] as String,
    })
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPreviewScreen(
          tripId: widget.tripId,
          tripName: widget.tripName,
          photos: selectedPhotos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text(widget.tripName, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _goToPreview,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7D5A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Tạo video (${_selectedIds.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getPhotos(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3A7D5A)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Chưa có ảnh nào', style: TextStyle(color: Colors.grey)),
                  Text('Upload ảnh trước nhé!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          // Cache photo data
          for (final doc in docs) {
            _photoData[doc.id] = doc.data() as Map<String, dynamic>;
          }

          return Column(
            children: [
              // Header chọn tất cả
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text('${docs.length} ảnh', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedIds.length == docs.length
                            ? _selectedIds.clear()
                            : _selectedIds.addAll(docs.map((d) => d.id));
                      }),
                      child: Text(
                        _selectedIds.length == docs.length ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                        style: const TextStyle(color: Color(0xFF3A7D5A)),
                      ),
                    ),
                  ],
                ),
              ),
              // Grid ảnh
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final isSelected = _selectedIds.contains(doc.id);
                    final bytes = base64Decode(data['base64'] as String);

                    return GestureDetector(
                      onTap: () => _toggleSelect(doc.id),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(bytes, fit: BoxFit.cover),
                          ),
                          // Overlay khi chọn
                          if (isSelected)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: const Color(0xFF3A7D5A).withOpacity(0.4),
                                child: const Center(
                                  child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                                ),
                              ),
                            ),
                          // Số thứ tự
                          if (isSelected)
                            Positioned(
                              top: 6, right: 6,
                              child: Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3A7D5A),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_selectedIds.toList().indexOf(doc.id) + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}