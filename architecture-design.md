# Personal Finance App - Architecture & Tech Stack

## 1. Project Overview (Understanding Summary)
- **Sản phẩm:** Ứng dụng quản lý tài chính cá nhân (lấy cảm hứng từ Money Lover / Firefly III).
- **Mục tiêu cốt lõi:** Làm dự án cá nhân (Portfolio/CV) với phần Frontend (UI/UX) thật đẹp mắt, mượt mà và một kiến trúc mã nguồn chuẩn chuyên nghiệp.
- **Đối tượng và Hoạt động:** Người dùng cá nhân ghi chép thu/chi hàng ngày. Ứng dụng áp dụng mô hình kiến trúc **Offline-first (Ưu tiên ngoại tuyến)** kết hợp đồng bộ nền tảng Cloud (Supabase).
- **Phát triển Tương lai (Future Scope):** Tích hợp NLP (Xử lý ngôn ngữ tự nhiên) qua Supabase + n8n Workflow để thêm giao dịch bằng giọng nói/quét hoá đơn tự động. Mở rộng tính năng Chatbot AI nhờ Vector Database tích hợp sẵn.

## 2. Công Nghệ Sử Dụng (Tech Stack & Decision Log)
- **Framework Chính:** Flutter (Phát triển Cross-platform).
- **State Management (Quản lý trạng thái):** `Riverpod`
  - *Lý do chọn:* Code ngắn gọn hơn BLoC, an toàn khi biên dịch (compile-safe), bắt kịp xu hướng hiện đại. Dễ tiếp cận cho người mới nhưng vẫn được đánh giá rất cao trong các dự án thực tế và CV xin việc.
- **Local Database (Cơ sở dữ liệu cục bộ - Offline First):** `Isar Database` (NoSQL)
  - *Lý do chọn:* Tốc độ truy vấn cực nhanh (C-core), tương thích hoàn hảo và trơn tru cho cả Mobile lẫn Flutter Web. Đóng vai trò là SSOT (Single Source of Truth) kết xuất UI tức thời ở 60 FPS, không lo độ trễ mạng.
- **Backend & API Server (Đám mây):** `Supabase` (BaaS)
  - *Lý do chọn:* Hạ tầng PostgreSQL mạnh mẽ tích hợp sẵn hệ thống Auth, tính năng Realtime, Postgres REST API. Đặc biệt hỗ trợ `pgvector` cực kỳ ưu việt khi mở rộng làm Vector Database cho các dự án kết hợp AI/Chatbot tài chính trong tương lai. Có thể dễ dàng kết nối Webhook với n8n để chạy luồng Xử lý Ngữ nghĩa (NLP).
  
## 3. Kiến Trúc Hệ Thống (Layered Architecture)
Dự án áp dụng kiến trúc phân tầng để đảm bảo code sạch (Clean Code), dễ bảo trì và thể hiện tư duy kiến trúc tốt:
- **`lib/data/` (Tầng dữ liệu):**
  - Chứa các cấu trúc Schema của Isar (ví dụ: `Transaction`, `Wallet`, `Category`).
  - Chứa các lớp `Repositories` chịu trách nhiệm gọi lệnh Thêm/Sửa/Xóa dữ liệu vào Isar.
- **`lib/domain/` (Tầng nghiệp vụ/Logic):**
  - Chứa các Business Logic (Ví dụ: Hàm tính tổng số dư trong tháng, phân tích biểu đồ). Tầng này hoàn toàn độc lập, không dính líu đến UI hay Database.
- **`lib/presentation/` (Tầng giao diện):**
  - Chứa các `Screens` (màn hình) và `Widgets` (thành phần UI độc lập).
  - Sử dụng tiêu chuẩn thiết kế hiện đại (Dark mode, Glassmorphism, Animations).
  - Kết nối với `Riverpod` để tự động render lại màn hình mỗi khi dữ liệu ở tầng dưới thay đổi.

## 4. Giải Pháp Môi Trường Compile (Cho Máy Tính Yếu)
Do hạn chế về tài nguyên hệ thống (RAM/Ổ cứng), việc tạo và xuất file `.apk` sẽ KHÔNG thông qua Android Studio, mà sử dụng bộ công cụ gọn nhẹ nhất:
- **Editor:** Visual Studio Code.
- **Java:** OpenJDK 17.
- **Android SDK:** Cài đặt độc lập qua **Android SDK Command-line Tools** (tải `platform-tools`, `build-tools`).
- **Command:** Sử dụng trực tiếp `flutter build apk` sau khi đã set biến môi trường `ANDROID_HOME` và cấu hình SDK cho Flutter.

## 5. Các Chức Năng Cốt Lõi (Core Features)
Để biến đồ án này thành một sản phẩm thực tế (Super App), dự án tập trung phát triển các tính năng sau:
- **📊 Quản Lý Thu Chi (Income & Expense Tracking):** 
  - Ghi chép giao dịch hàng ngày nhanh chóng qua giao diện Add Transaction hiện đại (Slide-up modal).
  - Phân loại rõ ràng các nhóm danh mục (Categories) bằng icon và màu sắc đặc trưng.
- **📈 Báo Cáo & Thống Kê (Statistics Dashboard):** 
  - Trực quan hóa dữ liệu qua biểu đồ cột (Custom Bar Chart) để theo dõi xu hướng chi tiêu nguyên tuần/tháng.
  - Hiển thị Top danh mục ngốn tiền nhất bằng thanh tiến trình (Progress Bar).
- **💳 Quản Lý Đa Ví (Multi-Wallet System):** 
  - Hỗ trợ tạo và quản lý độc lập nhiều nguồn tiền (Ví Chính, Thẻ Tín Dụng, Tiền Tiết Kiệm...).
  - Giao diện thẻ Debit trực quan (Glassmorphism Credit Card).
- **👤 Cá Nhân Hóa & Cài Đặt (Personalization):** 
  - Thay đổi theme Tối/Sáng tự động tựa theo hệ thống.
  - Các cấu hình giả lập bảo mật (FaceID/Biometric) và thông báo (Notifications).
