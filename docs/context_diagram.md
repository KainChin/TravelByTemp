# Context Diagram (C4 Model - Level 1)

Sơ đồ ngữ cảnh (Context Diagram) mô tả các tương tác cấp cao nhất giữa Hệ thống TravelByTemp, Người dùng (Traveller), và các hệ thống/Dịch vụ bên ngoài.

```mermaid
C4Context
    title System Context diagram for TravelByTemp

    Person(traveller, "Traveller", "Người dùng ứng dụng di động tìm kiếm điểm đến và lên kế hoạch du lịch tự động.")
    
    System(travelByTemp, "TravelByTemp System", "Nền tảng chính cho phép người dùng tạo lịch trình AI, xem bản đồ, xem thời tiết, và lưu giữ kỷ niệm (Story).")

    System_Ext(gemini, "Gemini / Groq / OpenAI", "Cung cấp LLM API để sinh ra lịch trình du lịch dựa trên ngữ cảnh và điểm đến.")
    System_Ext(googleMaps, "Google Maps API", "Cung cấp tọa độ địa lý (Geocoding), khoảng cách (Distance Matrix) và điều hướng lộ trình (Directions).")
    System_Ext(openMeteo, "Open-Meteo", "Cung cấp dữ liệu dự báo thời tiết tại điểm đến để tối ưu các hoạt động ngoài trời.")
    System_Ext(serpApi, "SerpApi", "Tìm kiếm và tải về hình ảnh các địa điểm du lịch động.")
    System_Ext(firebase, "Firebase Auth & Firestore", "Dịch vụ xác thực phía frontend (nếu dùng Social Login) và lưu trữ dữ liệu ảnh (base64) cho Story Kỷ niệm.")

    Rel(traveller, travelByTemp, "Sử dụng ứng dụng (Tạo lịch trình, xem bản đồ, tạo kỷ niệm)", "HTTPS / Mobile App")
    
    Rel(travelByTemp, gemini, "Gửi prompt và bối cảnh (Context), nhận lại JSON lịch trình chi tiết", "HTTPS / REST")
    Rel(travelByTemp, googleMaps, "Gửi tọa độ, nhận lại khoảng cách và thời gian tối ưu giữa các điểm", "HTTPS / REST")
    Rel(travelByTemp, openMeteo, "Lấy dự báo thời tiết thực tế để lọc/điều chỉnh các điểm đến", "HTTPS / REST")
    Rel(travelByTemp, serpApi, "Lấy hình ảnh minh họa cho các địa điểm", "HTTPS / REST")
    Rel(travelByTemp, firebase, "Lưu trữ và đồng bộ hóa hình ảnh Kỷ niệm", "Firebase SDK")
    
    UpdateElementStyle(traveller, $fontColor="white", $bgColor="#08427b", $borderColor="#073b6f")
    UpdateElementStyle(travelByTemp, $fontColor="white", $bgColor="#1168bd", $borderColor="#0b4884")
    UpdateElementStyle(gemini, $fontColor="white", $bgColor="#999999", $borderColor="#666666")
    UpdateElementStyle(googleMaps, $fontColor="white", $bgColor="#999999", $borderColor="#666666")
    UpdateElementStyle(openMeteo, $fontColor="white", $bgColor="#999999", $borderColor="#666666")
    UpdateElementStyle(serpApi, $fontColor="white", $bgColor="#999999", $borderColor="#666666")
    UpdateElementStyle(firebase, $fontColor="black", $bgColor="#FFCA28", $borderColor="#FFA000")
```

### Chú thích:
- **TravelByTemp System**: Hệ thống trung tâm (Bao gồm Flutter App và .NET 8 Backend + PostgreSQL).
- **External Systems** (Màu xám/vàng): Các hệ thống của bên thứ 3 (Google Maps, Open-Meteo, LLMs API, Firebase) tích hợp vào hệ thống qua REST/SDK.
- **Luồng dữ liệu**: Người dùng thao tác trên Mobile App, Mobile App gọi đến Backend (hoặc Firebase trực tiếp để tải ảnh), Backend điều phối tới các External Services để trả về kết quả cuối cùng.
