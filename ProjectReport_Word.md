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

## CHƯƠNG 4: TRIỂN KHAI VÀ KẾT QUẢ THỰC NGHIỆM
*(Trình bày quy trình hiện thực hóa thiết kế và đánh giá chất lượng sản phẩm cuối cùng)*

**4.1. Môi trường triển khai hệ thống**
- **4.1.1. Cấu hình phần cứng:** Thông số máy tính thực nghiệm (CPU, RAM, OS).
- **4.1.2. Môi trường phần mềm và Phiên bản:** 
    - Hạ tầng: Docker 25.x, Docker Compose v2.x.
    - Phát triển: Flutter SDK 3.x, Dart SDK 3.x.
    - Android Build Stack: Android Gradle Plugin 8.0.2, Gradle 8.0, Kotlin 1.9.22.
- **4.1.3. Quản lý biến môi trường (.env):** Giải thích vai trò của các tệp cấu hình (Supabase URL, API Keys, N8N Webhook) trong việc đảm bảo tính bảo mật và linh hoạt khi triển khai.

**4.2. Đóng gói và Vận hành Microservices (Containerization)**
- **4.2.1. Thiết lập Docker Compose:** Phân tích cách điều phối các container (Transaction Service, Chatbot Service, API Gateway) hoạt động đồng bộ trong mạng nội bộ cô lập (`finance_network`).
- **4.2.2. Quy trình khởi chạy một-chạm:** Mô tả các bước thực thi từ lệnh `docker-compose up` đến việc khởi chạy Flutter Client trên các nền tảng khác nhau.
- **4.2.3. Giám sát hệ thống:** Cách quản lý và theo dõi Log thời gian thực từ các dịch vụ Backend để xử lý sự cố.

**4.4. Kết quả thực nghiệm và Đánh giá (Testing & Evaluation)**
- **4.4.1. Kiểm thử tính năng nghiệp vụ (Functional Testing):** 
    - Kiểm chứng luồng ghi chép thu chi và thống kê dữ liệu.
    - Kiểm chứng khả năng phản hồi và độ chính xác của AI Chatbot theo ngữ cảnh tài chính.
- **4.4.2. Kiểm thử bảo mật và Phân quyền:** Xác thực cơ chế Row-Level Security (RLS) kết hợp với JWT Token, đảm bảo dữ liệu người dùng được cách ly tuyệt đối.
- **4.4.3. Kiểm thử hiệu năng:** Đánh giá độ trễ khi truy cập qua API Gateway và sự ổn định của luồng dữ liệu Stream (Realtime).

**4.5. Thảo luận và Hướng phát triển**
- **4.5.1. Ưu điểm:** Kiến trúc Microservices giúp hệ thống linh hoạt, dễ bảo trì và khả năng mở rộng cao.
- **4.4.2. Hạn chế:** Tiêu tốn tài nguyên phần cứng (do chạy nhiều container và n8n), độ trễ tích lũy khi qua nhiều lớp proxy.
- **4.4.3. Hướng phát triển:** Nâng cấp khả năng tự động mở rộng (Auto-scaling), tích hợp CI/CD và tối ưu hóa bộ nhớ cho các service nhẹ.

---

## KẾT LUẬN VÀ KIẾN NGHỊ
- Tổng kết những mục tiêu đã đạt được so với đề tài ban đầu.
- Bài học kinh nghiệm trong quá trình chuyển đổi kiến trúc từ Monolith sang Microservices.
- Kiến nghị về các giải pháp tối ưu hóa hơn cho hệ thống AI Agent trong tương lai.

