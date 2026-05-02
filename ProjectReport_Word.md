# DÀN Ý BÁO CÁO DỰ ÁN: CẤU TRÚC CHI TIẾT

Dưới đây là bản brainstorm và xây dựng dàn ý chi tiết dựa trên hệ thống thực tế của bạn (*Finance AI App* với kiến trúc Microservices, Flutter, Supabase/Isar, và AI Chatbot tích hợp n8n). Bạn có thể xem xét và phản hồi để chúng ta chốt cấu trúc cuối cùng.

---

## CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI
*(Đã viết xong - Giữ nguyên)*
1. Lý do chọn đề tài
2. Mục tiêu đề tài
3. Đối tượng nghiên cứu
4. Phạm vi nghiên cứu
5. Phương pháp nghiên cứu
6. Đóng góp của đề tài
7. Bố cục báo cáo

---

## CHƯƠNG 2: CƠ SỞ LÝ THUYẾT
*(Trình bày các kiến thức nền tảng công nghệ làm cơ sở xây dựng ứng dụng)*
**2.1. Khái niệm LLM Agent và mô hình Router Agent**
- Giới thiệu chung về LLM Agents.
- Mô hình Router Agent (Supervisor) trong việc phân loại ý định và điều phối luồng xử lý định tuyến (Pipeline/Routing).
- Ứng dụng thực tiễn của Router Agent trong việc trích xuất và phân tích văn bản tài chính.

**2.2. Phương pháp Context Injection và SQL-based RAG**
- Vấn đề ảo giác (Hallucination) của LLM khi thiếu dữ liệu cá nhân.
- Khái niệm Context Injection (Bơm ngữ cảnh) trong Prompt Engineering.
- Phương pháp SQL-based RAG (Retrieval-Augmented Generation truy xuất có cấu trúc): Truy xuất số liệu bằng truy vấn CSDL (Supabase) để làm cơ sở cho mô hình AI tổng hợp phân tích.

**2.3. Công nghệ Multi-Agent**
- Khái niệm Multi-Agent System (Hệ thống đa tác vụ).
- Sự giao tiếp và phân chia nhiệm vụ giữa các Agent để chia nhỏ vấn đề.

**2.4. Automation n8n tích hợp chatbot**
- Giới thiệu nền tảng n8n (Node-based workflow automation).
- Ứng dụng n8n trong việc tiếp nhận Webhook và tạo luồng điều hướng AI Chatbot tự động.

**2.5. Lý thuyết về Microservices và ứng dụng**
- Định nghĩa kiến trúc Microservices và nguyên tắc phân rã hệ thống.
- Ưu điểm của Microservices so với kiến trúc Monolith cục bộ (độc lập triển khai, dễ tiêu chuẩn hóa, chống chịu lỗi tốt).
- Ứng dụng thực tiễn: Phân tách hệ thống quản lý thu chi và Chatbot AI thành các dịch vụ độc lập.

**2.6. Nginx Reverse Proxy và API Gateway**
- Khái niệm API Gateway trong bài toán bảo vệ luồng truy cập nội mạng cho Microservices.
- Khái niệm Reverse Proxy (Nginx) hỗ trợ phân luồng tàng hình các cổng (Ports).
- Ứng dụng thực tiễn: Gỡ rào cản bức tường CORS cho giao tiếp HTTP và tạo định tuyến tập trung.

---

## CHƯƠNG 3: PHÂN TÍCH – THIẾT KẾ HỆ THỐNG
*(Trọng tâm của báo cáo, thể hiện toàn bộ khả năng phân rã và thiết kế kiến trúc)*
**3.1. Kiến trúc tổng thể hệ thống**
- Sơ đồ kiến trúc chuyển đổi từ Monolith sang Microservices.
- Áp dụng Clean Architecture để phân tách Business Logic.

**3.2. Luồng xử lý nghiệp vụ (Business flow)**
- Luồng quản lý thu chi (Tạo, sửa, xóa, thống kê giao dịch).
- Luồng tư vấn tài chính qua AI Chatbot.

**3.3. Thiết kế Frontend (Client)**
- Xây dựng giao diện đa nền tảng với Flutter.
- Quản lý trạng thái (State Management) với Riverpod.
- Cơ chế "Cầu dao" tự động chuyển đổi logic (tắt db cục bộ, chọc HTTP API).

**3.4. Tự động hóa luồng Chatbot AI với n8n**
- Thiết lập Webhook và luồng Node-based đón nhận tín hiệu giao tiếp.
- Cấu hình luồng Workflow n8n tích hợp LLM Router và SQL-RAG tĩnh.

**3.5. Thiết kế dữ liệu và Database**
- **Isar (Local/Offline DB):** Thiết kế kiến trúc chuyển đổi từ chế độ Monolithic/Offline-first cũ rẽ nhánh sang hệ thống qua mạng.
- **Supabase (PostgreSQL):** Sơ đồ tổ chức bảng (ERD) và chiến lược bảo mật Row-Level Security (RLS) gắn với JWT Token để bảo vệ Microservices.

**3.6. Thiết kế Microservices Backend (Dart Shelf & Nginx)**
- **Kiến trúc Framework Dart Shelf:** Đóng gói Backend nhẹ, biên dịch AOT độc lập, tách rời Flutter SDK.
- **Transaction Service:** Xử lý nghiệp vụ thu chi, gọi truy vấn thẳng đến Supabase kèm định danh Token đầu cuối.
- **Chatbot Service:** Dịch vụ xử lý NLP gửi tín hiệu xuyên container sang n8n qua môi trường mạng nội bộ.
- **Nginx API Gateway:** Cấu hình Reverse Proxy tập trung độc tôn tại port `3000`, định tuyến ẩn `/transactions` và `/chat`, đồng thời tháo gỡ giới hạn tường lửa CORS ngầm.

---

## CHƯƠNG 4: THỰC NGHIỆM VÀ ỨNG DỤNG
*(Đánh giá mức độ hoàn thiện của sản phẩm)*
**4.1. Mục tiêu thực nghiệm**
- Kiểm chứng tính năng cơ bản của App và sự toàn vẹn dữ liệu.
- Đánh giá khả năng chịu tải hoặc độ trễ qua cổng Gateway.

**4.2. Môi trường chạy thực nghiệm**
- Cấu hình server / máy tính cục bộ.
- Phần mềm: Docker, Docker Compose, Postman (để test API hở).

**4.3. Đánh giá kết quả thực nghiệm**
- **Kết quả đạt được:** Hoạt động ổn định của App, phân luồng Nginx chuẩn, phân quyền (RLS) an toàn qua token.
- **Nguyên nhân và Hạn chế:** Các vấn đề như độ trễ của AI khi gọi qua nhiều proxy, tài nguyên ngốn bởi n8n,...

---

## CHƯƠNG 5: TRIỂN KHAI ỨNG DỤNG VÀ HƯỚNG DẪN SỬ DỤNG
*(Hướng dẫn đóng gói và bàn giao hệ thống)*
**5.1. Mục tiêu triển khai**
- Đóng gói toàn bộ hệ thống vào ảnh (images) và khởi chạy một-chạm.

**5.2. Yêu cầu hệ thống và thư viện**
- Phiên bản Docker, Flutter SDK, Dart SDK cần dùng.
- Các File `.env` chứa biến quy định môi trường.

**5.3. Cấu trúc thư mục triển khai**
- Giải thích sơ đồ tổ chức thư mục của dự án (Flutter App, Các Service Dart, Cấu Hình Nginx, file `docker-compose.yaml`).

**5.4. Hướng dẫn cài đặt và chạy ứng dụng**
- Các bước khởi chạy cụ thể: Bước 1 (Cài đặt Docker), Bước 2 (Chạy `docker-compose up -d`), Bước 3 (Chạy App Client).
- Cách kiểm tra log lỗi khi Container sập.

---

