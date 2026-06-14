import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Nếu dùng máy thật (điện thoại thật): đổi thành IP máy tính của bạn
  // Nếu dùng emulator Android: dùng 10.0.2.2
  //static const String _baseUrl = 'http://10.0.2.2:11434';
  //static const String _baseUrl = 'http://10.0.2.2';
  static const _baseUrl = 'http://localhost:11434';
  static const String _model = 'gemma3:4b';
  static const String _systemPrompt = '''
Bạn là trợ lý du lịch Việt Nam thông minh tên là TravelAI.
Nhiệm vụ của bạn:
- Gợi ý địa điểm du lịch phù hợp theo sở thích và ngân sách
- Lập lịch trình chi tiết theo ngày
- Tư vấn chuẩn bị hành lý theo điểm đến và mùa
- Gợi ý ẩm thực đặc sản, chỗ lưu trú, phương tiện di chuyển
- Ước tính chi phí chuyến đi
Luôn trả lời bằng tiếng Việt, ngắn gọn, thân thiện và có cấu trúc rõ ràng.
''';

  Future<String> sendMessage(List<Map<String, String>> history) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...history,
          ],
          'stream': false,
          'options': {
            'num_predict': 512,
            'temperature': 0.3,
            'num_ctx': 1024,    // giảm context window (mặc định 2048)
            'num_thread': 7,
          },
        }),
      ).timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'] ?? 'Xin lỗi, tôi không hiểu câu hỏi này.';
      } else {
        return 'Lỗi kết nối: ${response.statusCode}';
      }
    } catch (e) {
      return 'Không thể kết nối đến AI. Hãy kiểm tra Ollama đang chạy chưa.\nLỗi: $e';
    }
  }
}
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class AiService {
//   static const _baseUrl = 'http://localhost:11434'; // emulator
//   static const String _model = 'gemma3:4b'; // nhẹ hơn 4b rất nhiều
//   static const String _systemPrompt =
//       'Bạn là trợ lý du lịch Việt Nam tên TravelAI. '
//       'Trả lời ngắn gọn, có cấu trúc, bằng tiếng Việt.';
//
//   Future<String> sendMessage(List<Map<String, String>> history) async {
//     // Chỉ giữ 6 tin nhắn gần nhất để giảm tải
//     final recentHistory =
//     history.length > 6 ? history.sublist(history.length - 6) : history;
//
//     try {
//       final response = await http
//           .post(
//         Uri.parse('$_baseUrl/api/chat'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'model': _model,
//           'messages': [
//             {'role': 'system', 'content': _systemPrompt},
//             ...recentHistory,
//           ],
//           'stream': false,
//           'options': {
//             'num_predict': 256, // đủ dùng, không quá dài
//             'temperature': 0.3,
//             'num_ctx': 1024,
//             'num_thread': 7,
//           },
//         }),
//       )
//           .timeout(const Duration(seconds: 180));
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['message']['content'] ??
//             'Xin lỗi, tôi không hiểu câu hỏi này.';
//       } else {
//         return 'Lỗi kết nối: ${response.statusCode}';
//       }
//     } catch (e) {
//       return 'Không thể kết nối đến AI.\nLỗi: $e';
//     }
//   }
// }