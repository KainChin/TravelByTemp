// ignore_for_file: use_string_in_part_of_directives

part of route_analysis;

enum TransportMode { motorbike, car, coach, train, ferry, flight }

class TransportOption {
  const TransportOption({
    required this.mode,
    required this.isAvailable,
    required this.isRecommended,
    required this.reason,
    required this.durationHours,
    required this.estimatedCostVnd,
    this.segments = const [],
    this.aiScore = 0,
    this.pros = const [],
    this.cons = const [],
  });

  final TransportMode mode;
  final bool isAvailable;
  final bool isRecommended;
  final String reason;
  final double durationHours;
  final double estimatedCostVnd;
  final List<String> segments;
  final double aiScore;
  final List<String> pros;
  final List<String> cons;

  factory TransportOption.fromJson(Map<String, dynamic> json) {
    return TransportOption(
      mode: _modeFromApi(json['type'] as String? ??
          json['mode'] as String? ??
          json['Type'] as String? ??
          json['Mode'] as String?),
      isAvailable: json['isAvailable'] as bool? ??
          json['IsAvailable'] as bool? ??
          false,
      isRecommended: json['isRecommended'] as bool? ??
          json['IsRecommended'] as bool? ??
          false,
      reason: json['reason'] as String? ?? json['Reason'] as String? ?? '',
      durationHours: (json['estimatedDuration'] as num?)?.toDouble() ??
          (json['EstimatedDuration'] as num?)?.toDouble() ??
          (json['durationHours'] as num?)?.toDouble() ??
          (json['DurationHours'] as num?)?.toDouble() ??
          0,
      estimatedCostVnd: (json['estimatedCost'] as num?)?.toDouble() ??
          (json['EstimatedCost'] as num?)?.toDouble() ??
          (json['estimatedCostVnd'] as num?)?.toDouble() ??
          (json['EstimatedCostVnd'] as num?)?.toDouble() ??
          0,
      segments: _stringList(json['segments'] ?? json['Segments']),
      aiScore: (json['aiScore'] as num?)?.toDouble() ??
          (json['AiScore'] as num?)?.toDouble() ??
          0,
      pros: _stringList(json['pros'] ?? json['Pros']),
      cons: _stringList(json['cons'] ?? json['Cons']),
    );
  }

  TransportOption copyWith({
    TransportMode? mode,
    bool? isAvailable,
    bool? isRecommended,
    String? reason,
    double? durationHours,
    double? estimatedCostVnd,
    List<String>? segments,
    double? aiScore,
    List<String>? pros,
    List<String>? cons,
  }) {
    return TransportOption(
      mode: mode ?? this.mode,
      isAvailable: isAvailable ?? this.isAvailable,
      isRecommended: isRecommended ?? this.isRecommended,
      reason: reason ?? this.reason,
      durationHours: durationHours ?? this.durationHours,
      estimatedCostVnd: estimatedCostVnd ?? this.estimatedCostVnd,
      segments: segments ?? this.segments,
      aiScore: aiScore ?? this.aiScore,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
    );
  }
}

class RouteLeg {
  const RouteLeg({
    required this.order,
    required this.fromName,
    required this.to,
    required this.distanceKm,
    required this.recommendedMode,
    required this.reason,
    this.isGoogleEstimate = false,
    this.durationHours,
    this.estimatedCostVndOverride,
    this.transportOptions = const [],
    this.from,
  });

  final int order;
  final String fromName;
  final Destination to;
  final double distanceKm;
  final TransportMode recommendedMode;
  final String reason;
  final bool isGoogleEstimate;
  final double? durationHours;
  final double? estimatedCostVndOverride;
  final List<TransportOption> transportOptions;

  /// Toạ độ + landmass của origin. Một số chức năng (multi-leg, check
  /// availability) cần Destination chứ không chỉ tên. Có thể null khi
  /// leg được tạo từ backend không gửi origin object.
  final Destination? from;

  String get routeLabel => '$fromName -> ${to.name}';

  RouteLeg copyWith({
    int? order,
    String? fromName,
    Destination? to,
    double? distanceKm,
    TransportMode? recommendedMode,
    String? reason,
    bool? isGoogleEstimate,
    double? durationHours,
    double? estimatedCostVndOverride,
    List<TransportOption>? transportOptions,
    Destination? from,
  }) {
    return RouteLeg(
      order: order ?? this.order,
      fromName: fromName ?? this.fromName,
      to: to ?? this.to,
      distanceKm: distanceKm ?? this.distanceKm,
      recommendedMode: recommendedMode ?? this.recommendedMode,
      reason: reason ?? this.reason,
      isGoogleEstimate: isGoogleEstimate ?? this.isGoogleEstimate,
      durationHours: durationHours ?? this.durationHours,
      estimatedCostVndOverride:
          estimatedCostVndOverride ?? this.estimatedCostVndOverride,
      transportOptions: transportOptions ?? this.transportOptions,
      from: from ?? this.from,
    );
  }

  TransportOption? get selectedTransportOption {
    for (final option in transportOptions) {
      if (option.mode == recommendedMode && option.isRecommended) return option;
    }
    for (final option in transportOptions) {
      if (option.mode == recommendedMode) return option;
    }
    return null;
  }

  double get estimatedCostVnd {
    final override = estimatedCostVndOverride;
    if (override != null && override > 0) return override;

    final selectedCost = selectedTransportOption?.estimatedCostVnd ?? 0;
    if (selectedCost > 0) return selectedCost;

    for (final option in transportOptionsForLeg(this)) {
      if (option.mode == recommendedMode && option.estimatedCostVnd > 0) {
        return option.estimatedCostVnd;
      }
    }

    return _fallbackCost(distanceKm, recommendedMode);
  }

  double get recommendedHours {
    final currentDuration = durationHours ?? selectedTransportOption?.durationHours ?? 0;
    if (currentDuration > 0) return currentDuration;
    return _fallbackHours(distanceKm, recommendedMode);
  }

  int get segmentTransferCount {
    final segments = selectedTransportOption?.segments ?? const [];
    if (segments.length <= 1) return 0;
    return segments.length - 1;
  }

  bool get usesFlight => recommendedMode == TransportMode.flight;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => '$item').where((item) => item.trim().isNotEmpty).toList();
}


