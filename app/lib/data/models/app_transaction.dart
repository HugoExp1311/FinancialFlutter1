import 'package:isar/isar.dart';

part 'app_transaction.g.dart';

@collection
class AppTransaction {
  Id id = Isar.autoIncrement; // ID tự động sinh (Kiểu số nguyên 64-bit)

  // UUID tạo ra từ máy cục bộ (Dùng package `uuid` để gen chuỗi).
  // Rất quan trọng để Map 1-1 với Supabase UUID
  @Index(unique: true, replace: true)
  late String syncId;

  late double amount;

  // --- [DATABASE OPTIMIZER] ---
  // @Index(): Tạo mục lục tìm kiếm (B-Tree Indexing) để khi lướt và lọc Danh sách
  // (Ví dụ: Chỉ hiện Expense = true) Isar sẽ quét với tốc độ O(log n) thay vì O(n).
  @Index()
  late bool isExpense;

  // IndexType.value: Tối ưu Cực độ cho thao tác Mặc Định của App: "Sắp xếp theo ngày gần nhất"
  @Index(type: IndexType.value)
  late DateTime date;

  String? note;

  // --- [DATABASE DESIGN] FLAT ARCHITECTURE (Kiến trúc phẳng) ---
  // Tư duy NoSQL: Hạn chế tối đa IsarLink (Quan hệ / Joins) đối với dữ liệu tĩnh.
  // Nhúng (Embed) luôn Cấu trúc Category vào Giao dịch để thao tác Đọc (Read) là NHANH NHẤT (O(1)).
  late String categoryName;
  late int
  categoryIconCode; // Chứa mã font của Icon (Ví dụ: Icons.food.codePoint)
  late int categoryColorHex; // Chứa mã màu 0xFF... để tái tạo thẻ Card

  // --- [SYNC LOGIC - OFFLINE FIRST] ---
  late DateTime updatedAt; // Cập nhật cuối của mẩu tin này

  @Index()
  bool isSynced = false; // Cờ đánh dấu đã đẩy lên Đám mây chưa?

  bool isDeleted = false; // Cờ Xóa mềm (Soft Delete)
}
