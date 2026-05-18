# 🐛 Hướng Dẫn Debug Microservices

## 📋 Tổng Quan

Dự án có 3 services chính:
1. **API Gateway** (Nginx) - Port 3000
2. **Transaction Service** (Dart) - Port 8080 (internal)
3. **Chatbot Service** (Dart) - Port 3002 (internal)

---

## 🔍 Phương Pháp Debug

### **Phương pháp 1: Debug Service Đang Chạy trong Docker**

#### Bước 1: Xem logs của service
```bash
# Xem logs real-time của tất cả services
cd microservices
docker-compose logs -f

# Xem logs của 1 service cụ thể
docker-compose logs -f transaction_service
docker-compose logs -f chatbot_service
docker-compose logs -f api_gateway

# Xem 100 dòng log cuối
docker-compose logs --tail=100 transaction_service
```

#### Bước 2: Vào bên trong container để debug
```bash
# Truy cập vào container
docker exec -it mcr_transaction_service sh

# Kiểm tra biến môi trường
env | grep SUPABASE

# Kiểm tra network
ping api_gateway
ping transaction_service

# Thoát container
exit
```

#### Bước 3: Kiểm tra health của service
```bash
# Test API Gateway
curl http://localhost:3000/health

# Test Transaction Service (từ bên trong container)
docker exec -it mcr_api_gateway sh
curl http://transaction_service:8080/transactions
exit
```

---

### **Phương pháp 2: Debug Service Ngoài Docker (Recommended)**

Đây là cách **TỐT NHẤT** để debug vì bạn có thể:
- Đặt breakpoint
- Xem biến real-time
- Hot reload code

#### Bước 1: Tắt service trong Docker
```bash
cd microservices
docker-compose stop transaction_service
# Hoặc
docker-compose down transaction_service
```

#### Bước 2: Chạy service trực tiếp trên máy local

**Transaction Service:**
```bash
cd microservices/transaction_service

# Set biến môi trường (Windows PowerShell)
$env:PORT="8080"
$env:HOST="0.0.0.0"
$env:SUPABASE_URL="https://baypebptjfrnclsgtddd.supabase.co"
$env:SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Chạy service
dart run bin/server.dart
```

**Chatbot Service:**
```bash
cd microservices/chatbot_service

# Set biến môi trường
$env:PORT="3002"
$env:HOST="0.0.0.0"
$env:N8N_WEBHOOK_URL="https://n8n.vault.io.vn/webhook/ai-chat"

# Chạy service
dart run bin/server.dart
```

#### Bước 3: Test service đang chạy local
```bash
# Test Transaction Service
curl http://localhost:8080/transactions

# Test Chatbot Service
curl http://localhost:3002/health
```

---

### **Phương pháp 3: Debug với VS Code (Advanced)**

#### Bước 1: Tạo file `.vscode/launch.json`
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Transaction Service",
      "type": "dart",
      "request": "launch",
      "program": "microservices/transaction_service/bin/server.dart",
      "cwd": "${workspaceFolder}/microservices/transaction_service",
      "env": {
        "PORT": "8080",
        "HOST": "0.0.0.0",
        "SUPABASE_URL": "https://baypebptjfrnclsgtddd.supabase.co",
        "SUPABASE_ANON_KEY": "your_key_here"
      }
    },
    {
      "name": "Debug Chatbot Service",
      "type": "dart",
      "request": "launch",
      "program": "microservices/chatbot_service/bin/server.dart",
      "cwd": "${workspaceFolder}/microservices/chatbot_service",
      "env": {
        "PORT": "3002",
        "HOST": "0.0.0.0",
        "N8N_WEBHOOK_URL": "https://n8n.vault.io.vn/webhook/ai-chat"
      }
    }
  ]
}
```

#### Bước 2: Debug trong VS Code
1. Mở file `server.dart` của service cần debug
2. Đặt breakpoint (click vào số dòng)
3. Nhấn **F5** hoặc **Run → Start Debugging**
4. Chọn configuration tương ứng
5. Gửi request đến service để trigger breakpoint

---

## 🛠️ Debug Các Vấn Đề Thường Gặp

### ❌ Lỗi: "Connection refused" khi gọi API

**Nguyên nhân:** Service chưa chạy hoặc port sai

**Cách fix:**
```bash
# Kiểm tra service có đang chạy không
docker ps

# Kiểm tra port mapping
docker ps | grep mcr_transaction_service

# Restart service
docker-compose restart transaction_service
```

---

### ❌ Lỗi: "Invalid JWT Token" từ Supabase

**Nguyên nhân:** Biến môi trường sai hoặc token hết hạn

**Cách fix:**
```bash
# Kiểm tra biến môi trường trong container
docker exec -it mcr_transaction_service sh
env | grep SUPABASE
exit

# Nếu sai, sửa file app/.env và rebuild
docker-compose down
docker-compose up -d --build
```

---

### ❌ Lỗi: "502 Bad Gateway" từ Nginx

**Nguyên nhân:** Backend service chết hoặc không trả lời

**Cách fix:**
```bash
# Xem logs của API Gateway
docker-compose logs api_gateway

# Xem logs của backend service
docker-compose logs transaction_service

# Test backend trực tiếp (bỏ qua gateway)
docker exec -it mcr_api_gateway sh
curl http://transaction_service:8080/transactions
exit
```

---

### ❌ Lỗi: "Cannot resolve host" trong Docker

**Nguyên nhân:** DNS cache hoặc network issue

**Cách fix:**
```bash
# Restart toàn bộ network
docker-compose down
docker network prune -f
docker-compose up -d

# Hoặc chỉ restart API Gateway
docker-compose restart api_gateway
```

---

## 📊 Debug Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT REQUEST                        │
│              (App/Browser/Postman)                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
            ┌────────────────┐
            │  API Gateway   │ ← Debug Point 1: Xem nginx logs
            │  (Port 3000)   │   docker-compose logs api_gateway
            └────────┬───────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐         ┌───────────────┐
│ Transaction   │         │   Chatbot     │
│ Service       │         │   Service     │
│ (Port 8080)   │         │ (Port 3002)   │
└───────┬───────┘         └───────┬───────┘
        │                         │
        │ Debug Point 2:          │ Debug Point 3:
        │ - Đặt breakpoint        │ - Xem request body
        │ - Xem logs              │ - Test n8n webhook
        │ - Test Supabase         │
        │                         │
        ▼                         ▼
┌───────────────┐         ┌───────────────┐
│   Supabase    │         │      n8n      │
│   Database    │         │   Workflow    │
└───────────────┘         └───────────────┘
```

---

## 🎯 Debug Checklist

Khi gặp lỗi, làm theo thứ tự:

- [ ] **Bước 1:** Xem logs của service bị lỗi
- [ ] **Bước 2:** Kiểm tra service có đang chạy không (`docker ps`)
- [ ] **Bước 3:** Kiểm tra biến môi trường (`docker exec ... env`)
- [ ] **Bước 4:** Test service trực tiếp (bỏ qua gateway)
- [ ] **Bước 5:** Restart service (`docker-compose restart`)
- [ ] **Bước 6:** Rebuild nếu có thay đổi code (`--build`)
- [ ] **Bước 7:** Chạy service ngoài Docker để debug chi tiết

---

## 🔧 Debug Tools

### 1. **Postman/Thunder Client**
Test API endpoints trực tiếp:
```
GET http://localhost:3000/transactions
POST http://localhost:3000/transactions
Content-Type: application/json

{
  "amount": 100,
  "is_expense": true,
  "category_name": "Food",
  "wallet_type": "main"
}
```

### 2. **Docker Desktop**
- Xem logs trực quan
- Restart container bằng 1 click
- Xem resource usage (CPU, RAM)

### 3. **VS Code Extensions**
- **Dart** - Debug Dart code
- **Docker** - Quản lý containers
- **REST Client** - Test API trong VS Code

---

## 💡 Pro Tips

1. **Luôn xem logs trước:** 90% lỗi có thể tìm ra từ logs
2. **Test từng layer:** Gateway → Service → Database
3. **Dùng `print()` debug:** Thêm `print('DEBUG: $variable')` vào code
4. **Hot reload:** Chạy service ngoài Docker để code thay đổi ngay
5. **Backup `.env`:** Luôn có backup khi thay đổi config

---

## 📚 Tài Liệu Tham Khảo

- [Docker Compose Logs](https://docs.docker.com/compose/reference/logs/)
- [Dart Debugging](https://dart.dev/tools/dart-devtools)
- [Nginx Debug](https://nginx.org/en/docs/debugging_log.html)
