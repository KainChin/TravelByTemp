import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GroqService {
  static const _apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'YOUR_GROQ_API_KEY_HERE');
  static const _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Analyzes the route and budget, returning AI badges and a recommendation
  static Future<Map<String, dynamic>> analyzeRouteBudget({
    required double totalDistanceKm,
    required double optimizedHours,
    required double estimatedCostVnd,
    required double budgetVnd,
    required int transferCount,
    required String destinationsName,
  }) async {
    try {
      final prompt = '''
Bạn là Động cơ Phân tích Phương tiện & Ngân sách (AI Transportation & Budget Planning Engine) cho ứng dụng du lịch Việt Nam.
Nhiệm vụ của bạn là phân tích thông tin lộ trình và ngân sách chuyến đi đến $destinationsName dưới góc nhìn của một tư vấn viên du lịch chuyên nghiệp, am hiểu thực tế.

Thông tin chuyến đi:
- Lộ trình đi qua: $destinationsName
- Khoảng cách di chuyển: ${totalDistanceKm.toStringAsFixed(0)} km
- Thời gian di chuyển: ${optimizedHours.toStringAsFixed(1)} giờ
- Chi phí di chuyển dự kiến: ${estimatedCostVnd.toStringAsFixed(0)} VND
- Tổng ngân sách nhóm: ${budgetVnd.toStringAsFixed(0)} VND
- Số lần chuyển phương tiện: $transferCount

Yêu cầu phân tích:
1. Đánh giá tính thực tế của ngân sách (Chi phí di chuyển chiếm bao nhiêu %, số tiền còn lại có đủ chi tiêu ăn uống, ngủ nghỉ không).
2. Đưa ra lời khuyên di chuyển thông thái, an toàn và tối ưu (phân bổ ngân sách, mẹo đặt vé, lưu ý chặng đi).
3. Luôn ưu tiên an toàn hơn tiện lợi, và thời tiết/thực tế hơn tốc độ.

Trả về kết quả ĐÚNG định dạng JSON sau (không chứa code block hay ký tự markdown nào khác):
{
  "aiBadges": ["AI đề xuất", "Chiến lược di chuyển (vd: Tiết kiệm nhất/Nhanh nhất/Cân bằng)", "Độ thuận tiện (vd: Độ thuận tiện: Cao/Trung bình/Thấp)"],
  "aiRecommendation": "Đoạn phân tích và lời khuyên ngắn gọn, thực tế bằng tiếng Việt (khoảng 3-4 câu, tối đa 70 từ)."
}
''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.5,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        debugPrint('Groq API Error: ${response.statusCode} - ${response.body}');
        return _fallbackData(estimatedCostVnd, budgetVnd);
      }
    } catch (e) {
      debugPrint('Groq Service Exception: $e');
      return _fallbackData(estimatedCostVnd, budgetVnd);
    }
  }

  static Map<String, dynamic> _fallbackData(double cost, double budget) {
    return {
      "aiBadges": ["AI đề xuất", "Cân bằng thời gian và chi phí", "Độ thuận tiện: Trung bình"],
      "aiRecommendation": "Phương tiện và ngân sách đã được tính toán dựa trên mức trung bình."
    };
  }
}
