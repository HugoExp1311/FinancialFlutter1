# Quy trình Gộp Code (Merge) tính năng OCR vào hệ thống Microservices

Đây là tài liệu hướng dẫn cách xử lý xung đột khi gộp mã nguồn từ một nhánh chưa có kiến trúc Microservices (chứa tính năng OCR và n8n mới) vào nhánh chính đã được quy hoạch kiến trúc Microservices.

## Phần 1: Quy trình 5 bước gộp code (Git Merge)

### Bước 1: Cô lập mã nguồn bằng Branch mới (Tuyệt đối không merge thẳng)
Thay vì gộp thẳng vào nhánh hiện tại (giả sử đang là `main`), hãy tạo một nhánh trung gian để làm phẫu thuật:
1. Tạo nhánh mới và chuyển sang: `git checkout -b merge_ocr_feature`
2. Lấy code của nhánh kia về: `git fetch origin`
3. Gộp code vào nhánh trung gian: `git merge origin/ten_nhanh_cua_ban_kia`

### Bước 2: Xử lý Xung đột (Resolve Conflicts) - Nguyên tắc "Giữ Khung của mình, Lấy Lõi của bạn"
*   **Đối với thư mục Backend cũ:** Nếu tính năng OCR được viết vào thư mục Monolithic cũ, hãy giữ lại code cũ tạm thời. Mở đoạn logic xử lý hình ảnh OCR, copy và dán vào một Handler mới bên trong thư mục `microservices/transaction_service/` (hoặc tạo hẳn một `ocr_service` mới). Sau khi di dời xong thì xóa rác backend cũ đi.
*   **Đối với thư mục Frontend (Flutter `app/lib`):** Gộp cẩn thận các nút bấm UI (Ví dụ: Nút "Quét biên lai"). **QUAN TRỌNG:** Phải sửa lại đường dẫn gọi API. Chuyển nó thành gọi qua Nginx Gateway (Port 3000) kèm theo JWT Token.

### Bước 3: Nâng cấp luồng n8n (Không Merge bằng Git)
Tuyệt đối không dùng Git để gộp file JSON của n8n vì sẽ gây lỗi định dạng ngoặc nhọn. (Xem chi tiết tại Phần 2).

### Bước 4: Cập nhật Docker & Nginx (Nếu cần thiết)
Nếu tính năng OCR cần cài thêm thư viện (như thư viện xử lý ảnh Python hoặc Tesseract OCR):
*   Mở file `Dockerfile` của service tương ứng, viết thêm lệnh `RUN apt-get install...` để cài gói đó vào trong Container.
*   Nếu tạo `ocr_service` riêng, nhớ cập nhật tệp `microservices/docker-compose.yml` và `api_gateway/nginx.conf` để thêm cấu hình định tuyến.

### Bước 5: Build lại và Kiểm thử (Test)
1. Tắt toàn bộ Docker cũ: `docker-compose down`
2. Chạy file `start_micro.bat` để build lại toàn bộ hệ thống.
3. Mở App Flutter lên, test chức năng quét ảnh OCR để đảm bảo luồng chạy đúng qua: Nginx -> Microservices -> n8n mới.
4. Nếu trơn tru, gõ lệnh `git add .`, `git commit -m "Merged OCR into Microservices"` và đẩy lên nhánh `main`.

---

## Phần 2: Hướng dẫn tích hợp 3 file luồng n8n (1 Main, 2 Sub-workflows)

Bản thân Docker **KHÔNG CẦN** thay đổi mã nguồn cấu hình khi số lượng file JSON của n8n tăng lên. Docker chỉ đóng vai trò là môi trường ảo hóa chạy n8n. Mọi thao tác liên kết luồng đều thực hiện trên giao diện web của n8n.

### 1. Import (Nhập) toàn bộ 3 file
Mở giao diện web của n8n, tạo 3 Workflow mới và lần lượt dùng tính năng `Import from file` để đưa cả 3 file (1 Main, 2 Tool) vào n8n. Nhấn **Save** cho tất cả.

### 2. Sửa lại đường dẫn liên kết Sub-workflow (CỰC KỲ QUAN TRỌNG)
Khi import file sang máy mới, n8n sẽ **đổi ID ngẫu nhiên** cho 2 file Tool.
*   Mở file Main lên, tìm đến các Nút đang gọi luồng phụ (thường là Nút **"Execute Workflow"**).
*   Bấm vào nút đó, chọn mục `Workflow ID` và trỏ nó vào đúng ID mới của file Tool 1 và Tool 2 vừa Import.

### 3. Cập nhật Webhook ID trong Microservices
Lưu ý khi import luồng Main mới, đường link Webhook của n8n có thể bị thay đổi ID. Bạn phải copy link Webhook mới đó và cập nhật lại vào biến môi trường hoặc thư mục `microservices/chatbot_service/` để máy chủ gọi đúng đích.

### 4. Khai báo API Key (Nếu có)
Hỏi đồng đội xem 2 file Tool OCR có sử dụng API Key bên thứ 3 nào không (Ví dụ: Google Vision API, OpenAI Vision...). Nếu có, vào mục **Credentials** của n8n để nhập các API Key này, nếu không Tool sẽ báo lỗi không được cấp quyền khi nhận ảnh thực tế.
