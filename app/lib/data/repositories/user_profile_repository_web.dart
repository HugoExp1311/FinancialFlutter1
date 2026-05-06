import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';

class UserProfileRepositoryWeb implements IUserProfileRepository {
  final SupabaseClient _supabase;

  UserProfileRepositoryWeb(this._supabase);

  @override
  Stream<UserProfileEntity?> watchUserProfile() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(null);

    // Dùng Supabase Realtime Stream trên Web thay cho Isar
    return _supabase
        .from('user_profile')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((events) {
          if (events.isEmpty) return null;
          final response = events.first;
          return UserProfileEntity(
            userId: response['id'],
            firstName: response['first_name'],
            lastName: response['last_name'],
            avatarUrl: response['avatar_url'],
            dateOfBirth: response['date_of_birth'] != null 
                ? DateTime.tryParse(response['date_of_birth']) 
                : null,
            gender: response['gender'],
            bio: response['bio'],
            phoneNumber: response['phone_number'],
            address: response['address'],
          );
        });
  }

  @override
  Future<void> updateUserProfile(UserProfileEntity entity) async {
    final data = {
      'id': entity.userId,
      'first_name': entity.firstName,
      'last_name': entity.lastName,
      'avatar_url': entity.avatarUrl,
      'date_of_birth': entity.dateOfBirth?.toIso8601String(),
      'gender': entity.gender,
      'bio': entity.bio,
      'phone_number': entity.phoneNumber,
      'address': entity.address,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _supabase.from('user_profile').upsert(data);
  }

  @override
  Future<void> syncProfile() async {
    // Web luôn online nên không cần logic pull/sync của Isar
  }
}
