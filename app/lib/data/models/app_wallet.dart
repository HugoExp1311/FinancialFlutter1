import 'package:isar_community/isar.dart';
import 'package:core_domain/core_domain.dart';

part 'app_wallet.g.dart';

@collection
class AppWallet {
  Id id = Isar.autoIncrement;

  // UUID từ Supabase để đồng bộ 1-1
  @Index(unique: true, replace: true)
  late String syncId;

  late String name;
  
  // Trường lưu số dư thực tế từ Supabase[cite: 5, 6]
  late double balance;

  String? colorHex;
  String? cardNumber;

  @Index()
  late String userId;

  late DateTime updatedAt;

  @Index()
  bool isSynced = false;

  // ---------------------------------------------------------------------------
  // MAPPER: AppWallet (Isar) ↔ WalletEntity (Domain)
  // ---------------------------------------------------------------------------

  /// Chuyển đổi từ Isar Model sang Entity để hiển thị lên UI
  WalletEntity toEntity() {
    return WalletEntity(
      id: syncId,
      name: name,
      balance: balance,
      colorHex: colorHex ?? '#2196F3',
      cardNumber: cardNumber,
    );
  }

  /// Cập nhật dữ liệu từ Entity vào Isar[cite: 5, 6]
  void applyFromEntity(WalletEntity entity) {
    syncId = entity.id;
    name = entity.name;
    balance = entity.balance;
    colorHex = entity.colorHex;
    cardNumber = entity.cardNumber;
    updatedAt = DateTime.now();
    isSynced = true; // Đánh dấu đã đồng bộ vì lấy từ Entity chính thống[cite: 5]
  }

  /// Hàm tiện ích tạo nhanh model từ Entity[cite: 5]
  static AppWallet fromEntity(WalletEntity entity, String userId) {
    final wallet = AppWallet();
    wallet.applyFromEntity(entity);
    wallet.userId = userId;
    return wallet;
  }
}