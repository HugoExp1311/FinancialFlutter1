FROM dart:stable AS build
WORKDIR /app

# Bắt buộc phải copy cả core_domain vì transaction_service phụ thuộc vào nó (Monorepo)
COPY packages/core_domain/ /app/packages/core_domain/
COPY microservices/transaction_service/ /app/microservices/transaction_service/

WORKDIR /app/microservices/transaction_service

# Tải dependencies
RUN dart pub get

# Biên dịch mã nguồn Dart thành file thực thi nhị phân cực nhẹ (AOT compile)
RUN dart compile exe bin/server.dart -o bin/server

# Chuyển sang image base siêu nhẹ để chạy production
FROM debian:stable-slim

# Cài đặt chứng chỉ gốc (Rất quan trọng để gửi HTTPS lên Supabase không bị lỗi SSL)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/microservices/transaction_service/bin/server /app/bin/server

# Expose port (Thông báo port hoạt động)
EXPOSE 8080

CMD ["/app/bin/server"]
