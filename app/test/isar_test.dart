import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:app/data/models/app_transaction.dart';
import 'dart:io';

void main() {
  late Isar isar;

  setUpAll(() async {
    // Tải Core nhị phân về máy tính để giả lập môi trường DB
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    // Tạo thư mục tạm thời trên máy để chứa DB nháp
    final tempDir = await Directory.systemTemp.createTemp('isar_testing_');

    isar = await Isar.open([AppTransactionSchema], directory: tempDir.path);
  });

  tearDown(() async {
    // Xoá trắng database sau mỗi test
    await isar.close(deleteFromDisk: true);
  });

  group('Isar AppTransaction Tests (CRUD + Query)', () {
    test('1. Create: Thêm giao dịch (Tạo mới)', () async {
      final tx = AppTransaction()
        ..syncId = 'tx-1'
        ..updatedAt = DateTime.now()
        ..amount = 50000
        ..isExpense = true
        ..date = DateTime.now()
        ..categoryName = "Ăn uống"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;

      await isar.writeTxn(() async {
        await isar.appTransactions.put(tx);
      });

      expect(await isar.appTransactions.count(), 1);
    });

    test('2. Read: Đọc & Lọc danh sách (Tìm kiếm)', () async {
      final tx1 = AppTransaction()
        ..syncId = 'tx-1'
        ..updatedAt = DateTime.now()
        ..amount = 20000
        ..isExpense = true
        ..date = DateTime.now()
        ..categoryName = "Cà phê"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;
      final tx2 = AppTransaction()
        ..syncId = 'tx-2'
        ..updatedAt = DateTime.now()
        ..amount = 5000000
        ..isExpense = false
        ..date = DateTime.now()
        ..categoryName = "Lương"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;

      await isar.writeTxn(() async {
        await isar.appTransactions.putAll([tx1, tx2]);
      });

      // Lọc ra giao dịch thu nhập
      final incomes = await isar.appTransactions
          .filter()
          .isExpenseEqualTo(false)
          .findAll();

      expect(incomes.length, 1);
      expect(incomes.first.categoryName, "Lương");
      expect(incomes.first.amount, 5000000);
    });

    test('3. Update: Cập nhật sửa giao dịch đã có', () async {
      final tx = AppTransaction()
        ..syncId = 'tx-3'
        ..updatedAt = DateTime.now()
        ..amount = 10000
        ..isExpense = true
        ..date = DateTime.now()
        ..categoryName = "Vé xe"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;

      // Lưu lần đầu
      await isar.writeTxn(() async {
        await isar.appTransactions.put(tx);
      });
      // Query lấy ID tự động
      final savedTx = await isar.appTransactions.where().findFirst();

      // Sửa đổi dữ liệu
      savedTx!.amount = 15000;
      savedTx.categoryName = "Gửi xe";

      // Lưu đè (Do cùng ID nên Isar sẽ tự cập nhật)
      await isar.writeTxn(() async {
        await isar.appTransactions.put(savedTx);
      });

      final updatedTx = await isar.appTransactions.get(savedTx.id);
      expect(updatedTx!.amount, 15000);
      expect(updatedTx.categoryName, "Gửi xe");
      // Số lượng mẩu tin vẫn phải là 1 (không bị sinh nảy)
      expect(await isar.appTransactions.count(), 1);
    });

    test('4. Delete: Xóa một giao dịch', () async {
      final tx = AppTransaction()
        ..syncId = 'tx-4'
        ..updatedAt = DateTime.now()
        ..amount = 50000
        ..isExpense = true
        ..date = DateTime.now()
        ..categoryName = "Mua thẻ"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;

      await isar.writeTxn(() async {
        await isar.appTransactions.put(tx);
      });

      final firstTx = await isar.appTransactions.where().findFirst();

      // Act: Xóa
      final deleted = await isar.writeTxn(() async {
        return await isar.appTransactions.delete(firstTx!.id);
      });

      expect(deleted, true); // Hàm xoá trả về true nếu thành công
      expect(await isar.appTransactions.count(), 0); // DB trống
    });

    test('5. Aggregation: Truy vấn siêu nhanh (Sum)', () async {
      // Nhét 3 record vào
      final tx1 = AppTransaction()
        ..syncId = 'tx-5'
        ..updatedAt = DateTime.now()
        ..amount = 50000
        ..isExpense = true
        ..date = DateTime.now()
        ..categoryName = "Sáng"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;
      final tx2 = AppTransaction()
        ..syncId = 'tx-6'
        ..updatedAt = DateTime.now()
        ..amount = 30000
        ..isExpense = true
        ..date = DateTime.now()
        ..categoryName = "Trưa"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;
      final tx3 = AppTransaction()
        ..syncId = 'tx-7'
        ..updatedAt = DateTime.now()
        ..amount = 200000
        ..isExpense = false
        ..date = DateTime.now()
        ..categoryName = "Bán đồ cũ"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;

      await isar.writeTxn(() async {
        await isar.appTransactions.putAll([tx1, tx2, tx3]);
      });

      // Tính: TỔNG tiền các khoản LÀ CHI TIÊU
      final expenseSum = await isar.appTransactions
          .filter()
          .isExpenseEqualTo(true)
          .amountProperty() // Chọn riêng cột amount để tính
          .sum(); // Hạ lệnh cho DB tính tổng toán học

      // 50,000 + 30,000 = 80,000
      expect(expenseSum, 80000);
    });
  });
}
