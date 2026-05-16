# Nhật ký Giải quyết Sự cố Merge Nhánh mc3_merge_profile

Tài liệu này ghi lại toàn bộ quá trình sửa lỗi và khôi phục tính năng sau khi merge nhánh `thu` vào nhánh `mc3_merge_profile`.

---

## 1. Các vấn đề chính sau khi Merge
- **Lỗi biên dịch Isar**: Không tìm thấy package `isar` do xung đột phiên bản (dự án chuyển sang dùng `isar_community`).
- **Logic Ví (Wallet) sai lệch**: Số dư ví được tính bằng công thức giả lập 70/30 thay vì dựa trên giao dịch thực tế.
- **Mất tính năng Profile**: Màn hình Profile bị lỗi hoặc mất các tính năng quan trọng như upload avatar và cài đặt tài khoản.
- **Xung đột Schema**: Sự không nhất quán giữa `walletType` (cũ) và `walletId` (mới).

---

## 2. Quá trình xử lý chi tiết

### Bước 1: Sửa lỗi thư viện Isar
- **Vấn đề**: Toàn bộ các file `.g.dart` và Repository bị lỗi `Type 'Isar' not found`.
- **Giải pháp**: 
  - Cập nhật tất cả các import từ `package:isar/isar.dart` sang `package:isar_community/isar.dart`.
  - Chạy `flutter pub get` và `build_runner` để generate lại code.

### Bước 2: Chuyển đổi Logic Ví (walletType → walletId)
- **Yêu cầu**: Ngừng sử dụng `walletType` ('main'/'savings') và chuyển sang quản lý ví động theo `walletId`.
- **Thực hiện**:
  - **Domain Entity**: Comment trường `walletType` trong `TransactionEntity`, giữ lại `walletId`.
  - **Data Model**: Comment `walletType` trong `AppTransaction` (Isar model) và các hàm mapper (`toEntity`, `applyFromEntity`).
  - **UI (WalletScreen)**: 
    - Thay thế toàn bộ logic tính toán số dư.
    - Duyệt qua `allTransactions`, lọc theo `tx.walletId == wallet.id`.
    - Thêm Modal "Add New Wallet" để tạo ví thực tế lên Supabase và Isar.

### Bước 3: Khôi phục Profile từ nhánh "thu"
- **Vấn đề**: Màn hình Profile ở nhánh merge không đầy đủ tính năng.
- **Giải pháp**:
  - Sử dụng lệnh `git checkout thu -- app/lib/presentation/screens/profile_screen.dart` để lấy lại bản copy hoàn chỉnh.
  - Sửa lỗi **UTF-8 Encoding** (Invalid UTF-8 byte) phát sinh trong quá trình copy file để `build_runner` có thể chạy được.
  - Khôi phục các tính năng: Upload Avatar lên Supabase Storage, Cập nhật thông tin cá nhân (First/Last name, Phone, DOB, Gender), và Cài đặt bảo mật.

### Bước 4: Sửa lỗi Use Cases và Compile
- **Vấn đề**: Các Use Case như `UpdateTransactionUseCase` vẫn gọi tham số `walletType`, gây lỗi build Windows.
- **Giải pháp**:
  - Truy vết toàn bộ project bằng `grep`.
  - Comment tất cả các lời gọi `walletType` trong `UpdateTransactionUseCase` và các file liên quan.
  - Đảm bảo tính nhất quán của pattern `copyWith`.

### Bước 5: Khôi phục Dropdown Chọn Ví trong Add Transaction Screen
- **Vấn đề**: Màn hình thêm giao dịch (bấm nút +) thiếu dropdown để chọn ví, dẫn đến không thể gán giao dịch vào ví cụ thể.
- **Giải pháp**:
  - Restore file `add_transaction_screen.dart` từ nhánh `thu` bằng lệnh `git checkout thu -- app/lib/presentation/screens/add_transaction_screen.dart`.
  - File này bao gồm:
    - Class `Wallet` để lưu thông tin ví (id, name).
    - Hàm `_fetchWallets()` để lấy danh sách ví từ Supabase khi màn hình mở.
    - DropdownButton cho phép người dùng chọn ví trước khi tạo giao dịch.
    - Validation kiểm tra `_selectedWalletId` trước khi submit.
    - Truyền `walletId: _selectedWalletId` vào `addTransactionUseCaseProvider.execute()`.

---

## 3. Trạng thái hiện tại
- **Build**: Thành công trên Windows Desktop (`flutter run -d windows`).
- **Ví**: Hiển thị danh sách ví thực từ Database, tính toán số dư chính xác theo từng ví.
- **Profile**: Đầy đủ tính năng upload ảnh và quản lý tài khoản.
- **Thêm giao dịch**: Có dropdown chọn ví, validation đầy đủ, và truyền `walletId` vào use case.
- **Mã nguồn**: Các đoạn code liên quan đến `walletType` đã được comment lại (không xóa) để tham khảo nếu cần rollback.

---

## 4. Các tệp đã can thiệp
- `app/lib/data/models/app_transaction.dart`
- `app/lib/presentation/screens/wallet_screen.dart`
- `app/lib/presentation/screens/profile_screen.dart`
- `app/lib/presentation/screens/add_transaction_screen.dart` *(Restored từ nhánh thu)*
- `packages/core_domain/lib/entities/transaction_entity.dart`
- `packages/core_domain/lib/use_cases/update_transaction_use_case.dart`
- `app/lib/data/models/app_transaction.g.dart` (Regenerated)

---
*Ghi chú: Mọi thay đổi đã được kiểm tra bằng `flutter analyze` để đảm bảo không có lỗi nghiêm trọng.*
