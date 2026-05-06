# Báo Cáo Triển Khai & Gỡ Lỗi Nền Tảng Web (Web Deployment Troubleshooting)

**Dự án:** Finance AI App (Microservices Architecture)  
**Mục tiêu:** Port ứng dụng Flutter từ thiết bị di động (APK) sang nền tảng Trình duyệt Web (Chrome) đồng thời duy trì hệ sinh thái Microservices.

Dưới đây là nhật ký tổng hợp các rào cản kỹ thuật nghiêm trọng khi đưa ứng dụng lên môi trường Web và các biện pháp giải quyết đã được áp dụng thành công.

---

## 1. Sự cố 1: Trắng màn hình do Rào cản Hệ thống tệp (Isar Database)
**Hiện tượng:** 
Khi biên dịch và chạy ứng dụng trên trình duyệt Chrome, ứng dụng bị crash ngay từ hàm `main()` dẫn đến lỗi màn hình trắng vĩnh viễn.  
**Nguyên nhân gốc (Root Cause):** 
Trình duyệt Web không cấp quyền truy cập trực tiếp vào hệ thống tệp (File System) của thiết bị vật lý như trên Android/Windows. Trong khi đó, hệ quản trị CSDL Isar yêu cầu bắt buộc phải cung cấp một đường dẫn ổ cứng thông qua `getApplicationDocumentsDirectory()` để khởi tạo.
**Giải pháp kiến trúc:**
- **Triển khai "Ve Sầu Thoát Xác":** Viết lại cấu trúc Provider (`app_providers.dart`) tự động nhận diện nền tảng (`kIsWeb`).
- Trên Mobile, ứng dụng tiếp tục sử dụng Isar.
- Trên Web, ứng dụng ngắt bỏ hoàn toàn Isar, chuyển sang sử dụng `UserProfileRepositoryWeb.dart` - một module mới sử dụng công nghệ **Supabase Realtime Stream** để kết nối trực tiếp lên Đám Mây (Cloud-first / Thin Client), lấy dữ liệu mà không cần lưu trữ vật lý.

---

## 2. Sự cố 2: "Án Oan 0 Đồng" & Xung đột Header CORS Kép
**Hiện tượng:** 
Giao diện Web load thành công Avatar và tên người dùng nhưng hiển thị số dư là `$0.00` dù cơ sở dữ liệu trên Supabase đã có rất nhiều bản ghi (Transactions). Đồng thời Console của Chrome xuất hiện lỗi `XMLHttpRequest error`.
**Nguyên nhân gốc (Root Cause):** 
Trình duyệt Chrome áp dụng chính sách bảo mật CORS cực kỳ khắt khe. 
- Tại **API Gateway (Nginx)**, chúng ta đã chủ động gắn tem khai báo an toàn: `add_header 'Access-Control-Allow-Origin' '*'`.
- Tuy nhiên, bên dưới Backend **Transaction Service**, lập trình viên cũng cài cắm một đoạn Middleware tự động dán tem CORS.
Hậu quả là Response trả về cho trình duyệt mang theo **2 Header CORS kép**: `Access-Control-Allow-Origin: *, *`. Chrome lập tức đánh giá đây là cấu hình không hợp lệ (hàng giả) và block gói dữ liệu JSON ngay cửa sổ mạng, khiến dữ liệu `$0.00` bị hiển thị sai lệch.
**Giải pháp kiến trúc:**
- Khử hoàn toàn middleware `_corsMiddleware()` trong source code `transaction_service/bin/server.dart`. 
- Uỷ quyền kiểm duyệt CORS độc tôn cho một mình Nginx API Gateway xử lý để đảm bảo nguyên tắc Centralized Routing.

---

## 3. Sự cố 3: Lỗi ngắt kết nối Não AI (Unsupported operation: Platform)
**Hiện tượng:** 
Gửi tin nhắn trong Chatbot nhận được thông báo lỗi đỏ rực: `Lỗi ngắt kết nối với não AI... Lỗi chi tiết: Unsupported operation: Platform._version`.
**Nguyên nhân gốc (Root Cause):** 
Giao diện `chatbot_screen.dart` đang sử dụng gói thư viện `dart:io` (cụ thể là đối tượng `HttpClient`) để giao tiếp HTTP. Thư viện này dùng để chọc sâu vào lõi Hệ điều hành (`Platform`), do đó **không được Flutter hỗ trợ biên dịch sang JavaScript** cho nền tảng Web.
Đồng thời, hàm gọi URL đang chọc thẳng vào Port `5678` nội bộ thay vì đi qua Cổng chính Gateway `3000`.
**Giải pháp kiến trúc:**
- Thay thế hoàn toàn `dart:io` sang thư viện đa nền tảng `package:http/http.dart`.
- Chuyển hướng luồng dữ liệu (Traffic) của Chatbot từ URL tĩnh nội bộ sang biến môi trường tập trung: `$baseUrl/chat/send` (Cổng 3000 Nginx). Giúp duy trì chặt chẽ tính đóng gói của kiến trúc Microservices.

---

## 4. Sự cố 4: Docker Cache & Biến Môi Trường Kẹt Cứng
**Hiện tượng:** 
Sau khi thay đổi URL cho n8n webhook (`N8N_WEBHOOK_URL`) trong file `.env`, container `chatbot_service` vẫn gọi về localhost của Docker cũ thay vì chĩa ra tên miền Cloud `n8n.vault.io.vn`. Đồng thời, code Dart trên Web sau khi sửa lỗi `dart:io` vẫn tiếp tục báo lỗi `Platform._version`.
**Nguyên nhân gốc (Root Cause):** 
- **Với Flutter Web:** Terminal `start_micro_web.bat` đang đóng vai trò là Server cấp phát nóng (Hot compiler). Việc F5 trình duyệt chỉ tải lại JS cũ từ RAM. Cần phím `R` để kích hoạt biên dịch lại.
- **Với Docker:** Gói binary của Dart được đóng gói bằng phương thức AOT (Ahead-Of-Time) trong một container `scratch` (trống rỗng). Do không có thay đổi file cấu trúc đáng kể, Docker Compose đã tái sử dụng Layer bộ nhớ đệm (Cache) của lần build cũ, khiến các bản cập nhật file `.env` và code Dart server bị đóng băng.
**Giải pháp kiến trúc:**
- Kích hoạt lệnh `docker-compose up -d --build --no-cache chatbot_service` để xóa trắng bộ nhớ đệm và ép Docker đóng gói một file thực thi AOT mới nhất cùng cấu hình `.env` mới nhất.
- Hướng dẫn người dùng thao tác phím `R` (Hot Restart) thay vì phím `F5` vô nghĩa của Web.

---
**Trạng thái hiện tại:** ✅ Toàn bộ ứng dụng Web đã tương thích đa nền tảng 100%, tích hợp hoàn hảo với hệ sinh thái Microservices.
