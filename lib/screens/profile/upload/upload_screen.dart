// ignore_for_file: unnecessary_library_name
library upload_screen;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:assignment/core/widgets/safe_memory_image.dart';
import 'package:assignment/services/firestore_service.dart';
import 'upload_service.dart';

part 'upload_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _tripNameCtrl = TextEditingController();
  List<XFile> _selectedImages = [];
  bool _isUploading = false;
  int _uploadProgress = 0;
  String? _selectedTripId;
  String? _selectedTripName;

  @override
  void dispose() {
    _tripNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await UploadService.pickImages();
    if (images.isNotEmpty) setState(() => _selectedImages = images);
  }

  // -- Bottom sheet: chọn trip có sẵn HOẶC tạo mới --
  Future<void> _showTripPicker() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn chuyến đi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            // ── Nút tạo trip mới --
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF3A7D5A),
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Tạo chuyến đi mới',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showCreateTripDialog();
              },
            ),
            const Divider(),
            // -- Danh sách trip có sẵn --
            StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.getTrips(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Chưa có chuyến đi nào',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final isSelected = docs[i].id == _selectedTripId;
                    return ListTile(
                      leading: const Icon(Icons.luggage_outlined,
                          color: Color(0xFF3A7D5A)),
                      title: Text(data['name'] ?? ''),
                      subtitle: Text('${data['photoCount'] ?? 0} ảnh'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                          color: Color(0xFF3A7D5A))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedTripId = docs[i].id;
                          _selectedTripName = data['name'] ?? '';
                        });
                        Navigator.pop(context);
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

  // -- Dialog tạo trip mới --
  Future<void> _showCreateTripDialog() async {
    _tripNameCtrl.clear();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tên chuyến đi mới'),
        content: TextField(
          controller: _tripNameCtrl,
          decoration: const InputDecoration(hintText: 'VD: Đà Nẵng 2024'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A7D5A)),
            onPressed: () async {
              if (_tripNameCtrl.text.trim().isEmpty) return;
              final id = await FirestoreService.createTrip(
                  _tripNameCtrl.text.trim());
              setState(() {
                _selectedTripId = id;
                _selectedTripName = _tripNameCtrl.text.trim();
              });
              if (mounted) Navigator.pop(context);
            },
            child:
            const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImages() async {
    if (_selectedTripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng chọn hoặc tạo chuyến đi trước!')));
      return;
    }
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    await UploadService.uploadMultiplePhotos(
      files: _selectedImages,
      tripId: _selectedTripId!,
      onProgress: (current, total) =>
          setState(() => _uploadProgress = (current / total * 100).round()),
    );

    setState(() {
      _isUploading = false;
      _selectedImages = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Đã upload lên chuyến "$_selectedTripName"!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text('Upload Ảnh',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripSelector(),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty) _buildPreviewGrid(),
            const SizedBox(height: 16),
            if (_isUploading) _buildProgressBar(),
            if (!_isUploading && _selectedImages.isNotEmpty)
              _buildUploadButton(),
          ],
        ),
      ),
    );
  }
}
