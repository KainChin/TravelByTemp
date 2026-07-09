# VietAI Travel (TravelByTemp) 🌴✈️

> **Ứng dụng du lịch ứng dụng Trí tuệ Nhân tạo (AI)** giúp người dùng Việt Nam và du khách quốc tế khám phá điểm đến, lập lịch trình thông minh, tính toán chi phí di chuyển và quản lý chuyến đi một cách dễ dàng nhất.

![VietAI Travel](assets/images/1.jpg)

## 🌟 Tính năng nổi bật (Core Features)

1. **AI Smart Itinerary (Lập lịch trình bằng AI):**
   - Tự động tạo lịch trình đa dạng, **không lặp lại địa điểm** giữa các ngày.
   - **Tối ưu hóa lộ trình địa lý** để tránh di chuyển vòng vèo, nhóm các địa điểm gần nhau vào cùng một buổi.
   - **Cân đối ngân sách (Thu liễm ngân sách):** Tự động đề xuất ăn uống vỉa hè nếu ngân sách hẹp, hoặc resort/hải sản cao cấp nếu ngân sách dư dả sau khi trừ tiền vé xe.
   
2. **AI Vision Chatbot:**
   - Trợ lý AI tích hợp khả năng đọc hiểu hình ảnh. Bạn có thể tải lên ảnh danh sách địa điểm hoặc poster du lịch, AI sẽ phân tích và lập kế hoạch ngay lập tức.
   
3. **Groq Cost Estimation & Route Analysis:**
   - Phân tích tuyến đường, quãng đường và thời gian di chuyển.
   - Động cơ ước tính chi phí di chuyển siêu tốc được hỗ trợ bởi Groq AI.
   
4. **Premium Dashboard:**
   - Cung cấp cái nhìn tổng quan về thời tiết điểm đến.
   - Thống kê chuyến đi, các điểm đến yêu thích và hiển thị linh hoạt (Dynamic Sidebar).

## 🛠️ Công nghệ sử dụng (Tech Stack)

### Frontend (Mobile App)
- **Framework:** Flutter / Dart
- **Design:** Tuân thủ chuẩn WCAG 2.1 AA, thiết kế riêng biệt thân thiện, ấm áp, đậm chất du lịch địa phương (Tránh UI chung chung của các app SaaS).

### Backend (Server)
- **Framework:** ASP.NET Core 8.0 Web API (C#)
- **AI Integration:** Semantic Kernel, Ollama (Local AI), Groq Cloud API.
- **Database:**
  - **PostgreSQL (+ PGVector):** Lưu trữ dữ liệu cấu trúc và vector tìm kiếm.
  - **MongoDB:** Lưu trữ dữ liệu phi cấu trúc, log và thông tin linh hoạt.
- **Containerization:** Docker & Docker Compose (cho việc triển khai 1-click toàn bộ stack DB, API và Ollama).

## 🚀 Hướng dẫn chạy dự án (Getting Started)

### 1. Khởi động Backend (Docker)
Để chạy toàn bộ hệ thống API và Database, bạn chỉ cần sử dụng Docker:
```bash
docker-compose -f docker-compose.yml up -d --build
```
Hệ thống sẽ tự động khởi tạo:
- Backend Container (`vietai_backend`)
- PostgreSQL (`vietai_postgres`)
- MongoDB (`vietai_mongodb`)
- Ollama Server (`vietai_ollama`)

### 2. Khởi động Frontend (Flutter)
Mở terminal tại thư mục gốc, cài đặt các package và chạy ứng dụng:
```bash
flutter pub get
flutter run
```

## 🔒 Biến môi trường (Environment Variables)
Đừng quên cấu hình các API Key quan trọng:
- `GROQ_API_KEY`: Dùng cho dịch vụ phân tích ngân sách siêu tốc (chạy command `--dart-define=GROQ_API_KEY=YOUR_KEY`).
- Các biến database connection strings trong file `docker-compose.yml` hoặc `.env`.

## 🎨 Thiết kế (Design Principles)
- **Màu sắc chủ đạo:** Xanh Brand `#2D9F75`.
- **Trải nghiệm:** Mobile-first, font chữ dễ đọc, hỗ trợ đa ngôn ngữ (Tiếng Việt/English).
- **Quy tắc:** Không sử dụng màu đen thuần (`#000`), thay vào đó là tone màu "ink" để tạo chiều sâu UI.
- API-driven: Không mock data cứng trên production.

## 🧑‍💻 Tác giả & Đóng góp (Author & Contributions)
Dự án được cá nhân hóa và phát triển tính năng bởi **Trình Khánh (KainChin)**.
Các tính năng nổi bật được tôi trực tiếp phát triển:
- **Tối ưu hóa Thuật toán AI:** Thiết kế hệ thống Prompt thu liễm ngân sách và định tuyến địa lý chống trùng lặp.
- **Tích hợp Groq AI:** Xây dựng hệ thống ước tính chi phí di chuyển siêu tốc.
- **Premium Dashboard UI:** Thiết kế lại toàn bộ giao diện Trang chủ với API thời tiết và thống kê trực quan.

---
*Dự án được xây dựng với mục tiêu mang lại trải nghiệm du lịch trọn vẹn, không ảo giác (no AI hallucination) và tính ứng dụng thực tế cao nhất cho du khách.*
