# Microservices — Transaction Service

> **Stack:** Dart + shelf + core_domain (dùng chung với Monolith)

---

## Cấu trúc

```
microservices/
└── transaction_service/
    ├── bin/
    │   └── server.dart              ← Entry point (chạy tại đây)
    ├── lib/
    │   └── handlers/
    │       └── transaction_handler.dart  ← HTTP route handlers (hiện là stub)
    └── pubspec.yaml
```

## Cách chạy Backend

```powershell
cd microservices/transaction_service
dart pub get
dart run bin/server.dart
# → ✅ Transaction Service running at http://localhost:8080
```

## Test nhanh bằng curl / Postman

```bash
# Health check
GET http://localhost:8080/health

# Lấy danh sách (stub data)
GET http://localhost:8080/transactions

# Tạo mới (stub)
POST http://localhost:8080/transactions
Content-Type: application/json
{ "amount": 50000, "is_expense": true, "category_name": "Food", ... }
```

## Kích hoạt Microservices Mode trong Flutter App

Vào `app/lib/presentation/providers/app_providers.dart`, đổi 1 dòng:

```dart
// MONOLITH (mặc định):
return TransactionRepositoryImpl(isar, supabase);

// MICROSERVICES:
return TransactionRepositoryHttp(baseUrl: 'http://localhost:8080');
```

---

## Roadmap (TODO — Bước 3 giai đoạn 2)

- [ ] Implement thật `TransactionHandler` (gọi Use Cases từ `core_domain`)
- [ ] Chọn data store cho backend: Supabase/PostgreSQL trực tiếp hoặc in-memory
- [ ] Implement `TransactionRepositoryHttp` trong Flutter (HTTP calls thật)
- [ ] Thêm Authentication (JWT từ Supabase hoặc custom)
- [ ] Containerize với Docker (`Dockerfile` + `docker-compose.yml`)
- [ ] Deploy backend lên Cloud (Railway / Fly.io / GCP Cloud Run)
