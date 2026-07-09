# Biểu đồ Tuần tự (Sequence Diagrams)

Tài liệu này bao gồm các biểu đồ tuần tự (Sequence Diagram) minh họa luồng xử lý của 3 nghiệp vụ quan trọng nhất trong hệ thống **TravelByTemp**.

---

## 1. Luồng Lập Kế hoạch Bằng AI (AI Planning Flow)
Mô tả quá trình người dùng yêu cầu tạo lịch trình, Backend xử lý fallback qua nhiều LLM và tối ưu lộ trình bằng Google Maps.

```mermaid
sequenceDiagram
    autonumber
    actor User as Traveller (App)
    participant Backend as .NET 8 Backend
    participant TravelChatService as AI Service (Backend)
    participant RouteService as Route Service (Backend)
    participant LLM as LLMs (Gemini/Groq)
    participant GMaps as Google Maps API
    participant DB as PostgreSQL

    User->>Backend: POST /api/chat/itinerary (Prompt, Days, Location)
    Backend->>TravelChatService: Build Context & Prompt
    
    TravelChatService->>LLM: Request Itinerary Generation (Gemini)
    alt Gemini Success
        LLM-->>TravelChatService: JSON Itinerary
    else Gemini Fails or Rate Limit
        TravelChatService->>LLM: Fallback to Groq/OpenAI
        LLM-->>TravelChatService: JSON Itinerary
    end

    TravelChatService->>RouteService: Optimize Routes (Itinerary JSON)
    RouteService->>GMaps: Get Distance Matrix & Geocoding
    GMaps-->>RouteService: Distance, Duration, Coordinates
    RouteService-->>TravelChatService: Optimized Itinerary + Route Legs

    TravelChatService->>DB: Lưn (Save) AI Itinerary & Routes
    DB-->>TravelChatService: Itinerary ID
    TravelChatService-->>Backend: Final Output (JSON)
    Backend-->>User: 200 OK (Itinerary Display)
```

---

## 2. Luồng Xác Thực (Login & Auth Flow)
Mô tả quá trình người dùng đăng nhập bằng hệ thống nội bộ để nhận JWT Token.

```mermaid
sequenceDiagram
    autonumber
    actor User as Traveller (App)
    participant AuthUI as Login Screen
    participant AuthProvider as VietaiScope
    participant Backend as .NET 8 Auth API
    participant DB as PostgreSQL

    User->>AuthUI: Nhập Username/Email + Password
    AuthUI->>AuthProvider: Call login(credentials)
    AuthProvider->>Backend: POST /api/auth/login
    Backend->>DB: Lấy User Hash & So sánh
    alt Hợp lệ (Valid)
        DB-->>Backend: User Data
        Backend->>Backend: Generate JWT Access & Refresh Token
        Backend->>DB: Save Refresh Token
        Backend-->>AuthProvider: 200 OK (Tokens, User Info)
        AuthProvider->>AuthUI: Save Token to Local Storage
        AuthUI-->>User: Đăng nhập thành công, chuyển hướng Home
    else Không hợp lệ (Invalid)
        Backend-->>AuthProvider: 401 Unauthorized
        AuthProvider-->>AuthUI: Exception
        AuthUI-->>User: Hiển thị lỗi (Sai mật khẩu)
    end
```

---

## 3. Luồng Tải lên Kỷ niệm / Story (Story Upload Flow)
Mô tả cách thức ứng dụng nén ảnh thành Base64 và lưu trực tiếp lên Firebase Firestore để tối ưu backend chính.

```mermaid
sequenceDiagram
    autonumber
    actor User as Traveller (App)
    participant Picker as Image Picker (App)
    participant Firebase as Cloud Firestore
    participant Backend as .NET 8 Backend (Optional sync)

    User->>Picker: Mở Bộ sưu tập (Gallery)
    Picker-->>User: Chọn danh sách ảnh chuyến đi
    User->>Picker: Nhấn "Tạo Kỷ niệm (Story)"
    
    rect rgb(230, 240, 255)
        Note right of Picker: Xử lý phía Client
        Picker->>Picker: Resize & Compress Images
        Picker->>Picker: Encode to Base64 Strings
    end

    Picker->>Firebase: batch.set(users/{uid}/trips/{tripId}/photos/{id})
    Firebase-->>Picker: Trả về thành công (Upload Success)
    
    opt Nếu cần đồng bộ trạng thái
        Picker->>Backend: POST /api/users/memory (Update Trip Count)
        Backend-->>Picker: 200 OK
    end

    Picker-->>User: Bắt đầu phát Video/Slideshow Kỷ niệm (Story)
```
