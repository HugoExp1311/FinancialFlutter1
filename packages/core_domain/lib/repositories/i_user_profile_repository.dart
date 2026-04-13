import '../entities/user_profile_entity.dart';

abstract class IUserProfileRepository {
  Stream<UserProfileEntity?> watchUserProfile();
  Future<void> updateUserProfile(UserProfileEntity entity);
  Future<void> syncProfile();
}
