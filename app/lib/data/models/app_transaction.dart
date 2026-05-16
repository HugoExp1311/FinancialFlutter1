import 'package:isar_community/isar.dart';
import 'package:core_domain/core_domain.dart';

part 'app_transaction.g.dart';

@collection
class AppTransaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String syncId;

  late double amount;

  @Index()
  late bool isExpense;

  @Index(type: IndexType.value)
  late DateTime date;

  String? note;

  // --- THÊM TRƯỜNG WALLET ID TẠI ĐÂY ---
  @Index()
  String? walletId; 

  late String categoryName;
  late int categoryIconCode;
  late int categoryColorHex;

  late DateTime updatedAt;

  @Index()
  bool isSynced = false;

  bool isDeleted = false;

  // ---------------------------------------------------------------------------
  // MAPPER: AppTransaction (Isar) ↔ TransactionEntity (Domain)
  // ---------------------------------------------------------------------------

  TransactionEntity toEntity() {
    return TransactionEntity(
      localId: id == Isar.autoIncrement ? null : id,
      syncId: syncId,
      amount: amount,
      isExpense: isExpense,
      date: date,
      note: note,
      walletId: walletId, // CHUYỂN SANG ENTITY
      categoryName: categoryName,
      categoryIconCode: categoryIconCode,
      categoryColorHex: categoryColorHex,
      updatedAt: updatedAt,
      isSynced: isSynced,
      isDeleted: isDeleted,
    );
  }

  void applyFromEntity(TransactionEntity entity) {
    if (entity.localId != null) id = entity.localId!;
    syncId = entity.syncId;
    amount = entity.amount;
    isExpense = entity.isExpense;
    date = entity.date;
    note = entity.note;
    walletId = entity.walletId; // ÁP DỤNG TỪ ENTITY
    categoryName = entity.categoryName;
    categoryIconCode = entity.categoryIconCode;
    categoryColorHex = entity.categoryColorHex;
    updatedAt = entity.updatedAt;
    isSynced = entity.isSynced;
    isDeleted = entity.isDeleted;
  }

  static AppTransaction fromEntity(TransactionEntity entity) {
    final tx = AppTransaction();
    tx.applyFromEntity(entity);
    return tx;
  }

  void applyFromRow(Map<String, dynamic> row) {
    syncId = row['sync_id'];
    amount = (row['amount'] as num).toDouble();
    isExpense = row['is_expense'];
    categoryName = row['category_name'];
    categoryIconCode = row['category_icon_code'];
    categoryColorHex = row['category_color_hex'];
    note = row['note'];
    walletId = row['wallet_id'];
    date = DateTime.parse(row['date']);
    updatedAt = DateTime.parse(row['updated_at']);
    isDeleted = row['is_deleted'];
    isSynced = true;
  }
}