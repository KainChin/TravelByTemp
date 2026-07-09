# TravelByTemp 🌍✈️

**TravelByTemp** là một dự án cá nhân (Personal Project) cung cấp ứng dụng du lịch thông minh, giúp người dùng tự động lập kế hoạch và quản lý lịch trình bằng sức mạnh của Trí tuệ nhân tạo (AI). Ứng dụng hỗ trợ lên lịch trình tự động, phân tích tuyến đường tối ưu, dự báo thời tiết và lưu giữ kỷ niệm chuyến đi.

---

## 🚀 Tính năng nổi bật

- **🗺️ Lên lịch trình bằng AI**: Tích hợp nhiều mô hình ngôn ngữ lớn (LLM) như **Gemini, OpenAI, Groq, Ollama** để phân tích yêu cầu người dùng, thời tiết và tạo lịch trình phù hợp tự động.
- **🌤️ Tích hợp Thời tiết (Open-Meteo)**: Phân tích điều kiện thời tiết thực tế để đưa ra gợi ý và thay đổi các hoạt động ngoài trời/trong nhà cho phù hợp.
- **📍 Phân tích & Tối ưu tuyến đường**: Sử dụng **Google Maps API** để tính toán khoảng cách, thời gian di chuyển, tối ưu lộ trình trong ngày và vẽ bản đồ trực quan.
- **📸 Kỷ niệm & Story (Tích hợp Firebase)**: Người dùng có thể tải ảnh lên (`base64`) để lưu trữ kỷ niệm từng chuyến đi và xem lại như một slideshow (Story/Video).
- **🔒 Quản lý Tài khoản & Bảo mật**: Authentication với JWT cho backend và **Firebase Auth** + **Firestore** cho frontend (Story/Media).

---

## 🛠️ Kiến trúc & Công nghệ

### 1. Frontend (Mobile App)
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Bản đồ**: `flutter_map` kết hợp Leaflet (OpenStreetMap) và Google Maps.
- **Firebase**:
  - `firebase_auth`: Hỗ trợ đăng nhập/đăng ký.
  - `cloud_firestore`: **Lưu trữ dữ liệu ảnh** (base64) và meta-data cho tính năng tạo Kỷ niệm / Story.
- **Quản lý State & Dependency**: `provider`, custom Scopes (`VietaiScope`).

### 2. Backend (API Server)
- **Framework**: [.NET 8](https://dotnet.microsoft.com/) (C# 12) - ASP.NET Core Web API.
- **Cơ sở dữ liệu**: PostgreSQL (kết hợp Entity Framework Core).
- **AI Orchestration**: Flexible Services hỗ trợ nhiều LLM (Gemini, ChatGPT, Groq, local Ollama) fallback qua lại nếu có lỗi.
- **External Services**:
  - `Open-Meteo`: API lấy dữ liệu thời tiết.
  - `Google Maps`: Matrix API / Directions API.
  - `SerpApi`: Tìm kiếm hình ảnh điểm đến.

---

## 💡 Giải đáp thắc mắc về hệ thống

**1. Vai trò của Firebase trong dự án là gì?**
- Firebase trong dự án được dùng chủ yếu để hỗ trợ **Authentication** (xác thực người dùng) và **Firestore** để lưu trữ các thông tin NoSQL linh hoạt, đặc biệt là hình ảnh của người dùng.

**2. Tính năng upload ảnh tạo Story có sử dụng Firebase không?**
- **Có, hoàn toàn sử dụng Firebase.** Khi bạn upload ảnh trong tính năng Kỷ niệm (Story), ứng dụng sẽ chuyển ảnh thành dạng chuỗi `base64` và lưu vào **Cloud Firestore** theo cấu trúc: `users/{uid}/trips/{tripId}/photos`. Khi xem lại, ứng dụng lấy danh sách ảnh này từ Firestore và hiển thị slideshow (VideoPreviewScreen).

---

## 💻 Hướng dẫn chạy dự án

### Yêu cầu
- Flutter SDK (>= 3.0)
- .NET 8 SDK
- PostgreSQL Server (Đang chạy)
- Thiết lập biến môi trường API Keys (Google Maps, Gemini, Groq, SerpApi)

### Chạy Backend
```bash
cd backend/VietAITravel.Api
dotnet restore
dotnet ef database update # (Nếu có migration)
dotnet run
```

### Chạy Frontend
```bash
flutter pub get
flutter run
```

---

## 📝 Bản quyền & Đóng góp
Dự án được phát triển dưới dạng **Personal Project**. Mọi logic cốt lõi như thuật toán phân tích AI, chia tách Services (Partial classes) và Flutter UI component architecture đã được tối ưu cho hiệu năng và khả năng bảo trì.
