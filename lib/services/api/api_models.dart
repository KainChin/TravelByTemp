// ignore_for_file: use_string_in_part_of_directives
part of api_client;

class WeatherSnapshot {
  const WeatherSnapshot({required this.temperatureC, required this.description});
  final double temperatureC;
  final String description;
}

class AiRecommendResult {
  AiRecommendResult({
    required this.scheduleId,
    required this.title,
    required this.summary,
    required this.currentTemperature,
    required this.currentWeatherDescription,
    required this.recommendedDestinations,
    required this.dailyPlan,
  });

  final String scheduleId;
  final String title;
  final String summary;
  final double currentTemperature;
  final String currentWeatherDescription;
  final List<AiRecommendedDest> recommendedDestinations;
  final List<AiDailyPlan> dailyPlan;

  factory AiRecommendResult.fromJson(Map<String, dynamic> json) {
    return AiRecommendResult(
      scheduleId: json['scheduleId'] as String,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      currentTemperature: (json['currentTemperature'] as num?)?.toDouble() ?? 0,
      currentWeatherDescription:
          json['currentWeatherDescription'] as String? ?? '',
      recommendedDestinations: (json['recommendedDestinations'] as List? ?? [])
          .map((e) => AiRecommendedDest.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyPlan: (json['dailyPlan'] as List? ?? [])
          .map((e) => AiDailyPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AiRecommendedDest {
  AiRecommendedDest({
    required this.destinationId,
    required this.name,
    required this.reason,
    required this.weatherFit,
  });

  final String destinationId;
  final String name;
  final String reason;
  final String weatherFit;

  factory AiRecommendedDest.fromJson(Map<String, dynamic> json) => AiRecommendedDest(
        destinationId: json['destinationId'] as String,
        name: json['name'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        weatherFit: json['weatherFit'] as String? ?? '',
      );
}

class AiDailyPlan {
  AiDailyPlan({required this.day, required this.items});
  final int day;
  final List<AiDailyPlanItem> items;

  factory AiDailyPlan.fromJson(Map<String, dynamic> json) => AiDailyPlan(
        day: json['day'] as int? ?? 1,
        items: (json['items'] as List? ?? [])
            .map((e) => AiDailyPlanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AiDailyPlanItem {
  AiDailyPlanItem({
    required this.destinationId,
    required this.time,
    required this.activity,
    this.note,
  });

  final String destinationId;
  final String time;
  final String activity;
  final String? note;

  factory AiDailyPlanItem.fromJson(Map<String, dynamic> json) => AiDailyPlanItem(
        destinationId: json['destinationId'] as String,
        time: json['time'] as String? ?? '',
        activity: json['activity'] as String? ?? '',
        note: json['note'] as String?,
      );
}

class ScheduleSummary {
  ScheduleSummary({
    required this.id,
    required this.title,
    required this.totalDays,
    required this.budgetInput,
    required this.preferenceInput,
    required this.userLocationName,
    required this.currentTemperature,
    required this.currentWeatherDescription,
    required this.generatedAt,
  });

  final String id;
  final String title;
  final int totalDays;
  final double budgetInput;
  final String? preferenceInput;
  final String? userLocationName;
  final double? currentTemperature;
  final String? currentWeatherDescription;
  final DateTime generatedAt;

  factory ScheduleSummary.fromJson(Map<String, dynamic> json) {
    return ScheduleSummary(
      id: '${json['id']}',
      title: json['title'] as String? ?? 'Untitled trip',
      totalDays: json['totalDays'] as int? ?? 1,
      budgetInput: (json['budgetInput'] as num?)?.toDouble() ?? 0,
      preferenceInput: json['preferenceInput'] as String?,
      userLocationName: json['userLocationName'] as String?,
      currentTemperature:
          (json['currentTemperature'] as num?)?.toDouble(),
      currentWeatherDescription:
          json['currentWeatherDescription'] as String?,
      generatedAt: DateTime.tryParse('${json['generatedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ScheduleDetail extends ScheduleSummary {
  ScheduleDetail({
    required super.id,
    required super.title,
    required super.totalDays,
    required super.budgetInput,
    required super.preferenceInput,
    required super.userLocationName,
    required super.currentTemperature,
    required super.currentWeatherDescription,
    required super.generatedAt,
    required this.destinations,
  });

  final List<ScheduleDestination> destinations;

  factory ScheduleDetail.fromJson(Map<String, dynamic> json) {
    return ScheduleDetail(
      id: '${json['id']}',
      title: json['title'] as String? ?? 'Untitled trip',
      totalDays: json['totalDays'] as int? ?? 1,
      budgetInput: (json['budgetInput'] as num?)?.toDouble() ?? 0,
      preferenceInput: json['preferenceInput'] as String?,
      userLocationName: json['userLocationName'] as String?,
      currentTemperature:
          (json['currentTemperature'] as num?)?.toDouble(),
      currentWeatherDescription:
          json['currentWeatherDescription'] as String?,
      generatedAt: DateTime.tryParse('${json['generatedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      destinations: (json['destinations'] as List? ?? [])
          .map((e) => ScheduleDestination.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ScheduleDestination {
  ScheduleDestination({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.province,
    required this.imageUrl,
    required this.dayNumber,
    required this.orderInDay,
    required this.note,
    required this.estimatedTime,
  });

  final String id;
  final String destinationId;
  final String destinationName;
  final String province;
  final String? imageUrl;
  final int dayNumber;
  final int orderInDay;
  final String? note;
  final String? estimatedTime;

  factory ScheduleDestination.fromJson(Map<String, dynamic> json) {
    return ScheduleDestination(
      id: '${json['id']}',
      destinationId: '${json['destinationId']}',
      destinationName: json['destinationName'] as String? ?? '',
      province: json['province'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      dayNumber: json['dayNumber'] as int? ?? 1,
      orderInDay: json['orderInDay'] as int? ?? 1,
      note: json['note'] as String?,
      estimatedTime: json['estimatedTime'] as String?,
    );
  }
}

class Comment {
  Comment({
    required this.id,
    required this.destinationId,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.rating,
    required this.content,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String destinationId;
  final String userId;
  final String username;
  final String fullName;
  final int rating;
  final String? content;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: '${json['id']}',
      destinationId: '${json['destinationId']}',
      userId: '${json['userId']}',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      content: json['content'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: DateTime.tryParse('${json['createdAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse('${json['updatedAt']}'),
    );
  }
}

class FavoriteDestination {
  FavoriteDestination({
    required this.id,
    required this.savedAt,
    required this.destination,
  });

  final String id;
  final DateTime savedAt;
  final Destination destination;

  factory FavoriteDestination.fromJson(Map<String, dynamic> json) {
    return FavoriteDestination(
      id: '${json['id']}',
      savedAt: DateTime.tryParse('${json['savedAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      destination: Destination.fromApi(
        json['destination'] as Map<String, dynamic>,
      ).copyWith(isFavorite: true),
    );
  }
}
