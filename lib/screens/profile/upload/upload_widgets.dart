// ignore_for_file: use_string_in_part_of_directives
part of upload_screen;

extension _UploadScreenStateWidgets on _UploadScreenState {
  Widget _buildTripSelector() {
    return GestureDetector(
      onTap: _showTripPicker, // ← mở bottom sheet thay vì chỉ tạo mới
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.luggage_outlined, color: Color(0xFF3A7D5A)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTripName ?? 'Chọn hoặc tạo chuyến đi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _selectedTripName != null
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A7D5A)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 36, color: Color(0xFF3A7D5A)),
              SizedBox(height: 8),
              Text('Chọn ảnh từ máy tính',
                  style: TextStyle(
                      color: Color(0xFF3A7D5A),
                      fontWeight: FontWeight.w600)),
              Text('Hỗ trợ JPG, PNG',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_selectedImages.length} ảnh đã chọn',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
          itemCount: _selectedImages.length,
          itemBuilder: (_, i) => FutureBuilder<String>(
            future: UploadService.toBase64(_selectedImages[i]),
            builder: (_, snap) {
              if (!snap.hasData) {
                return Container(color: Colors.grey[200]);
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SafeBase64Image(
                  base64: snap.data,
                  source: 'Upload preview ${_selectedImages[i].name}',
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Text('Đang upload... $_uploadProgress%',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _uploadProgress / 100,
          backgroundColor: Colors.grey[200],
          color: const Color(0xFF3A7D5A),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _uploadImages,
        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
        label: const Text('Upload Ảnh',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3A7D5A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
