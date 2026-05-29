import 'package:assignment/models/destination.dart';

/// Gợi ý điểm đến dựa trên chênh lệch nhiệt độ so với vị trí người dùng.
class TemperatureDestinationService {
  const TemperatureDestinationService();

  /// Nếu đang nóng → ưu tiên nơi mát hơn; nếu lạnh → nơi ấm hơn.
  List<Destination> recommend({
    required double userTempC,
    required List<Destination> all,
    int limit = 6,
  }) {
    final scored = all.map((d) {
      final diff = (userTempC - d.avgTempC).abs();
      double score;

      if (userTempC >= 30) {
        // Nóng: ưu tiên điểm mát hơn nhiều
        score = d.avgTempC < userTempC
            ? (userTempC - d.avgTempC) * 2 + (10 - diff)
            : -diff;
      } else if (userTempC <= 22) {
        // Mát/lạnh: ưu tiên điểm ấm hơn
        score = d.avgTempC > userTempC
            ? (d.avgTempC - userTempC) * 2 + (10 - diff)
            : -diff;
      } else {
        // Vừa phải: ưu tiên khí hậu gần hoặc đa dạng
        score = 10 - diff + _climateBonus(userTempC, d.climate);
      }

      return MapEntry(d, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  double _climateBonus(double userTemp, DestinationClimate climate) {
    if (userTemp >= 30) {
      return switch (climate) {
        DestinationClimate.cool => 4,
        DestinationClimate.cold => 5,
        DestinationClimate.warm => 1,
        DestinationClimate.hot => -2,
      };
    }
    if (userTemp <= 22) {
      return switch (climate) {
        DestinationClimate.hot => 4,
        DestinationClimate.warm => 5,
        DestinationClimate.cool => 1,
        DestinationClimate.cold => -2,
      };
    }
    return 2;
  }

  String recommendationMessage(double userTempC, String location) {
    if (userTempC >= 30) {
      return 'Trời $location đang ${userTempC.toStringAsFixed(0)}°C — gợi ý điểm mát hơn cho bạn';
    }
    if (userTempC <= 22) {
      return 'Trời $location ${userTempC.toStringAsFixed(0)}°C — gợi ý điểm ấm áp hơn';
    }
    return 'Nhiệt độ ${userTempC.toStringAsFixed(0)}°C tại $location — điểm đến phù hợp';
  }
}
