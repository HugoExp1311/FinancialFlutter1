import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import 'package:app/data/models/app_user_profile.dart';

class UserProfileRepositoryImpl implements IUserProfileRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  UserProfileRepositoryImpl(this._isar, this._supabase);

  // 1. LẤY DATA (LUÔN ƯU TIÊN LOCAL - ISAR)
  @override
  Stream<UserProfileEntity?> watchUserProfile() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(null);

    return _isar.appUserProfiles
        .filter()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true)
        .map((profiles) {
          if (profiles.isEmpty) return null;
          final p = profiles.first;
          return UserProfileEntity(
            userId: p.userId,
            firstName: p.firstName,
            lastName: p.lastName,
            avatarUrl: p.avatarUrl,
            dateOfBirth: p.dateOfBirth,
            gender: p.gender,
            bio: p.bio,
            phoneNumber: p.phoneNumber,
            address: p.address,
          );
        });
  }

  // 2. CẬP NHẬT (LƯU LOCAL + ĐẨY LÊN SUPABASE)
  @override
  Future<void> updateUserProfile(UserProfileEntity entity) async {
    final oldProfile = await _isar.appUserProfiles
        .filter()
        .userIdEqualTo(entity.userId)
        .findFirst();

    final newProfile = oldProfile ?? AppUserProfile();
    newProfile.userId = entity.userId;
    newProfile.firstName = entity.firstName;
    newProfile.lastName = entity.lastName;
    newProfile.avatarUrl = entity.avatarUrl;
    newProfile.dateOfBirth = entity.dateOfBirth;
    newProfile.gender = entity.gender;
    newProfile.bio = entity.bio;
    newProfile.phoneNumber = entity.phoneNumber;
    newProfile.address = entity.address;
    newProfile.updatedAt = DateTime.now();
    newProfile.isSynced = false;

    // Lưu vào Isar Database (trên điện thoại)
    await _isar.writeTxn(() async {
      await _isar.appUserProfiles.put(newProfile);
    });

    // Gọi hàm push chạy ngầm
    _pushToSupabase(newProfile);
  }

  // 3. ĐỒNG BỘ: KÉO TỪ SERVER VỀ
  @override
  Future<void> syncProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('user_profile')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final existing = await _isar.appUserProfiles
            .filter()
            .userIdEqualTo(userId)
            .findFirst();

        final cloudDateStr = response['updated_at'];
        final cloudUpdatedAt = cloudDateStr != null 
            ? DateTime.tryParse(cloudDateStr.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.fromMillisecondsSinceEpoch(0);

        if (existing == null || existing.updatedAt.isBefore(cloudUpdatedAt)) {
          final p = existing ?? AppUserProfile();
          p.userId = response['id'];
          p.firstName = response['first_name'];
          p.lastName = response['last_name'];
          p.avatarUrl = response['avatar_url'];
          
          if (response['date_of_birth'] != null) {
            p.dateOfBirth = DateTime.tryParse(response['date_of_birth']);
          }
          p.gender = response['gender'];
          p.bio = response['bio'];
          p.phoneNumber = response['phone_number'];
          p.address = response['address'];

          p.updatedAt = cloudUpdatedAt;
          p.isSynced = true;

          await _isar.writeTxn(() async {
            await _isar.appUserProfiles.put(p);
          });
        }
      }
    } catch (e) {
      debugPrint('Sync Profile 🔴 ERROR: $e');
    }
  }

  // 4. HÀM ĐẨY (BACKGROUND)
  Future<void> _pushToSupabase(AppUserProfile p) async {
    try {
      final data = {
        'id': p.userId, // Khóa chính trên Supabase là id (chính là user uuid)
        'first_name': p.firstName,
        'last_name': p.lastName,
        'avatar_url': p.avatarUrl,
        'date_of_birth': p.dateOfBirth?.toIso8601String(),
        'gender': p.gender,
        'bio': p.bio,
        'phone_number': p.phoneNumber,
        'address': p.address,
        'updated_at': p.updatedAt.toIso8601String(),
      };

      await _supabase.from('user_profile').upsert(data);
      
      p.isSynced = true;
      await _isar.writeTxn(() async {
        await _isar.appUserProfiles.put(p);
      });
    } catch (e) {
      debugPrint('Push Profile 🔴 ERROR: $e');
    }
  }
}
