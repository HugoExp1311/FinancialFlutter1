import 'package:isar_community/isar.dart';

part 'app_user_profile.g.dart';

@collection
class AppUserProfile {
  Id id = Isar.autoIncrement;

  // UUID của user (từ auth.users)
  @Index(unique: true, replace: true)
  late String userId;

  String? firstName;
  String? lastName;
  String? avatarUrl;
  DateTime? dateOfBirth;
  String? gender;
  String? bio;
  String? phoneNumber;
  String? address;

  late DateTime updatedAt;
  
  // Cờ trạng thái đồng bộ
  bool isSynced = false;
}
