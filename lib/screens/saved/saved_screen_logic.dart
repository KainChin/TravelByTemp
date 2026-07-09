part of saved_screen;

extension SavedScreenLogic on _SavedScreenState {
  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = VietaiScope.of(context).auth?.accessToken;
      final service = TripItineraryService(authToken: token);
      final results = await Future.wait([
        VietaiScope.of(context).api.fetchFavorites(),
        service.history(),
        SavedItineraryStore.load(),
      ]);
      if (!mounted) return;
      final remoteItineraries = (results[1] as List<TripItineraryHistoryItem>)
          .map((item) => SavedItineraryItem(
                id: item.id,
                title: item.title,
                savedAt: item.createdAt,
                itinerary: item.itinerary,
              ))
          .toList();
      final localItineraries = results[2] as List<SavedItineraryItem>;
      setState(() {
        _favorites = results[0] as List<FavoriteDestination>;
        _itineraries = _mergeItineraries(remoteItineraries, localItineraries);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SavedItineraryItem> _mergeItineraries(
    List<SavedItineraryItem> remote,
    List<SavedItineraryItem> local,
  ) {
    // Remote items are the source of truth. Local-only items are kept as
    // offline fallbacks (created while server was unreachable).
    final byId = <String, SavedItineraryItem>{};
    for (final item in local) {
      byId[item.id] = item;
    }
    for (final item in remote) {
      byId[item.id] = item;
    }
    final items = byId.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  Future<void> _removeItinerary(SavedItineraryItem item) async {
    try {
    await _removeRemoteItinerary(item.id);
    await SavedItineraryStore.remove(item.id);
    if (!mounted) return;
    setState(() => _itineraries.removeWhere((saved) => saved.id == item.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa ${item.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    } catch (error, stackTrace) {
      debugPrint('[Saved] Could not remove itinerary ${item.id}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _removeRemoteItinerary(String id) async {
    try {
      final token = VietaiScope.of(context).auth?.accessToken;
      await TripItineraryService(authToken: token).deleteItinerary(id);
    } catch (error, stackTrace) {
      debugPrint('[Saved] Could not delete remote itinerary $id: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _remove(FavoriteDestination item) async {
    try {
      await VietaiScope.of(context).api.deleteFavorite(item.destination.id);
      if (!mounted) return;
      setState(() => _favorites.removeWhere((favorite) => favorite.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${item.destination.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _openItinerary(SavedItineraryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedTripDetailScreen(item: item),
      ),
    ).then((_) => _load()); // reload if deleted inside detail
  }

  void _openFavorite(FavoriteDestination item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationDetailScreen(destination: item.destination),
      ),
    );
  }

  Future<void> _renameItinerary(SavedItineraryItem item) async {
    final token = VietaiScope.of(context).auth?.accessToken;
    final controller = TextEditingController(text: item.title);
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên hành trình'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên hành trình mới',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF16A34A)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu', style: TextStyle(color: Color(0xFF16A34A))),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (nextName != null && nextName.isNotEmpty && nextName != item.title) {
      final map = {
        ...item.itinerary,
        'title': nextName,
        'id': item.id,
      };
      try {
        await TripItineraryService(authToken: token).saveItinerary(
          itineraryId: item.id,
          itinerary: map,
        );
      } catch (error, stackTrace) {
        debugPrint('[Saved] Could not rename remote itinerary ${item.id}: $error');
        debugPrintStack(stackTrace: stackTrace);
        await SavedItineraryStore.remove(item.id);
        await SavedItineraryStore.save(map);
      }
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đổi tên thành "$nextName"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cloneItinerary(SavedItineraryItem item) async {
    final clonedTitle = '${item.title} (Bản sao)';
    final clonedId = '${item.id}-copy-${DateTime.now().millisecondsSinceEpoch}';
    final map = {
      ...item.itinerary,
      'title': clonedTitle,
      'id': clonedId,
    };
    try {
      final token = VietaiScope.of(context).auth?.accessToken;
      final saved = await TripItineraryService(authToken: token).saveItinerary(
        itinerary: map,
      );
      await SavedItineraryStore.save({
        ...saved.itinerary,
        'id': saved.id,
        'title': saved.title,
      });
    } catch (error, stackTrace) {
      debugPrint('[Saved] Could not clone itinerary remotely: $error');
      debugPrintStack(stackTrace: stackTrace);
      await SavedItineraryStore.save(map);
    }
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép hành trình thành công!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _buildShareText(SavedItineraryItem item) {
    final days = item.itinerary['days'];
    final dests = <String>{};
    var dayCount = 0;
    var activityCount = 0;
    if (days is List) {
      dayCount = days.length;
      for (final day in days) {
        if (day is Map) {
          final activities = day['activities'] ?? day['schedule'];
          if (activities is List) {
            activityCount += activities.length;
            for (final a in activities) {
              if (a is Map) {
                final name = (a['destination'] ?? a['placeName'] ?? '').toString().trim();
                if (name.isNotEmpty && name.toLowerCase() != 'null') dests.add(name);
              }
            }
          }
        }
      }
    }
    final route = dests.isEmpty
        ? 'điểm đến đã chọn'
        : dests.take(5).join(' → ');
    final summary = item.itinerary['summary']?.toString().trim();
    final buffer = StringBuffer()
      ..writeln('🌏 Hành trình: ${item.title}')
      ..writeln('🗺️  Lộ trình: $route')
      ..writeln('📅 $dayCount ngày • $activityCount hoạt động');
    if (summary != null && summary.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(summary);
    }
    buffer
      ..writeln()
      ..writeln('— Lưu bởi VietAI Travel');
    return buffer.toString();
  }

  void _shareItinerary(SavedItineraryItem item) {
    final text = _buildShareText(item);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép nội dung chia sẻ vào bộ nhớ tạm.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportItineraryPdf(SavedItineraryItem item) async {
    // No PDF dependency in this project — export the same shareable text
    // so the user can paste it into Google Docs / Word and print to PDF
    // from there. Honest placeholder, not a fake success toast.
    final text = _buildShareText(item);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Đã sao chép hành trình dạng văn bản — dán vào Word/Docs để xuất PDF.',
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  List<SavedItineraryItem> get _filteredItineraries {
    final query = _searchQuery.toLowerCase().trim();
    if (query.isEmpty) return _itineraries;
    return _itineraries.where((item) {
      final title = item.title.toLowerCase();
      final summary =
          (item.itinerary['summary'] ?? '').toString().toLowerCase();
      // Include activity destinations so users can search "phú quốc" etc.
      final days = item.itinerary['days'];
      var places = '';
      if (days is List) {
        for (final day in days) {
          if (day is Map) {
            final acts = day['activities'] ?? day['schedule'];
            if (acts is List) {
              for (final a in acts) {
                if (a is Map) {
                  places += ' ${a['destination'] ?? a['placeName'] ?? ''}';
                }
              }
            }
          }
        }
      }
      final haystack = '$title $summary $places'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<FavoriteDestination> get _filteredFavorites {
    final query = _searchQuery.toLowerCase().trim();
    if (query.isEmpty) return _favorites;
    return _favorites.where((item) {
      final d = item.destination;
      final haystack = [
        d.name,
        d.location ?? '',
        d.tagline,
        d.description,
        d.category,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  int get _totalItineraryDays {
    var total = 0;
    for (final item in _itineraries) {
      final days = item.itinerary['days'];
      if (days is List) total += days.length;
    }
    return total;
  }

  int get _totalItineraryActivities {
    var total = 0;
    for (final item in _itineraries) {
      final days = item.itinerary['days'];
      if (days is List) {
        for (final day in days) {
          if (day is Map) {
            final acts = day['activities'] ?? day['schedule'];
            if (acts is List) total += acts.length;
          }
        }
      }
    }
    return total;
  }

  void _goHome() {
    if (widget.onHomePressed != null) {
      widget.onHomePressed!();
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

}

