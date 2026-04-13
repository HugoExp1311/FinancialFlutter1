class UserProfileEntity {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bio;
  final String? phoneNumber;
  final String? address;

  UserProfileEntity({
    required this.userId,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.phoneNumber,
    this.address,
  });
}
