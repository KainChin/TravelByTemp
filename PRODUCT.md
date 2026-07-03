# VietAI Travel — Product

## Register

product

## Users

Du khách Việt Nam và người nước ngoài muốn lên kế hoạch du lịch trong nước với gợi ý AI, bản đồ, thời tiết và đặt tour. Dev team dùng Cursor để phát triển Flutter app + ASP.NET API nhất quán về UI.

## Product Purpose

Ứng dụng du lịch AI-assisted: khám phá điểm đến, lập lịch trình, chat AI, quản lý booking theo role (Traveler / Manager / Admin). Thành công khi người dùng tạo được hành trình phù hợp ngân sách & thời tiết, và giao diện đáng tin cậy — không “AI slop”.

## Brand Personality

Ấm áp, rõ ràng, địa phương hóa (tiếng Việt). Chuyên nghiệp nhưng thân thiện — gợi cảm giác companion du lịch, không corporate lạnh.

## Anti-references

- Gradient tím–xanh generic SaaS, Inter mặc định khắp nơi
- Card lồng card, shadow nặng, bounce easing
- Copy tiếng Anh cứng nhắc trên UI tiếng Việt
- Pure black (#000) thay vì ink tối có chiều sâu

## Design Principles

1. **Một nguồn sự thật** — `design-rules/DESIGN.md` là canonical; `npm run design:sync` sau khi sửa tokens.
2. **Flutter tokens** — `lib/core/theme/app_colors.dart` phải align với DESIGN.md (màu brand `#2D9F75`).
3. **Detector là lưới an toàn** — `npm run impeccable:detect` trước khi merge UI lớn.
4. **Mobile-first** — thumb zones, contrast AA, loading states rõ ràng.
5. **API-driven** — không mock data trên màn production; lỗi mạng hiển thị thân thiện.

## Accessibility & Inclusion

WCAG 2.1 AA. Contrast 4.5:1 cho body text. `prefers-reduced-motion` cho animation. Hỗ trợ tiếng Việt + English qua `LocaleScope`.
