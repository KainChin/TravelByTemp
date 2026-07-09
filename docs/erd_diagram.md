# Entity-Relationship Diagram (ERD)

Dưới đây là sơ đồ thực thể liên kết (ERD) cốt lõi của hệ thống **TravelByTemp** dựa trên cấu trúc Database (PostgreSQL qua Entity Framework Core). Sơ đồ tập trung vào các domain chính: **Authentication/User**, **Destinations**, **AI Itineraries & Routes**, và **Transport**.

```mermaid
erDiagram
    users {
        int id PK
        string username
        string email
        string password_hash
        int role_id FK
        datetime created_at
    }

    roles {
        int id PK
        string name
        string permissions_json
    }

    refresh_tokens {
        int id PK
        int user_id FK
        string token
        datetime expires_at
    }

    destinations {
        int id PK
        string name
        string region
        string province
        string category
        decimal rating
        float latitude
        float longitude
    }

    gallery_images {
        int id PK
        int destination_id FK
        string image_url
    }

    comments {
        int id PK
        int user_id FK
        int destination_id FK
        decimal rating
        string content
    }

    user_favorites {
        int id PK
        int user_id FK
        int destination_id FK
    }

    ai_itineraries {
        int id PK
        int user_id FK
        string title
        jsonb request_json
        jsonb itinerary_json
        string ai_model
        datetime created_at
    }

    trip_routes {
        int id PK
        int user_id FK
        string departure_name
        float departure_latitude
        float departure_longitude
        float total_distance_km
        float optimized_hours
    }

    trip_route_legs {
        int id PK
        int trip_route_id FK
        int leg_order
        string from_name
        string to_name
        float distance_km
        float duration_hours
    }

    transport_hubs {
        int id PK
        string code
        string name
        string type
        string region
    }

    transport_routes {
        int id PK
        int origin_hub_id FK
        int destination_hub_id FK
        string transport_type
        float estimated_duration_hours
        decimal estimated_cost_vnd
    }

    user_travel_memories {
        int id PK
        int user_id FK
        jsonb preferred_styles_json
        int trip_count
    }

    %% Relationships
    roles ||--o{ users : "has"
    users ||--o{ refresh_tokens : "owns"
    users ||--o{ comments : "writes"
    users ||--o{ user_favorites : "likes"
    users ||--o{ ai_itineraries : "generates"
    users ||--o{ trip_routes : "plans"
    users ||--|| user_travel_memories : "has profile"

    destinations ||--o{ gallery_images : "has photos"
    destinations ||--o{ comments : "receives"
    destinations ||--o{ user_favorites : "is liked in"

    trip_routes ||--o{ trip_route_legs : "contains"

    transport_hubs ||--o{ transport_routes : "is origin"
    transport_hubs ||--o{ transport_routes : "is destination"
```

### Chú thích các khối chính:
1. **User & Auth**: Bảng `users`, `roles`, và `refresh_tokens` dùng để xác thực và phân quyền.
2. **Core Content**: Bảng `destinations`, `gallery_images`, `comments`, `user_favorites` lưu trữ danh mục điểm đến và tương tác cộng đồng.
3. **AI Planning**: `ai_itineraries`, `trip_routes`, `trip_route_legs` lưu trữ các lịch trình sinh ra bằng AI, bao gồm các chặng di chuyển (legs) được tối ưu bằng Google Maps.
4. **Transport**: Bảng `transport_hubs` (sân bay, bến xe) và `transport_routes` hỗ trợ tính toán lộ trình di chuyển liên tỉnh/vùng.

*(Lưu ý: Storage của Firestore chứa các hình ảnh Story sẽ liên kết logic qua `uid` của user, không thể hiện trực tiếp trong CSDL SQL này).*
