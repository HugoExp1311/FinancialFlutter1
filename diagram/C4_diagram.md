# Sơ đồ Kiến trúc C4: Finance AI App

Dưới đây là các gợi ý chi tiết và mã nguồn Mermaid để bạn có thể sao chép trực tiếp vào báo cáo của mình. Kiến trúc C4 rất phù hợp để giải thích hệ thống Microservices của bạn theo hướng từ tổng quan đến chi tiết.

---

## 1. System Context Diagram (Level 1)
**Mục đích:** Thể hiện bức tranh toàn cảnh nhất. Nhìn vào đây, người chấm sẽ biết có những ai sử dụng hệ thống, và hệ thống của bạn (Finance AI App) đang tương tác với những hệ thống bên ngoài nào.

*   **Người dùng (Person):** Cá nhân có nhu cầu quản lý thu chi và muốn được AI tư vấn tài chính.
*   **Hệ thống trung tâm (Software System):** Finance AI App của bạn.
*   **Hệ thống bên ngoài (External Systems):** 
    *   `Supabase`: Hệ thống CSDL đám mây (Database as a Service) và cấp phát bảo mật.
    *   `Groq LLM API`: Dịch vụ cung cấp não bộ AI cho n8n gọi tới.

### Mã Mermaid (Level 1):
```mermaid
C4Context
    title System Context Diagram - Finance AI App

    Person(user, "Người dùng", "Cá nhân sử dụng ứng dụng để quản lý tài chính và nhận lời khuyên từ AI")
    
    System(financeApp, "Finance AI System", "Hệ thống nền tảng xử lý và lưu trữ dòng tiền tài chính cá nhân tích hợp trợ lý ảo.")
    
    System_Ext(supabase, "Supabase (BaaS)", "Cung cấp Cloud Database (PostgreSQL) và hệ thống xác thực (Auth/RLS)")
    System_Ext(groq, "Groq LLM API", "Nền tảng cung cấp AI Model suy luận ngôn ngữ (Llama-3)")

    Rel(user, financeApp, "Sử dụng tính năng Thu/Chi & Trò chuyện", "App UI")
    Rel(financeApp, supabase, "Đọc/Ghi dữ liệu thu chi & Kiểm tra Token", "HTTPS/REST")
    Rel(financeApp, groq, "Gửi Prompt và nhận phản hồi phân tích", "HTTPS/REST")
```

---

## 2. Container Diagram (Level 2)
**Mục đích:** "Phóng to" hệ thống `Finance AI System` ở Level 1 ra để xem bên trong có các "thùng chứa" (Container) nào. Đây chính là nơi bạn "khoe" được kiến trúc Microservices và API Gateway.

*   **Flutter Client App:** Cung cấp UI đa nền tảng. Chứa Clean Architecture (Riverpod, Repositories).
*   **API Gateway (Nginx):** Cổng vào duy nhất (Port 3000), phá vỡ tường lửa CORS, đóng vai trò Reverse Proxy.
*   **Transaction Service (Dart Shelf):** Microservice chạy port 8080 phụ trách Business Logic thu/chi và cấp ủy quyền.
*   **Chatbot Service (Dart Shelf):** Microservice chạy port 3002, đóng vai trò chuyển tiếp tín hiệu xuyên biên giới mạng lưới.
*   **n8n Workflow Automation:** Xử lý luồng Node-based, đóng vai trò là Agent Router và SQL-based RAG.

### Mã Mermaid (Level 2):
```mermaid
C4Container
    title Container Diagram - Kiến trúc Microservices phân tán

    Person(user, "Người dùng", "Thao tác trên thiết bị cá nhân")

    System_Boundary(clientSide, "Thiết bị Người Dùng (Mobile)") {
        Container(flutterClient, "Flutter Client App", "Flutter, Riverpod", "Ứng dụng trực quan")
        ContainerDb(isarDb, "Local Database", "Isar Database", "Lưu trữ dữ liệu ngoại tuyến (Offline-first)")
    }

    System_Boundary(backendSide, "Hệ Thống Máy Chủ (Docker Environment)") {
        Container(apiGateway, "API Gateway", "Nginx", "Cổng điều hướng Port 3000")
        Container(transactionService, "Transaction Service", "Dart Shelf Server", "Xử lý Core Logic giao dịch")
        Container(chatbotService, "Chatbot Service", "Dart Shelf Server", "Trung chuyển tin nhắn")
        Container(n8n, "n8n Automation", "NodeJS / n8n", "Router Agent và RAG")
    }

    System_Ext(supabase, "Supabase", "Cloud PostgreSQL & RLS Auth")
    System_Ext(groq, "Groq LLM API", "Llama-3 Model")

    Rel(user, flutterClient, "Tương tác chạm/nhập liệu", "Touch UI")
    Rel(flutterClient, isarDb, "Đọc/Ghi dữ liệu offline", "Isar API")
    Rel(flutterClient, apiGateway, "Gọi API /transactions & /chat", "HTTPS/REST (JSON)")

    Rel(apiGateway, transactionService, "Định tuyến ẩn danh /transactions", "HTTP Nội bộ (Port 8080)")
    Rel(apiGateway, chatbotService, "Định tuyến ẩn danh /chat", "HTTP Nội bộ (Port 3002)")

    Rel(chatbotService, n8n, "Gắn Payload, đâm xuyên mạng Host", "HTTP Nội bộ (Port 5678)")

    Rel(transactionService, supabase, "Thao tác CRUD kèm Authorization Token", "HTTPS/REST")
    Rel(n8n, supabase, "SQL-RAG: Kéo lịch sử giao dịch", "HTTPS/REST")
    Rel(n8n, groq, "Gửi Prompt tài chính cho AI", "HTTPS/REST")
```

---

## 3. Component Diagram (Level 3)
**Mục đích:** "Phóng to" vào một Container cụ thể để xem các thành phần bên trong nó hoạt động ra sao. Để thể hiện rõ năng lực thiết kế phần mềm, tôi chọn "phóng to" **Flutter Client App** vì nó minh họa xuất sắc mô hình **Clean Architecture** và **Cơ chế Cầu dao**.

*   **Presentation Layer:** Giao diện người dùng.
*   **Các Module Nghiệp Vụ (Auth, Transaction, Chatbot):** Gộp chung Controller (Riverpod) và Repository để giải quyết trọn vẹn từng chức năng độc lập. Nổi bật nhất là `Transaction Component` có chứa cơ chế "Cầu dao" tự động định tuyến.
*   **Domain Entities:** Ngôn ngữ chung, độc lập với nền tảng.
*   **API Client / Isar Client:** Tương tác trực tiếp với bên ngoài.

### Mã Mermaid (Level 3):
```mermaid
C4Component
    title Component Diagram - Flutter Client App (Clean Architecture)

    Container_Boundary(flutterApp, "Flutter Client App") {
        Component(presentation, "Presentation Layer", "Flutter Widgets", "Giao diện UI trực quan, nhận tương tác người dùng")
        
        Component(authComp, "Auth Component", "Riverpod & Repository", "Xử lý SignIn, cấp phát Token bảo mật")
        Component(transactionComp, "Transaction Component", "Riverpod & Repository", "Xử lý thu chi. Chứa cơ chế 'Cầu dao' (Offline/Online)")
        Component(chatbotComp, "Chatbot Component", "Riverpod & Repository", "Xử lý hội thoại AI và trạng thái Chat")
        
        Component(domain, "Domain Entities", "Dart", "Định nghĩa cấu trúc dữ liệu (Models) độc lập")
        Component(httpClient, "HTTP API Client", "Dio / http", "Xử lý giao tiếp mạng, gắn Header Authorization (JWT)")
        Component(isarClient, "Local DB Client", "Isar SDK", "Thao tác Query trực tiếp xuống cơ sở dữ liệu cục bộ")
    }

    Container(apiGateway, "API Gateway", "Nginx", "Hệ thống Microservices")
    ContainerDb(isarDb, "Local Database", "Isar", "Dữ liệu ngoại tuyến")

    Rel(presentation, authComp, "Đăng nhập / Cập nhật User", "Action / Watch")
    Rel(presentation, transactionComp, "Tạo/Xem thu chi", "Action / Watch")
    Rel(presentation, chatbotComp, "Gửi tin nhắn AI", "Action / Watch")

    Rel(authComp, domain, "Khởi tạo User Entity", "Mapping")
    Rel(transactionComp, domain, "Khởi tạo Transaction Entity", "Mapping")
    Rel(chatbotComp, domain, "Khởi tạo Message Entity", "Mapping")
    
    Rel(authComp, httpClient, "Xác thực Supabase", "Method Call")
    Rel(transactionComp, httpClient, "Dùng khi Mode = Microservices", "Method Call")
    Rel(chatbotComp, httpClient, "Gửi Chat qua API Gateway", "Method Call")
    
    Rel(transactionComp, isarClient, "Dùng khi Mode = Offline", "Method Call")

    Rel(httpClient, apiGateway, "Gọi API /transactions & /chat", "HTTPS/REST")
    Rel(isarClient, isarDb, "Đọc/Ghi trực tiếp", "Native API")
```

---
**💡 Gợi ý:** Bạn có thể copy các khối mã `mermaid` trên và dán vào các công cụ Render miễn phí (như [Mermaid Live Editor](https://mermaid.live/) hoặc plugin Markdown trên VSCode) để xuất thành file ảnh độ phân giải cao dán vào báo cáo Word của bạn. Sơ đồ Level 3 này là vũ khí tuyệt vời để ghi điểm tối đa về mặt "Phân tích và Thiết kế Phần mềm"!
