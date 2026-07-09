part of saved_screen;



extension SavedScreenBuilders on _SavedScreenState {
  Widget _buildLoading() {
    return const SizedBox(
      height: 260,
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
      ),
    );
  }

  Widget _buildError() {
    return _MessageCard(
      icon: Icons.cloud_off_rounded,
      title: 'Chưa tải được danh sách đã lưu',
      subtitle: 'Kiểm tra kết nối và kéo xuống để tải lại dữ liệu.',
      actionLabel: 'Thử lại',
      onPressed: _load,
    );
  }

  Widget _buildEmptyState() {
    return _MessageCard(
      icon: Icons.favorite_border_rounded,
      title: 'Bạn chưa lưu hành trình nào',
      subtitle: 'Hãy tạo hoặc lưu hành trình đầu tiên để AI có thể hỗ trợ bạn nhanh hơn.',
      actionLabel: 'Tạo hành trình',
      onPressed: _goHome,
    );
  }

  Widget _buildItinerarySection() {
    final showInlineSuggestion = MediaQuery.of(context).size.width < 1024;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showInlineSuggestion) ...[
          _AISuggestionCard(
            trips: _itineraries.length,
            places: _favorites.length,
          ),
          const SizedBox(height: 20),
        ],
        const _SectionTitle(
          title: 'Hành trình đã lưu',
          icon: Icons.map_rounded,
        ),
        const SizedBox(height: 12),
        if (_filteredItineraries.isEmpty && _searchQuery.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Không tìm thấy hành trình phù hợp',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
          )
        else
          ..._filteredItineraries.map(
            (item) => _ItineraryCard(
              item: item,
              onOpen: () => _openItinerary(item),
              onRename: () => _renameItinerary(item),
              onClone: () => _cloneItinerary(item),
              onShare: () => _shareItinerary(item),
              onExportPdf: () => _exportItineraryPdf(item),
              onRemove: () => _removeItinerary(item),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Địa điểm yêu thích',
          icon: Icons.favorite_border_rounded,
        ),
        const SizedBox(height: 12),
        if (_filteredFavorites.isEmpty && _searchQuery.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Không tìm thấy địa điểm phù hợp',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
          )
        else
          ..._filteredFavorites.map(
            (item) => _FavoriteCard(
              favorite: item,
              onOpen: () => _openFavorite(item),
              onRemove: () => _remove(item),
            ),
          ),
      ],
    );
  }

  Widget _buildSavedBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_favorites.isEmpty && _itineraries.isEmpty) return _buildEmptyState();
    return Column(
      children: [
        if (_itineraries.isNotEmpty) _buildItinerarySection(),
        if (_favorites.isNotEmpty) _buildFavoritesSection(),
      ],
    );
  }

  Widget _buildSavedSidebar() {
    return Column(
      children: [
        _AISuggestionCard(
          trips: _itineraries.length,
          places: _favorites.length,
        ),
        const SizedBox(height: 16),
        _SavedDashboardPanel(
          trips: _itineraries.length,
          places: _favorites.length,
        ),
        const SizedBox(height: 16),
        const _SavedInsightPanel(),
      ],
    );
  }


}


