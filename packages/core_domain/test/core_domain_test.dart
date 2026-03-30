import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddTransactionUseCase', () {
    // TODO: Sẽ inject MockRepository ở Bước 3 khi viết unit tests đầy đủ.
    // Hiện tại file này chỉ xác nhận package compile thành công.
    test('TransactionEntity equality check', () {
      final now = DateTime(2026, 3, 24);
      final e1 = TransactionEntity(
        syncId: 'abc-123',
        amount: 50000,
        isExpense: true,
        date: now,
        categoryName: 'Ăn uống',
        categoryIconCode: 0xe56c,
        categoryColorHex: 0xFFFF5722,
        updatedAt: now,
      );
      final e2 = e1.copyWith(amount: 100000);

      expect(e1.syncId, equals(e2.syncId));
      expect(e1.amount, isNot(equals(e2.amount)));
      expect(e1, isNot(equals(e2)));
    });
  });
}
