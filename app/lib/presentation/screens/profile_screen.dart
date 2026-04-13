import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final file = File(image.path);
      final fileExt = image.path.split('.').last;

      // Khởi tạo timestamp để link hình ảnh không bị dính cache
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final path = '$userId/$fileName';

      // Upload file vào Storage bucket có tên là 'avatar'
      // YÊU CẦU: Bạn phải tạo một bucket tên là 'avatar' trong Supabase Storage và set public = true
      await supabase.storage
          .from('avatar')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = supabase.storage
          .from('avatar')
          .getPublicUrl(path);

      // Lưu publicUrl vào DB
      final repository = ref.read(userProfileRepositoryProvider);
      final currentProfileRes = await repository.watchUserProfile().first;

      final updatedEntity = UserProfileEntity(
        userId: userId,
        firstName: currentProfileRes?.firstName,
        lastName: currentProfileRes?.lastName,
        avatarUrl: publicUrl,
        dateOfBirth: currentProfileRes?.dateOfBirth,
        gender: currentProfileRes?.gender,
        bio: currentProfileRes?.bio,
        phoneNumber: currentProfileRes?.phoneNumber,
        address: currentProfileRes?.address,
      );

      await repository.updateUserProfile(updatedEntity);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(supabaseProvider).auth.currentUser;
    final userProfileAsync = ref.watch(userProfileStreamProvider);

    // Đảm bảo sync mỗi khi vào trang (nếu bạn muốn)
    // ref.read(userProfileRepositoryProvider).syncProfile();

    final profile = userProfileAsync.value;
    final avatarUrl = profile?.avatarUrl;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _pickAndUploadImage(context, ref),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.transparent,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : const NetworkImage(
                              'https://i.pravatar.cc/150?img=11',
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile?.firstName != null
                  ? '${profile?.firstName} ${profile?.lastName ?? ''}'.trim()
                  : (user?.email ?? 'Unknown User'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Premium Member ✦',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            _buildSettingItem(
              context,
              Icons.person_outline_rounded,
              'Account Settings',
            ),
            _buildSettingItem(
              context,
              Icons.security_rounded,
              'Security & FaceID',
            ),
            _buildSettingItem(
              context,
              Icons.notifications_none_rounded,
              'Notifications',
            ),
            _buildSettingItem(
              context,
              Icons.help_outline_rounded,
              'Help & Support',
            ),
            const SizedBox(
              height: 48,
            ), // Thay thế thẻ Spacer() để phù hợp với màn hình có thể cuộn
            _buildSettingItem(
              context,
              Icons.logout_rounded,
              'Log Out',
              isDanger: true,
              onTap: () async {
                final supabase = ref.read(supabaseProvider);
                final isar = ref.read(isarProvider);

                await supabase.auth.signOut();
                await isar.writeTxn(() async {
                  await isar.clear();
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    final color = isDanger
        ? AppTheme.expenseColor
        : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (!isDanger)
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}
