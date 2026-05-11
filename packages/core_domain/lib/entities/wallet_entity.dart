class WalletEntity {
  final String id;
  final String name;
  final double balance;
  final String colorHex;
  final String? cardNumber;

  WalletEntity({
    required this.id,
    required this.name,
    required this.balance,
    required this.colorHex,
    this.cardNumber,
  });

  // Chuyển từ dữ liệu Supabase trả về thành Object Flutter
  factory WalletEntity.fromMap(Map<String, dynamic> map) {
    return WalletEntity(
      id: map['id'],
      name: map['name'],
      balance: (map['balance'] as num).toDouble(),
      colorHex: map['color_hex'],
      cardNumber: map['card_number'],
    );
  }
}