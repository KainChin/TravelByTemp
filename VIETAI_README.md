# VietAI Travel — Full Stack

Hệ thống gợi ý du lịch AI-assisted với **PostgreSQL + pgvector**, **MongoDB**, **Ollama** (self-hosted LLM), **Docker Compose**, **3 role**, **CI/CD**.

## Kiến trúc

| Thành phần | Công nghệ | Vai trò |
|------------|-----------|---------|
| PostgreSQL + pgvector | `pgvector/pgvector:pg16` | Users, roles, destinations, schedules, vector embeddings |
| MongoDB | `mongo:7` | AI prompts, raw/parsed responses, weather snapshots, logs |
| Ollama | `ollama/ollama` | `llama3.1:8b` (chat) + `nomic-embed-text` (embedding) |
| Backend | ASP.NET Core 8 | API, JWT, vector search, AI flow |
| Frontend web | React + Vite | Portal đăng nhập, explore, AI planner |
| Flutter app | `lib/` (root) | Mobile UI đã tích hợp API (`10.0.2.2:5000` trên Android emulator) |

## Khởi chạy

```bash
# 1. Build & chạy toàn bộ stack
docker compose up -d --build

# 2. Pull model Ollama (lần đầu, ~4–8 GB)
docker exec vietai_ollama ollama pull nomic-embed-text
docker exec vietai_ollama ollama pull llama3.1:8b

# 3. Truy cập
# - Frontend: http://localhost:3000
# - API Swagger: http://localhost:5000/swagger
# - PostgreSQL: localhost:5432
# - MongoDB: localhost:27017
```

## Tài khoản mẫu (seed khi backend khởi động)

| Role | Username | Password |
|------|----------|----------|
| Admin | admin | Admin@123 |
| TravelManager | manager | Manager@123 |
| Traveler | traveler | Traveler@123 |

## Flow AI Recommendation

1. Traveler đăng nhập → gửi `POST /api/ai/recommend` với tọa độ, ngân sách, sở thích.
2. Backend gọi **Open-Meteo** (weather, không cần API key).
3. Tạo embedding query qua **Ollama** → tìm địa điểm bằng **cosine similarity** (pgvector).
4. Build prompt → **Ollama chat** (JSON) → lưu `schedules` + `schedule_destinations` (Postgres) + `ai_recommendation_logs` (Mongo).

## API chính

- `POST /api/auth/login` · `POST /api/auth/register`
- `GET /api/destinations`
- `POST /api/ai/recommend` (Traveler)
- `GET /api/schedules`
- `POST /api/manager/destinations` (TravelManager)
- `POST /api/manager/destinations/{id}/regenerate-embedding`
- `GET /api/admin/users` (Admin)

## CI/CD

GitHub Actions: `.github/workflows/ci-cd.yml` — build/test backend, build frontend, `docker compose build`, deploy placeholder trên `main`.

## Báo cáo đồ án

Đoạn mô tả kiến trúc (PostgreSQL hybrid, MongoDB logs, self-hosted LLM, Docker, 3 role, CI/CD) nằm trong spec project — có thể copy từ mục **9. ĐOẠN ĐƯA VÀO BÁO CÁO** trong đề bài.
