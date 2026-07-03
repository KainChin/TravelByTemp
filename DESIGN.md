---
version: alpha
name: VietAI Travel
description: Warm, trustworthy travel companion for Vietnam — mobile-first.
colors:
  primary: "#1A1A1A"
  secondary: "#757575"
  tertiary: "#2D9F75"
  tertiary-dark: "#2D8B69"
  neutral: "#F5F7F5"
  surface: "#FFFFFF"
  on-primary: "#FFFFFF"
  on-tertiary: "#FFFFFF"
  on-surface: "#1A1A1A"
  border: "#E8E8E8"
typography:
  h1:
    fontFamily: Public Sans
    fontSize: 1.25rem
    fontWeight: "700"
    lineHeight: 1.2
  body-md:
    fontFamily: Public Sans
    fontSize: 1rem
    fontWeight: "400"
    lineHeight: 1.5
  label-caps:
    fontFamily: Space Grotesk
    fontSize: 0.6875rem
    fontWeight: "600"
    lineHeight: 1
    letterSpacing: 0.05em
rounded:
  sm: 8px
  md: 12px
  lg: 16px
spacing:
  sm: 8px
  md: 16px
  lg: 24px
components:
  button-primary:
    backgroundColor: "{colors.tertiary}"
    textColor: "{colors.on-tertiary}"
    rounded: "{rounded.md}"
    padding: 14px 16px
    typography: "{typography.body-md}"
  button-primary-hover:
    backgroundColor: "{colors.tertiary-dark}"
    textColor: "{colors.on-tertiary}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: 16px
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.md}"
    padding: 12px 16px
    typography: "{typography.body-md}"
---

## Overview

VietAI Travel UI kết hợp sự ấm áp của du lịch Việt Nam với clarity của công cụ lập lịch. Nền limestone nhạt, accent xanh lá brand, typography dễ đọc trên mobile.

## Colors

- **Primary (#1A1A1A):** Tiêu đề, text chính.
- **Secondary (#757575):** Metadata, caption, hint.
- **Tertiary (#2D9F75):** CTA, tab active, link — map tới `AppColors.primary` trong Flutter.
- **Tertiary dark (#2D8B69):** Hover / pressed state.
- **Neutral (#F5F7F5):** Scaffold background (Explore, Trips).
- **Surface (#FFFFFF):** Card, input, bottom nav.
- **Border (#E8E8E8):** Divider, outline nhẹ.

## Typography

- **Headlines:** Public Sans Bold — section title, trip names.
- **Body:** Public Sans 16px — mô tả, form.
- **Labels:** Space Grotesk caps — tab bar, chips.

## Layout

- Screen padding ngang: 16px.
- Bottom nav safe area + elevation nhẹ.
- Map sections: min height 220px, radius 16px.

## Elevation & Depth

- Tránh shadow đậm; dùng border `#E8E8E8` hoặc elevation 1–2.
- Không card trong card.

## Shapes

- Button & input: 12px radius.
- Card lớn: 16px.
- Avatar / icon container: 10–12px.

## Components

- Primary button: full-width trên mobile khi CTA chính.
- Search bar: icon trái, clear khi có text.
- Weather banner: gradient nhẹ từ tertiary, text trắng.

## Do's and Don'ts

**Do:** Dùng token colors; loading overlay có message tiếng Việt; fit API errors qua `friendlyApiError`.

**Don't:** Gradient tím marketing; hardcode màu ngoài `app_colors.dart` / DESIGN.md; `withOpacity` — dùng `withValues(alpha:)`.
