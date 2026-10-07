# 📱 QR Master - Ứng Dụng Quét & Tạo Mã QR (Flutter)

Ứng dụng di động đa nền tảng (Android & iOS) hoàn chỉnh được phát triển bằng Flutter, hỗ trợ quét mã QR bằng Camera trực tiếp, quét mã từ ảnh trong thư viện (Gallery), tạo mã QR theo nhiều định dạng và quản lý lịch sử quét/tạo mã.

---

## 🚀 Các Tính Năng Chính

### 1. 📷 Quét Mã QR Thông Minh
- **Quét trực tiếp qua Camera:** Nhận diện mã siêu nhanh và chính xác với thư viện `mobile_scanner` (hỗ trợ Google ML Kit trên Android & VisionKit trên iOS).
- **Quét từ Thư viện ảnh (Gallery):** Cho phép chọn ảnh chụp màn hình hoặc ảnh lưu sẵn trong máy để giải mã QR.
- **Tiện ích camera:** Bật/tắt đèn Flash (Torch) và chuyển đổi Camera trước/sau.
- **Hiệu ứng giao diện:** Khung ngắm bo tròn phong cách hiện đại cùng tia quét laser chuyển động.

### 2. ⚡ Tự Động Phân Loại & Thao Tác Nhanh
- **Liên kết Web (URL):** Nhận diện URL và mở trực tiếp trên trình duyệt chỉ với 1 chạm.
- **Mạng Wi-Fi:** Phân tích thông tin SSID, mật khẩu và giao thức bảo mật.
- **Số điện thoại / SMS / Email:** Mở ứng dụng gọi điện, gửi tin nhắn hoặc gửi email tương ứng.
- **Sao chép & Chia sẻ:** Nút sao chép nội dung vào Clipboard và chia sẻ trực tiếp qua mạng xã hội.

### 3. ✨ Tạo Mã QR Đa Dạng
- Hỗ trợ tạo mã cho nhiều định dạng:
  - Địa chỉ Website (URL)
  - Đoạn văn bản (Text)
  - Cấu hình Wi-Fi (Tên mạng, mật khẩu, loại bảo mật WPA/WEP)
  - Số điện thoại
  - Email / SMS
- **Xuất & Chia sẻ ảnh QR:** Tự động tạo ảnh PNG độ phân giải cao và chia sẻ qua các ứng dụng khác.

### 4. 🗂️ Quản Lý Lịch Sử (Offline Storage)
- Tự động lưu tất cả mã đã quét và mã đã tạo vào bộ nhớ thiết bị với `SharedPreferences`.
- Phân loại theo bộ lọc: *Tất cả*, *Đã quét*, *Đã tạo*.
- Hỗ trợ sao chép nhanh, xem lại chi tiết, vuốt để xóa từng mục hoặc xóa toàn bộ lịch sử.

---

## 📂 Cấu Trúc Dự Án (Clean MVVM Architecture)

```text
qr_scanner_app/
├── android/app/src/main/AndroidManifest.xml  # Cấu hình quyền Camera, Storage cho Android
├── ios/Runner/Info.plist                      # Cấu hình quyền Camera, Photo Library cho iOS
├── pubspec.yaml                               # Danh sách thư viện & dependencies
├── lib/
│   ├── main.dart                              # Điểm khởi chạy ứng dụng & nạp theme
│   ├── domain/
│   │   └── models/
│   │       └── qr_item.dart                   # Model dữ liệu QrItem & phân loại nội dung
│   ├── data/
│   │   └── services/
│   │       └── qr_history_service.dart        # Dịch vụ lưu trữ lịch sử offline
│   └── ui/
│       ├── core/
│       │   └── theme.dart                     # Theme Material 3 (Light/Dark mode)
│       └── features/
│           ├── home/
│           │   └── home_screen.dart           # Giao diện chính với thanh NavigationBar 3 tab
│           ├── scanner/
│           │   ├── views/
│           │   │   └── scanner_screen.dart    # Màn hình quét Camera & chọn ảnh từ Gallery
│           │   └── widgets/
│           │       ├── scanner_overlay.dart   # Khung ngắm & hiệu ứng laser
│           │       └── scan_result_sheet.dart # Bottom sheet hiển thị kết quả & hành động
│           ├── generator/
│           │   └── views/
│           │       └── generator_screen.dart  # Màn hình tạo QR & xuất ảnh chia sẻ
│           └── history/
│               └── views/
│                   └── history_screen.dart    # Màn hình xem & quản lý lịch sử
```

---

## 🛠️ Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Bước 1: Mở thư mục dự án
Đặt thư mục làm việc của bạn tại:
`C:\Users\huythanh.pham\.gemini\antigravity\scratch\qr_scanner_app`

### Bước 2: Tải các gói thư viện
Mở Terminal trong thư mục dự án và chạy:
```bash
flutter pub get
```

### Bước 3: Lưu ý cấu hình nền tảng

- **Android:**
  - File `android/app/build.gradle`: Đảm bảo `minSdkVersion` tối thiểu là `21` (yêu cầu của thư viện `mobile_scanner`).
  - Quyền camera và bộ nhớ đã được cấu hình sẵn trong `android/app/src/main/AndroidManifest.xml`.

- **iOS:**
  - Các quyền `NSCameraUsageDescription` và `NSPhotoLibraryUsageDescription` đã được khai báo sẵn trong `ios/Runner/Info.plist`.
  - Trên thiết bị iOS thật, camera sẽ hoạt động mượt mà (trên iOS Simulator không hỗ trợ camera thật).

### Bước 4: Chạy ứng dụng trên thiết bị
Kết nối điện thoại thật (bật USB Debugging trên Android) hoặc khởi động giả lập:
```bash
flutter run
```
