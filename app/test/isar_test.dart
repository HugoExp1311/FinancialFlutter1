import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:app/data/models/app_transaction.dart';
import 'dart:io';

void main() {
  late Isar isar;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('isar_testing_');
    isar = await Isar.open([AppTransactionSchema], directory: tempDir.path);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('Kiểm thử CRUD Giao dịch (Isar)', () {
    test('Nên thêm được giao dịch mới', () async {
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

    test('Nên lọc được danh sách theo loại thu nhập/chi tiêu', () async {
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

      final incomes = await isar.appTransactions
          .filter()
          .isExpenseEqualTo(false)
          .findAll();

      expect(incomes.length, 1);
      expect(incomes.first.categoryName, "Lương");
    });

    test('Nên cập nhật được thông tin giao dịch đã có', () async {
      final tx = AppTransaction()
        ..syncId = 'tx-3'
        ..updatedAt = DateTime.now()
        ..amount = 10000
        ..isExpense = true
        ..date = DateTime.now()
        ..categoryName = "Vé xe"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;

      await isar.writeTxn(() async {
        await isar.appTransactions.put(tx);
      });
      
      final savedTx = await isar.appTransactions.where().findFirst();

      savedTx!.amount = 15000;
      savedTx.categoryName = "Gửi xe";

      await isar.writeTxn(() async {
        await isar.appTransactions.put(savedTx);
      });

      final updatedTx = await isar.appTransactions.get(savedTx.id);
      expect(updatedTx!.amount, 15000);
      expect(updatedTx.categoryName, "Gửi xe");
    });

    test('Nên xóa được giao dịch khỏi database', () async {
      final tx = AppTransaction()
        ..syncId = 'tx-4'
        ..updatedAt = DateTime.now()
        ..amount = 50000
        ..isExpense = true
        ..date = DateTime.now()
        ..categoryName = "Mua sắm"
        ..categoryIconCode = 0
        ..categoryColorHex = 0;

      await isar.writeTxn(() async {
        await isar.appTransactions.put(tx);
      });

      final firstTx = await isar.appTransactions.where().findFirst();

      final deleted = await isar.writeTxn(() async {
        return await isar.appTransactions.delete(firstTx!.id);
      });

      expect(deleted, true);
      expect(await isar.appTransactions.count(), 0);
    });

    test('Nên tính được tổng tiền chi tiêu chính xác', () async {
      final tx1 = AppTransaction()
        ..syncId = 'tx-5'
        ..amount = 50000
        ..isExpense = true
        ..date = DateTime.now()
        ..updatedAt = DateTime.now()
        ..categoryName = "Sáng";
        
      final tx2 = AppTransaction()
        ..syncId = 'tx-6'
        ..amount = 30000
        ..isExpense = true
        ..date = DateTime.now()
        ..updatedAt = DateTime.now()
        ..categoryName = "Trưa";

      await isar.writeTxn(() async {
        await isar.appTransactions.putAll([tx1, tx2]);
      });

      final expenseSum = await isar.appTransactions
          .filter()
          .isExpenseEqualTo(true)
          .amountProperty()
          .sum();

      expect(expenseSum, 80000);
    });
  });
}