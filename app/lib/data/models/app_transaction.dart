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

  // Flatten category data
  late String categoryName;
  late int categoryIconCode; 
  late int categoryColorHex; 

  late DateTime updatedAt;

  @Index()
  bool isSynced = false;

  bool isDeleted = false; 

  // Mapper: Isar -> Domain
  TransactionEntity toEntity() {
    return TransactionEntity(
      localId: id == Isar.autoIncrement ? null : id,
      syncId: syncId,
      amount: amount,
      isExpense: isExpense,
      date: date,
      note: note,
      categoryName: categoryName,
      categoryIconCode: categoryIconCode,
      categoryColorHex: categoryColorHex,
      updatedAt: updatedAt,
      isSynced: isSynced,
      isDeleted: isDeleted,
    );
  }

  // Mapper: Domain -> Isar
  void applyFromEntity(TransactionEntity entity) {
    if (entity.localId != null) id = entity.localId!;
    syncId = entity.syncId;
    amount = entity.amount;
    isExpense = entity.isExpense;
    date = entity.date;
    note = entity.note;
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
}