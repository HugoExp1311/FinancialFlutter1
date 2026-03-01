# Backend Architecture Design: Supabase + Isar Offline-first

## 1. Tổng quan Kiến trúc

Mô hình **Offline-first (Ưu tiên ngoại tuyến)** kết hợp **BaaS (Supabase)** là một giải pháp hoàn hảo cho ứng dụng quản lý thu chi cá nhân tích hợp AI.

*   **Isar Database (Local):** Đóng vai trò là SSOT (Single Source of Truth) cho giao diện người dùng (UI). Mọi thao tác Thêm, Sửa, Xoá, Lọc dữ liệu đều thực thi Đọc/Ghi trực tiếp trên điện thoại để đạt mức FPS 60, UX tức thì, không bị phụ thuộc vào trễ mạng.
*   **Supabase (Cloud):** Đóng vai trò là hệ lưu trữ trung tâm, đồng bộ dữ liệu chéo thiết bị, cung cấp các dịch vụ Authorization (Xác thực đăng nhập), và là cổng nối mượt mà tới các Workflow AI (n8n, NLP).

## 2. Thiết kế luồng dữ liệu (Data Flow)

### Kịch bản A: Người dùng chủ động tạo giao dịch
1.  **UI & Isar:** User tạo 1 giao dịch. Ứng dụng lập tức ghi vào Isar (RAM/Disk cục bộ) và cập nhật giao diện ngay lập tức.
2.  **Sync Service:** Một Background Task sẽ kiểm tra kết nối mạng (`internet_connection_checker`).
    *   *Trạng thái Online:* App gửi POST request (chứa dữ liệu giao dịch dưới dạng JSON) lên Supabase API và cập nhật trạng thái `sync_status = true` trên Isar.
    *   *Trạng thái Offline:* Trạng thái giao dịch gắn cờ `sync_status = false` nằm chờ.
3.  **Hồi phục mạng:** Khi có mạng lại, hệ thống quét các bản ghi `sync_status = false` và đẩy một lượt Batch Insert (đẩy hàng loạt) lên Supabase để tránh nghẽn.

### Kịch bản B: NLP n8n tự động tạo từ Giọng nói/Hoá đơn
1.  **Input:** User thu âm giọng nói hoặc chụp biên lai. App bắn một lệnh Webhook kèm file lên n8n.
2.  **Xử lý AI (n8n):** n8n bóc tách văn bản, chạy NLP (GPT/Gemini), trả ra kết quả có cấu trúc: `{"amount": 50000, "category": "Food"}`.
3.  **n8n -> Supabase:** n8n gọi lệnh lưu tự động cục dữ liệu bóc được vào Supabase DB.
4.  **Supabase -> App (Realtime):** Cơ chế Websocket (Supabase Realtime) đẩy tín hiệu Push Notification / Data Payload về App.
5.  **App & Isar:** Ứng dụng (hiện đang mở) bắt được tín hiệu Realtime, tự động tải dữ liệu gốc (Fetch), ghi đè/nhét vào Isar cục bộ. Giao diện người dùng sẽ tự báo "Có vẻ bạn vừa ăn sáng xong!".

## 3. Cấu trúc Bảng CSDL (Supabase PostgreSQL Table)

Supabase chạy trên nền PostgreSQL nên cần định nghĩa Schema chặt chẽ.

**Table: `transactions`**
*   `id` (uuid, primary key): Định danh toàn cầu (chống đụng độ khi offline/online).
*   `user_id` (uuid, foreign key tới bảng auth.users): Khóa định danh của người dùng. RLS (Row Level Security) sẽ chặn không cho user A đọc được tiêu thụ của user B.
*   `amount` (numeric hoặc int8): Số tiền.
*   `is_expense` (bool): True = Chi, False = Thu.
*   `category_name` (text/varchar): Tên hạng mục ("Ăn uống", "Đi lại").
*   `category_icon_code` (int4): Mã icon.
*   `category_color_hex` (int4): Mã màu hex.
*   `note` (text, nullable): Ghi chú giao dịch.
*   `date` (timestamptz): Thời gian giao dịch diễn ra.
*   `created_at` (timestamptz): Thời gian bản ghi này được lên server. Bắt buộc để thực hiện logic phân giải xung đột.
*   `is_deleted` (bool, default: false): Hỗ trợ "Soft Delete" để không bị mất đồng bộ khi có thay đổi offline.

## 4. Hướng dẫn cài đặt cơ bản

### Bước 1: Khởi tạo Project Supabase
1.  Đăng nhập [Supabase](https://supabase.com/). Tạo dự án mới.
2.  Lưu lại **Project URL** và **API Anon Key**.

### Bước 2: Thiết lập Client trong Flutter
1.  Chạy cài thư viện: `flutter pub add supabase_flutter`
2.  Cấu hình `main.dart` để khởi tạo Supabase ngay trước thẻ `runApp()`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}

// Gọi biến client ở mọi nơi:
final supabase = Supabase.instance.client;
```

### Bước 3: Đồng bộ hoá Schema Model (Ví dụ Model nâng cấp)
Trong `AppTransaction` của Isar, cần thêm các trường xử lý luồng đồng bộ:

```dart
@collection
class AppTransaction {
  Id id = Isar.autoIncrement;

  // UUID tạo ra từ máy cục bộ (Dùng package `uuid` để gen chuỗi). 
  // Rất quan trọng để Map 1-1 với Supabase UUID
  @Index(unique: true, replace: true)
  late String syncId;

  late double amount;
  late bool isExpense;
  late DateTime date;
  String? note;
  late String categoryName;
  late int categoryIconCode;
  late int categoryColorHex;

  // --- TRƯỜNG PHỤC VỤ SYNC ---
  late DateTime updatedAt;      // Cập nhật cuối của mẩu tin này
  @Index()
  bool isSynced = false;        // Cờ đánh dấu đã đẩy lên Đám mây chưa?
  bool isDeleted = false;       // Áp dụng cờ Xóa mềm
}
```

## 5. Các Lớp Bảo Mật (RLS - Row Level Security)
Khác với Firebase (viết rule bằng JSON), Supabase viết Rule bảo vệ dữ liệu bằng SQL thuần trên Dashboard:

*   **Chỉ tạo mới khi Login:** Ai đang xài Token chính chủ Auth mới được phép chèn dữ liệu.
*   **Chỉ đọc dữ liệu của chính mình:**
    ```sql
    CREATE POLICY "Users can only see their own transactions"
    ON transactions
    FOR SELECT
    USING (auth.uid() = user_id);
    ```
