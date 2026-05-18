# 🚀 AI Finance Assistant (Flutter + n8n + Supabase)

Dự án Quản lý Tài chính Thông minh ứng dụng AI với kiến trúc **Multi-Agent System** (Hệ thống Đa Đại lý) và **Microservices**. Hệ thống mang lại trải nghiệm nhập liệu bằng Chatbot siêu tốc, phân tích tự động, và Dashboard trực quan.

## 🎯 Tổng Quan (Project Overview)

Ứng dụng giúp người dùng ghi chép thu chi hoàn toàn tự động chỉ bằng một câu nói hoặc văn bản thông qua Chatbot AI. Hệ thống tích hợp một "**Khối óc**" điều tiết ở backend (n8n Workflow) chia làm hai luồng rõ rệt:
1. **Luồng Ghi Chép (Data Clerk):** Bóc tách Số tiền, Hạng mục, Ghi chú từ tin nhắn để lưu vào Database.
2. **Luồng Phân Tích (Financial Analyst):** Đóng vai trò Cố vấn, tự động lôi toàn bộ lịch sử thu/chi, chạy thuật toán tính tổng và viết bài đánh giá tài chính cá nhân hóa cho người dùng.

## 🏗 Cấu Trúc Dự Án (Monorepo Architecture)

Dự án áp dụng triệt để nguyên lý **Clean Architecture** và chia thành các khối tách biệt:

```text
Flutter1/
├── app/                  # Ứng dụng điện thoại (Flutter) (Giao diện, Riverpod, Routing)
├── microservices/        # Dịch vụ Backend (Dart backend server, REST APIs custom)
│   └── transaction_service/
├── packages/             # Các gói độc lập
│   └── core_domain/      # Chứa Entities, Use Cases, Repositories theo chuẩn Clean UI
Prompts cho AI, Specs
└── README.md             # File tổng quan bạn đang đọc
```

## 🧩 Các Thành Phần Chức Năng (Features)

**1. Hệ thống Frontend (Flutter App)**
- Giao diện trực quan đẹp mắt: Biểu đồ thu chi (PieChart, BarChart), Dashboard thống kê qua ngày/tháng/năm.
- Màn hình Chatbot tích hợp Bong bóng chat AI cực nhanh.
- Quản lý trạng thái (State Management) bằng **Riverpod 2.0**.
- Flow Đăng nhập/Đăng ký qua Supabase Auth.
- Form nhập tay truyền thống (Dành cho việc chỉnh sửa và backup).
- Hỗ trợ Đa ngôn ngữ (Localization): Hệ thống hỗ trợ chuyển đổi hoàn thiện giữa Tiếng Việt và Tiếng Anh trên toàn bộ giao diện.

**2. Hệ thống Backend (Supabase / Dart Microservice)**
- Lưu trữ 100% dữ liệu gốc tại **Supabase** (PostgresQL).
- Cơ chế bảo mật RLS (Row Level Security) theo từng định danh `user_id`.
- Transaction Microservice phụ trách xử lý riêng lẻ các logic đặc thù ở phía mây.
- **Isar** là local database dùng để hỗ trợ lưu trữ dữ liệu khi không có kết nối internet.

**3. Khối óc Trung Tâm (N8N Multi-Agent Workflow)**
- Routing mạnh mẽ qua **Llama 3.3 70B (Groq API)** hoặc **Gemini 2.5 Flash (Google API)**.
- Tích hợp Parser JSON và Data Fetcher khép kín, triệt tiêu ảo giác (Hallucination).
- Quét hóa đơn Đa phương thức (Multimodal OCR): Tích hợp thị giác máy tính từ **Gemini 2.5 Flash** để đọc hiểu ảnh chụp hóa đơn, tự động trích xuất tổng tiền và nội dung chi tiêu mà không cần nhập liệu.
- Cảnh báo bất thường kép (Dual-Layer Anomaly Detection): Tự động phát hiện chi tiêu vượt ngưỡng (Tĩnh) và các hành vi lạm chi bất thường so với lịch sử (Động).

---

## 💻 Hướng Dẫn Cài Đặt và Chạy Mã Nguồn (Installation)

### Bước 1: Yêu Cầu Môi Trường (Prerequisites)
Đảm bảo máy của bạn đã cài đặt các công cụ sau:
- Tải [Flutter SDK](https://docs.flutter.dev/get-started/install) (Khuyến nghị version >= 3.x).
- Tải [Dart SDK](https://dart.dev/get-dart).
- Tạo tài khoản nền tảng Đám mây [Supabase](https://supabase.com).
- Tạo tài khoản API AI của [Groq](https://console.groq.com/).
- Tạo tài khoản APi AI của [Google](https://aistudio.google.com).
- Một Workspace chạy n8n (Local qua Docker hoặc n8n Cloud).

### Bước 2: Khởi tạo Backend Supabase
1. Đăng nhập Supabase, tạo một Project mới.
2. Tại phần **SQL Editor**, khởi tạo bảng `transactions` với các trường:
   `id`, `sync_id`, `user_id`, `amount`, `is_expense`, `category_name`, `category_icon_code`, `category_color_hex`, `note`, `date`, `updated_at`.
3. Lưu lại 2 khóa mật: `SUPABASE_URL` và `SUPABASE_ANON_KEY`.

### Bước 3: Cài đặt Hệ thống AI Backend (N8N Workflow)
1. Mở N8N Workspace của bạn. Trỏ vào `Workflows` -> `Import from File`.
2. Import lần lượt 3 file workflow: `AI_Agent_Coordinator.json`, `Tool_GhiChep.json`, và `Tool_PhanTich.json` vào n8n Workspace.
3. Config lại cặp Credentials ở các node: 
   - Node `Supabase`: Gắn cặp khóa URL/Key ở Bước 2.
   - Node `Groq Chat Model`: Nhập API Key ở Groq.
   - Node `Google Gemini Chat Model`: Nhập API Key ở Google AI Studio.
4. Gắn 2 tool trong workflow phụ `Tool_GhiChep.json`, và `Tool_PhanTich.json` vào workflow chính `AI_Agent_Coordinator.json`.
4. Chuyển nút trạng thái của cả 3 Workflow sang **Published** (Xanh lá).
5. Mở Cục `Webhook` đầu nguồn lên, click Test và copy cái URL `Test URL` / `Production URL`.

### Bước 4: Thiết lập App Flutter
1. Di chuyển vào thư mục `app`:
   ```bash
   cd app
   flutter pub get
   ```
2. Mở file `app/.env` (Nếu chưa có thì tạo file text tên `.env`), điền vào các khóa sau:
   ```env
   SUPABASE_URL=dán_đường_link_supabase_của_bạn
   SUPABASE_ANON_KEY=dán_key_ẩn_danh_supabase
   N8N_WEBHOOK_URL=dán_webhook_url_n8n_ở_bước_3
   ```
3. Chạy lệnh xây dựng code tự động của Riverpod và freezed:
   ```bash
   dart run build_runner build -d
   ```
4. Chạy App (Hỗ trợ iOS, Android, macOS, Windows):
   ```bash
   flutter run -d windows
   ```

### Bước 5: (Tùy chọn) Chạy Microservices
Nếu muốn chạy Microservices độc lập (Cho các kết nối ngoài hoặc webhook xử lý cục bộ):
```bash
cd microservices/transaction_service
dart pub get
dart bin/server.dart
```

## 🎉 Trải Nghiệm (Usage)
1. Mở App, đăng kí một tài khoản mới và đăng nhập.
2. Chuyển sang thẻ **Chatbot (AI)** nằm trong thanh định vị Bottom Navigation.
3. Nhập văn bản: *"Hôm nay tớ tiêu 45 ngàn tiền ăn một tô phở cạn tiền luôn"* -> Tiều phu AI sẽ ghi nhận Data Kế toán.
4. Nhập tiếp: *"Phân tích cho tớ và chốt xem tiền dư tháng này bù lỗ được không?"* -> Giáo sư AI sẽ in ra biểu đồ Markdown và đánh giá tài chính cho bạn!
5. Nhấn vào icon Camera 📸, chọn ảnh hóa đơn bất kỳ -> AI sẽ tự động phân tích và ghi chép thông tin hóa đơn vào Database.

Chúc bạn thành công với AI Finance Chatbot này!
