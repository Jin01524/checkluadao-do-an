# CheckLuaDao

CheckLuaDao phân tích tin nhắn và ảnh nghi lừa đảo. Web và app Android dùng chung API để quét, xem kết quả và tra cứu kho mẫu.

| Thư mục | Mã nguồn |
| --- | --- |
| [web](web/) | Giao diện React, Vite và Tailwind CSS. |
| [backend](backend/) | API Node.js và Express, xử lý OCR, phân tích bằng Gemini và lưu trữ qua Supabase. |
| [app](app/) | Flutter và mã Kotlin cho bong bóng quét màn hình Android. Phiên bản 1.2.11+17. |

## Chạy từ mã nguồn

1. **Backend.** Dùng Node.js 24. Trong thư mục backend, chạy npm ci. Tạo file .env với SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, GEMINI_API_KEY và JWT_SECRET của môi trường riêng. Với cơ sở dữ liệu mới, dùng backend/supabase_schema.sql để tạo bảng. Nếu cần đăng nhập quản trị, cấu hình ADMIN_USERNAME và ADMIN_PASSWORD_HASH. Chạy npm start để mở API ở cổng 5000.
2. **Web.** Trong thư mục web, chạy npm ci rồi npm run dev. Mặc định web gọi http://localhost:5000. Để dùng API khác, đặt VITE_API_URL trong web/.env.local. Dùng npm run build để tạo bản web.
3. **Android.** Dùng Flutter 3.47.5 (Dart 3.13.4) và Android SDK. Trong thư mục app, chạy flutter pub get rồi flutter run trên thiết bị Android. Đặt --dart-define=API_BASE_URL=https://your-api.example.com nếu muốn dùng backend HTTPS riêng. Bản debug có thể chạy bằng cấu hình mặc định. Bản release cần khóa ký của người build và chỉ nên bật BACKEND_PRIVACY_READY sau khi kiểm tra backend.

Mã nguồn web đối chiếu ở commit 43be75e, backend ở 0156a6a và app ở bản làm việc 1.2.11+17. Logo trong app dùng chung tài nguyên với web.
