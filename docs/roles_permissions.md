# Ma trận Phân quyền & Vai trò (Roles & Permissions Matrix)

Hệ thống **TravelByTemp** quản lý việc truy cập và các chức năng thông qua phân quyền dựa trên vai trò (Role-Based Access Control - RBAC). Dưới đây là ma trận phân quyền mô tả chi tiết các nhóm đối tượng người dùng và quyền hạn tương ứng.

## 1. Các Vai trò (Roles) trong Hệ thống

| Tên Role | Mô tả Vai trò |
| :--- | :--- |
| **Guest** (Khách) | Người dùng chưa đăng nhập, sử dụng ứng dụng ở chế độ đọc/khám phá cơ bản. |
| **User** (Người dùng) | Người dùng đã đăng nhập (sở hữu tài khoản Auth qua JWT). Sử dụng toàn bộ tính năng cốt lõi (AI Planning, Lưu kỷ niệm, vv). |
| **Admin** (Quản trị) | Quản trị viên hệ thống. Có quyền truy cập vào Backend Admin Panel hoặc thao tác trực tiếp với Database để kiểm duyệt nội dung và quản lý user. |

---

## 2. Ma trận Phân quyền Chi tiết (Permissions Matrix)

Dưới đây là bảng phân quyền đối với các module chính trong dự án.
Quy ước: 
- ❌: Không có quyền (Denied)
- ✅: Có quyền (Granted)
- 👤: Chỉ thao tác được trên dữ liệu của chính mình (Self-Owned Data)

| Phân hệ (Module) | Thao tác (Action) | Guest | User | Admin |
| :--- | :--- | :---: | :---: | :---: |
| **Authentication** | Đăng ký / Đăng nhập | ✅ | ❌ | ❌ |
| | Đổi mật khẩu / Đăng xuất | ❌ | 👤 | ✅ |
| **AI Itinerary** (Lịch trình AI) | Sinh lịch trình mới bằng AI | ❌ | ✅ | ✅ |
| | Xem lịch trình | ❌ | 👤 | ✅ |
| | Sửa / Xóa lịch trình đã lưu | ❌ | 👤 | ✅ |
| | Clone / Share lịch trình | ❌ | 👤 | ✅ |
| **Destination** (Điểm đến) | Xem thông tin điểm đến & Map | ✅ | ✅ | ✅ |
| | Thích / Lưu điểm đến (Favorites)| ❌ | ✅ | ✅ |
| | Viết Comment / Rating | ❌ | ✅ | ✅ |
| | Thêm / Sửa / Xóa Điểm đến | ❌ | ❌ | ✅ |
| | Phê duyệt / Ẩn Comment | ❌ | ❌ | ✅ |
| **Memories / Story** (Kỷ niệm) | Upload ảnh mới & Tạo Story | ❌ | 👤 | ✅ |
| | Xem Slideshow / Video | ❌ | 👤 | ✅ |
| | Xóa ảnh / Story | ❌ | 👤 | ✅ |
| **System Settings** | Cấu hình API LLM keys | ❌ | ❌ | ✅ |
| | Sửa bảng giá Transport | ❌ | ❌ | ✅ |

---

## 3. Quản lý Token & Auth Flow
- **Người dùng (User)** đăng nhập nhận được **Access Token (JWT)** (sống ngắn hạn) và **Refresh Token** (lưu ở bảng `refresh_tokens`).
- Khi request tới API `.NET 8`, token được parse qua Middleware để trích xuất `user_id` và `role_id`.
- Chức năng liên quan tới Firebase Firestore (Story) sử dụng `uid` đồng bộ hoặc Custom Token Firebase để đảm bảo người dùng chỉ được quyền ghi đè (Write) vào sub-collection `users/{uid}/*` của chính mình (Firebase Security Rules).
