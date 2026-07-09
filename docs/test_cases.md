# Bộ Kịch bản Kiểm thử (Test Cases)

Dưới đây là tập hợp các kịch bản kiểm thử (Test Cases) được sinh ra để kiểm tra độ ổn định và logic cốt lõi của hệ thống **TravelByTemp**, đặc biệt tập trung vào quá trình lên lịch trình bằng AI (AI Planning) và Xác thực (Authentication).

---

## 1. Module: Lên lịch trình tự động bằng AI (AI Itinerary Planning)

| Mã TC | Tiêu đề (Title) | Điều kiện tiên quyết (Preconditions) | Các bước thực hiện (Steps) | Kết quả mong đợi (Expected Result) |
| :--- | :--- | :--- | :--- | :--- |
| **TC_AI_01** | Tạo lịch trình thành công với Gemini | Đã đăng nhập, chọn địa điểm "Đà Lạt", "3 ngày" | 1. Nhập prompt: "Tôi muốn đi Đà Lạt 3 ngày, ưu tiên cafe view đẹp".<br>2. Nhấn "Tạo lịch trình". | Trả về JSON hợp lệ gồm danh sách hoạt động 3 ngày, được tối ưu khoảng cách. UI vẽ bản đồ chính xác. |
| **TC_AI_02** | Fallback khi Gemini bị lỗi (Rate Limit) | Đã đăng nhập, ép Mock Gemini trả về 429 (Too Many Requests). | 1. Nhấn "Tạo lịch trình".<br>2. Theo dõi log backend. | Backend tự động chuyển sang Groq hoặc OpenAI để sinh kết quả mà không văng lỗi (Crash) trên App. Người dùng vẫn nhận được lịch trình. |
| **TC_AI_03** | Xử lý khi AI sinh ra JSON lỗi định dạng | Đã đăng nhập, ép Mock AI trả về chuỗi text thay vì JSON. | 1. Gọi API sinh lịch trình.<br>2. Backend parse JSON. | Backend sử dụng Fallback Parsing hoặc Yêu cầu AI sửa lỗi. Trả về thông báo lỗi thân thiện thay vì sập hệ thống (Internal Server Error). |
| **TC_AI_04** | Tối ưu hóa Route qua Google Maps | Đã sinh xong JSON thô từ AI. | 1. Backend trích xuất danh sách địa điểm.<br>2. Gọi Google Maps Distance Matrix. | Backend tự sắp xếp lại thứ tự điểm đến trong ngày sao cho khoảng cách di chuyển là ngắn nhất. Thêm thông tin `duration` và `distance` vào mỗi Leg. |

---

## 2. Module: Xác thực & Tài khoản (Authentication)

| Mã TC | Tiêu đề (Title) | Điều kiện tiên quyết (Preconditions) | Các bước thực hiện (Steps) | Kết quả mong đợi (Expected Result) |
| :--- | :--- | :--- | :--- | :--- |
| **TC_AUTH_01** | Đăng nhập thành công với tài khoản đúng | Tồn tại user `traveler123` / pass `123456`. | 1. Nhập username, password.<br>2. Bấm "Đăng nhập". | Đăng nhập thành công, App lưu trữ JWT Access Token. Chuyển sang màn hình Home. |
| **TC_AUTH_02** | Đăng nhập thất bại do sai mật khẩu | Tồn tại user `traveler123`. | 1. Nhập `traveler123` và pass sai.<br>2. Bấm "Đăng nhập". | App hiển thị cảnh báo "Sai tài khoản hoặc mật khẩu". KHÔNG tiết lộ là sai username hay sai password để tránh dò pass. |
| **TC_AUTH_03** | Làm mới Token (Refresh Token) | Đã đăng nhập, Access Token vừa hết hạn. | 1. Thực hiện 1 request (VD: Lấy lịch sử).<br>2. Middleware trả về 401. | Interceptor phía Mobile App tự động gọi `/api/auth/refresh`, lấy Access Token mới và gửi lại request ban đầu một cách vô hình với người dùng. |

---

## 3. Module: Kỷ niệm & Story (Firebase Storage)

| Mã TC | Tiêu đề (Title) | Điều kiện tiên quyết (Preconditions) | Các bước thực hiện (Steps) | Kết quả mong đợi (Expected Result) |
| :--- | :--- | :--- | :--- | :--- |
| **TC_STORY_01** | Tải ảnh lên và lưu dạng Base64 | Đã đăng nhập, có ảnh trong máy. | 1. Chọn 3 tấm ảnh chuyến đi.<br>2. Nhấn "Tạo Story". | Ảnh được resize, encode thành Base64 và lưu thành công vào Firestore `users/{uid}/trips/...`. App hiển thị Slideshow ngay lập tức. |
| **TC_STORY_02** | Lỗi dung lượng ảnh quá lớn | Firestore giới hạn 1MB/document. | 1. Chọn 1 tấm ảnh dung lượng 20MB (không nén).<br>2. Gửi lưu. | Trình nén ảnh (Compressor) phía Flutter hoạt động, ép dung lượng xuống < 1MB trước khi gửi. Nếu vẫn lớn, báo lỗi "Ảnh quá lớn". |
| **TC_STORY_03** | Quyền riêng tư (Security Rules) | Lấy trực tiếp `uid` của người khác. | 1. Giả mạo payload cố gắng ghi vào `users/{nguoi_khac}/...` thông qua Firebase REST API. | Firebase Security Rules từ chối (Permission Denied). Chỉ chính chủ mới được lưu ảnh. |
