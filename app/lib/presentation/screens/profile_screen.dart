import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Đã thêm thư viện pick ảnh
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // --- LOGIC: CHỌN VÀ UPLOAD AVATAR ---
  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Chọn ảnh từ Gallery (có thể đổi thành ImageSource.camera nếu muốn chụp)
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return; // Người dùng huỷ chọn ảnh

      // Hiển thị loading (tùy chọn)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải ảnh lên... ⏳')),
        );
      }

      // Đọc byte của ảnh để upload (Hỗ trợ tốt trên cả Windows/Web/Mobile)
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '/$fileName'; // Lưu vào thư mục gốc của bucket

      // Upload lên Supabase Storage 
      await Supabase.instance.client.storage.from('avatar').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      // Lấy link public của ảnh vừa tải lên
      final imageUrl = Supabase.instance.client.storage.from('avatar').getPublicUrl(path);

      // Cập nhật lại cột avatar_url trong bảng user_profile
      await Supabase.instance.client.from('user_profile').upsert({
        'id': userId,
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Tải lại dữ liệu Provider
      ref.invalidate(profileProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật Avatar thành công! 📸')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi upload avatar: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- LOGIC: HIỆN MODAL ĐỂ CẬP NHẬT ACCOUNT SETTINGS ---
  void _showAccountSettings(BuildContext context, WidgetRef ref, Map<String, dynamic>? currentProfile) {
    final firstNameController = TextEditingController(text: currentProfile?['first_name'] ?? '');
    final lastNameController = TextEditingController(text: currentProfile?['last_name'] ?? '');
    final phoneController = TextEditingController(text: currentProfile?['phone_number'] ?? '');
    final addressController = TextEditingController(text: currentProfile?['address'] ?? '');
    final bioController = TextEditingController(text: currentProfile?['bio'] ?? '');
    final dobController = TextEditingController(text: currentProfile?['date_of_birth'] ?? '');
    
    // Biến lưu trạng thái Dropdown
    String? selectedGender = currentProfile?['gender'];
    final List<String> genderOptions = ['Male', 'Female', 'Unknown'];
    // Đảm bảo giá trị khởi tạo hợp lệ
    if (selectedGender != null && !genderOptions.contains(selectedGender)) {
      selectedGender = 'Unknown';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Dùng StatefulBuilder để form có thể setState cập nhật Dropdown/Date picker
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // --- DATE OF BIRTH (DATE PICKER) ---
                        Expanded(
                          child: TextField(
                            controller: dobController,
                            readOnly: true, // Không cho gõ tay
                            decoration: InputDecoration(
                              labelText: 'DOB',
                              hintText: 'YYYY-MM-DD',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixIcon: const Icon(Icons.calendar_today_rounded),
                            ),
                            onTap: () async {
                              // Gọi hàm chọn ngày của Flutter
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000), // Mặc định mở ở năm 2000
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                // Format ngày về dạng yyyy-mm-dd
                                String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                setState(() {
                                  dobController.text = formattedDate;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // --- GENDER (DROPDOWN) ---
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: genderOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedGender = newValue;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: bioController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          try {
                            final userId = Supabase.instance.client.auth.currentUser?.id;
                            if (userId == null) return;

                            await Supabase.instance.client.from('user_profile').upsert({
                              'id': userId,
                              'first_name': firstNameController.text.trim(),
                              'last_name': lastNameController.text.trim(),
                              'phone_number': phoneController.text.trim(),
                              'address': addressController.text.trim(),
                              'bio': bioController.text.trim(),
                              if (selectedGender != null) 'gender': selectedGender,
                              if (dobController.text.trim().isNotEmpty) 'date_of_birth': dobController.text.trim(),
                              'updated_at': DateTime.now().toIso8601String(),
                            });

                            ref.invalidate(profileProvider);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cập nhật thành công! 🎉')),
                              );
                            }
                          } catch (e) {
                            debugPrint("Lỗi khi lưu profile: $e");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return profileAsync.when(
      data: (profile) {
        final String firstName = profile?['first_name'] as String? ?? '';
        final String lastName = profile?['last_name'] as String? ?? '';
        String displayName = '$firstName $lastName'.trim();
        
        if (displayName.isEmpty) {
          displayName = user?.email?.split('@')[0] ?? 'Người dùng';
        }

        final String avatarUrl = (profile?['avatar_url'] as String?) ?? 
                                 'https://i.pravatar.cc/150?img=11';

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                
                // --- AVATAR BỌC TRONG GESTURE DETECTOR ĐỂ CÓ THỂ CLICK ---
                GestureDetector(
                  onTap: () {
                    // Mở menu để xác nhận việc đổi ảnh
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Chọn ảnh từ thư viện'),
                              onTap: () {
                                Navigator.pop(context); // Đóng menu
                                _pickAndUploadAvatar(context, ref); // Mở hàm tải ảnh
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: NetworkImage(avatarUrl),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      // Thêm một icon camera nhỏ ở góc cho đẹp UI
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium Member ✦',
                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 40),

                _buildSettingItem(
                  context,
                  Icons.person_outline_rounded,
                  'Account Settings',
                  onTap: () => _showAccountSettings(context, ref, profile),
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
                const SizedBox(height: 48),

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
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Lỗi tải dữ liệu: $err')),
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
    final color = isDanger ? Colors.redAccent : Theme.of(context).colorScheme.onSurface;

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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color),
              ),
            ),
            if (!isDanger)
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }
}