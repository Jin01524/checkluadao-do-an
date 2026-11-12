# CheckLuaDao

CheckLuaDao hỗ trợ kiểm tra tin nhắn nghi lừa đảo trên web và Android. Người dùng dán văn bản hoặc chọn ảnh, đọc dấu hiệu rủi ro, phần đối chiếu an toàn và kết luận.

## Dùng thử

- **Android 1.2.11 (build 17)** · [Tải APK](https://github.com/Jin01524/checkluadao-do-an/releases/download/v1.2.11/CheckLuaDao-v1.2.11-build17-android.apk) · [Ghi chú phát hành và SHA-256](https://github.com/Jin01524/checkluadao-do-an/releases/tag/v1.2.11)
- **Web** · [Mở CheckLuaDao](https://check-lua-dao.vercel.app)

Trên Android, mở tệp APK và làm theo hướng dẫn cài đặt của thiết bị. Để quét nội dung đang xem ở ứng dụng khác, bật bong bóng trong CheckLuaDao, cấp quyền hiển thị đè và chọn **Quét màn hình**. Android sẽ yêu cầu xác nhận chia sẻ màn hình để chụp một ảnh. Bấm **Xem chi tiết** trong lớp phủ để mở báo cáo.

## Chức năng

- **Kiểm tra văn bản và ảnh.** Backend dùng Tesseract.js để đọc chữ trong ảnh. Gemini nhận phần văn bản và trả ba phần phân tích gồm rủi ro, đối chiếu an toàn và kết luận.
- **Xử lý tin thiếu ngữ cảnh.** Hệ thống để trống điểm và có thể đề xuất một câu hỏi ngắn để người dùng tự sao chép. Khi có thêm phản hồi, người dùng có thể quét lại đoạn hội thoại như một lượt mới.
- **Tra cứu kho mẫu.** Tìm theo nội dung hoặc loại lừa đảo, xem chi tiết và trạng thái kiểm duyệt. Khu vực quản trị web dùng để duyệt mẫu và quản lý cấu hình theo vai trò.
- **Bong bóng Android.** Chụp một ảnh theo yêu cầu, hiển thị tiến trình và kết quả trên lớp phủ, hoặc hủy lượt đang xử lý.

Kết quả phản ánh nội dung đã gửi ở thời điểm quét. Nếu có yêu cầu đáng ngờ mới, hãy quét lại với phần hội thoại liên quan.

## Mã nguồn

| Thư mục | Công nghệ | Điểm bắt đầu |
| --- | --- | --- |
| [web](web/) | React, Vite, Tailwind CSS | [Trang quét](web/src/pages/HomePage.jsx) |
| [backend](backend/) | Node.js, Express, Tesseract.js, Gemini, Supabase | [Khai báo API](backend/server.js), [luồng quét](backend/routes/check.js) |
| [app](app/) | Flutter, Dart, Kotlin | [Màn quét](app/lib/features/scan/scan_page.dart), [bong bóng Android](app/android/app/src/main/kotlin/com/checkluadao/app_checkluadao_ttnt/ScreenBubbleService.kt) |

Web và Android dùng chung API. Luồng quét bắt đầu ở `POST /api/v2/check`. Backend kiểm tra dữ liệu, đọc chữ từ ảnh nếu có, gọi Gemini, rồi áp dụng quy tắc ngữ cảnh và trả kết quả. Các lượt có kết luận mới đi qua bước ghi nhật ký và xét điều kiện lưu mẫu.

## Chạy dự án trên máy

Clone repo rồi chạy các lệnh bên dưới từ thư mục `checkluadao-do-an`. Dùng **Node.js 24** cho backend và web. App Android dùng **Flutter 3.47.5**, **Dart 3.13.4** và **Android SDK**.

### 1. Backend

Tạo `backend/.env` từ mẫu dưới đây và điền giá trị của môi trường riêng. Với một cơ sở dữ liệu mới, chạy [supabase_schema.sql](backend/supabase_schema.sql) trong SQL Editor của Supabase.

```dotenv
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
GEMINI_API_KEY=
JWT_SECRET=
```

Nếu cần tài khoản quản trị từ biến môi trường, thêm `ADMIN_USERNAME` và `ADMIN_PASSWORD_HASH` (bcrypt). Lưu khóa Supabase, Gemini và JWT ở phía máy chủ.

```sh
cd backend
npm ci
npm start
```

API mặc định chạy tại `http://localhost:5000`. Mở `http://localhost:5000/api/health` để kiểm tra máy chủ.

### 2. Web

Mở terminal khác và chạy từ thư mục gốc của repo.

```sh
cd web
npm ci
npm run dev
```

Vite in địa chỉ web sau khi khởi động. Web mặc định gọi backend tại `http://localhost:5000`. Nếu dùng địa chỉ khác, đặt `VITE_API_URL` trong `web/.env.local`. Chạy `npm run build` để tạo bản web.

### 3. Android

Mở terminal ở thư mục gốc của repo, kết nối điện thoại Android hoặc mở giả lập.

```sh
cd app
flutter pub get
flutter run
```

App dùng địa chỉ trong [app_config.dart](app/lib/app/app_config.dart) theo mặc định. Để dùng backend riêng mà thiết bị truy cập được, truyền `--dart-define=API_BASE_URL=https://your-api.example.com` vào lệnh Flutter. Bản release yêu cầu HTTPS, cấu hình ký và chỉ bật `BACKEND_PRIVACY_READY=true` sau khi kiểm tra backend sẽ sử dụng.

## Kiểm thử

| Thành phần | Lệnh trong thư mục tương ứng |
| --- | --- |
| Backend | `npm test` |
| Web | `npm run build` |
| Flutter | `flutter analyze` và `flutter test` |
