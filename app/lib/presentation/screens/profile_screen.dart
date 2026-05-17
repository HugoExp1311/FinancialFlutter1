import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải ảnh lên... ⏳')),
        );
      }

      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '/$fileName';

      await Supabase.instance.client.storage.from('avatar').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = Supabase.instance.client.storage.from('avatar').getPublicUrl(path);

      await Supabase.instance.client.from('user_profile').upsert({
        'id': userId,
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(profileProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật Avatar thành công! 📸')),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // --- LOGIC: ACCOUNT SETTINGS  ---
  void _showAccountSettings(BuildContext context, WidgetRef ref, Map<String, dynamic>? currentProfile) {
    final firstNameController = TextEditingController(text: currentProfile?['first_name'] ?? '');
    final lastNameController = TextEditingController(text: currentProfile?['last_name'] ?? '');
    final phoneController = TextEditingController(text: currentProfile?['phone_number'] ?? '');
    final dobController = TextEditingController(text: currentProfile?['date_of_birth'] ?? '');
    
    String? selectedGender = currentProfile?['gender'];
    final List<String> genderOptions = ['Male', 'Female', 'Unknown'];
    if (selectedGender != null && !genderOptions.contains(selectedGender)) {
      selectedGender = 'Unknown';
    }

    InputDecoration customInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    const Text('Account Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: TextField(controller: firstNameController, decoration: customInputDecoration('First Name', Icons.person_outline))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: lastNameController, decoration: customInputDecoration('Last Name', Icons.badge_outlined))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: customInputDecoration('Phone Number', Icons.phone_outlined)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: dobController, readOnly: true,
                            decoration: customInputDecoration('Date of Birth', Icons.calendar_today_rounded),
                            onTap: () async {
                              final pickedDate = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                              if (pickedDate != null) {
                                setState(() => dobController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}");
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedGender,
                            decoration: customInputDecoration('Gender', Icons.wc_outlined).copyWith(prefixIcon: null),
                            items: genderOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                            onChanged: (v) => setState(() => selectedGender = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              if (selectedGender != null) 'gender': selectedGender,
                              if (dobController.text.trim().isNotEmpty) 'date_of_birth': dobController.text.trim(),
                              'updated_at': DateTime.now().toIso8601String(),
                            });

                            ref.invalidate(profileProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công! 🎉')));
                            }
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // --- LOGIC: SECURITY & FACE ID ---
  void _showSecuritySettings(BuildContext context, WidgetRef ref) {
    bool isAppLockEnabled = false;
    bool isBiometricEnabled = false;
    bool isHideBalanceEnabled = ref.read(hideBalanceProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Security & FaceID', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero, activeColor: AppTheme.primaryColor,
                    secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.password_rounded, color: Colors.orange)),
                    title: const Text('Mã PIN ứng dụng', style: TextStyle(fontWeight: FontWeight.w500)), subtitle: const Text('Yêu cầu nhập PIN khi mở app'),
                    value: isAppLockEnabled, onChanged: (v) => setState(() { isAppLockEnabled = v; if (!v) isBiometricEnabled = false; }),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero, activeColor: AppTheme.primaryColor,
                    secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.green)),
                    title: const Text('Xác thực FaceID / TouchID', style: TextStyle(fontWeight: FontWeight.w500)), subtitle: const Text('Mở khóa nhanh bằng sinh trắc học'),
                    value: isBiometricEnabled, onChanged: isAppLockEnabled ? (v) => setState(() => isBiometricEnabled = v) : null, 
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero, activeColor: AppTheme.primaryColor,
                    secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.visibility_off_rounded, color: Colors.purple)),
                    title: const Text('Ẩn số dư mặc định', style: TextStyle(fontWeight: FontWeight.w500)), subtitle: const Text('Làm mờ số tiền ở màn hình Home'),
                    value: isHideBalanceEnabled,
                    onChanged: (v) {
                      setState(() => isHideBalanceEnabled = v);
                      ref.read(hideBalanceProvider.notifier).state = v;
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- LOGIC: HIỆN MODAL CÀI ĐẶT THÔNG BÁO ---
  void _showNotificationsSettings(BuildContext context) {
    bool isDailyReminderEnabled = true;
    bool isBudgetAlertEnabled = true;
    bool isPromoEnabled = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero, activeColor: AppTheme.primaryColor,
                    secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.access_alarm_rounded, color: AppTheme.primaryColor)),
                    title: const Text('Nhắc nhở hàng ngày', style: TextStyle(fontWeight: FontWeight.w500)), subtitle: const Text('Nhắc bạn ghi chép vào 20:00 mỗi tối'),
                    value: isDailyReminderEnabled, onChanged: (v) => setState(() => isDailyReminderEnabled = v),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero, activeColor: AppTheme.primaryColor,
                    secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.expenseColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: AppTheme.expenseColor)),
                    title: const Text('Cảnh báo vượt ngân sách', style: TextStyle(fontWeight: FontWeight.w500)), subtitle: const Text('Gửi thông báo khi chi tiêu sắp vượt hạn mức'),
                    value: isBudgetAlertEnabled, onChanged: (v) => setState(() => isBudgetAlertEnabled = v),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero, activeColor: AppTheme.primaryColor,
                    secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.campaign_outlined, color: Colors.blue)),
                    title: const Text('Cập nhật hệ thống & Tin tức', style: TextStyle(fontWeight: FontWeight.w500)), subtitle: const Text('Nhận thông báo về tính năng mới'),
                    value: isPromoEnabled, onChanged: (v) => setState(() => isPromoEnabled = v),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- LOGIC: HIỆN MODAL HELP & SUPPORT ---
  void _showHelpAndSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(), // Bấm ra vùng xám để đóng
          child: GestureDetector(
            onTap: () {}, // Chặn đóng khi bấm nhầm vào nền trắng
            child: DraggableScrollableSheet(
              initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,     
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      const Text('Help & Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            const Text('Câu hỏi thường gặp (FAQ)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            const ExpansionTile(title: Text('Làm sao để thêm giao dịch mới?', style: TextStyle(fontWeight: FontWeight.w500)), children: [Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text('Nhấn vào nút "+" màu xanh ở giữa thanh công cụ bên dưới để thêm thu nhập hoặc chi phí.'))]),
                            const ExpansionTile(title: Text('Dữ liệu của tôi có được đồng bộ không?', style: TextStyle(fontWeight: FontWeight.w500)), children: [Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text('Có, ứng dụng tự động lưu trữ cục bộ và đồng bộ an toàn lên đám mây mỗi khi có mạng.'))]),
                            const ExpansionTile(title: Text('Cách thay đổi ảnh đại diện?', style: TextStyle(fontWeight: FontWeight.w500)), children: [Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text('Trong màn hình Profile, bạn chỉ cần nhấn trực tiếp vào Avatar hiện tại để tải ảnh mới lên.'))]),
                            
                            const SizedBox(height: 32),
                            const Text('Liên hệ hỗ trợ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            ListTile(contentPadding: EdgeInsets.zero, leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.email_outlined, color: AppTheme.primaryColor)), title: const Text('Gửi Email'), subtitle: const Text('support@financeapp.com')),
                            ListTile(contentPadding: EdgeInsets.zero, leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.phone_in_talk_outlined, color: AppTheme.primaryColor)), title: const Text('Hotline'), subtitle: const Text('1900 1234 (Miễn phí)')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final lang = ref.watch(languageProvider);

    return profileAsync.when(
      data: (profile) {
        final String firstName = profile?['first_name'] as String? ?? '';
        final String lastName = profile?['last_name'] as String? ?? '';
        String displayName = '$firstName $lastName'.trim();
        if (displayName.isEmpty) displayName = user?.email?.split('@')[0] ?? AppTranslations.getText(lang, 'unknown_user');
        final String avatarUrl = (profile?['avatar_url'] as String?) ?? 'https://i.pravatar.cc/150?img=11';

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _pickAndUploadAvatar(context, ref),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryColor, width: 2)),
                        child: CircleAvatar(radius: 48, backgroundImage: NetworkImage(avatarUrl), backgroundColor: Colors.transparent),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 8),
                Text(AppTranslations.getText(lang, 'premium_member'), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 40),

                _buildSettingItem(context, Icons.person_outline_rounded, AppTranslations.getText(lang, 'account_settings'), onTap: () => _showAccountSettings(context, ref, profile)),
                
                // MỤC CHỌN NGÔN NGỮ (Tự động quy định tiền tệ)
                _buildSettingItem(
                  context, 
                  Icons.language_rounded, 
                  AppTranslations.getText(lang, 'language'),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: lang,
                      dropdownColor: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                      ],
                      onChanged: (String? newLang) {
                        if (newLang != null) {
                          ref.read(languageProvider.notifier).state = newLang;
                        }
                      },
                    ),
                  ),
                ),

                _buildSettingItem(context, Icons.security_rounded, AppTranslations.getText(lang, 'security_faceid'), onTap: () => _showSecuritySettings(context, ref)),
                _buildSettingItem(context, Icons.notifications_none_rounded, AppTranslations.getText(lang, 'notifications'), onTap: () => _showNotificationsSettings(context)),
                _buildSettingItem(context, Icons.help_outline_rounded, AppTranslations.getText(lang, 'help_support'), onTap: () => _showHelpAndSupport(context)),
                const SizedBox(height: 32),
                
                _buildSettingItem(context, Icons.logout_rounded, AppTranslations.getText(lang, 'logout'), isDanger: true, onTap: () async {
                  final isar = ref.read(isarProvider);
                  await isar.writeTxn(() async {
                    await isar.clear();
                  });
                  
                  ref.invalidate(profileProvider);
                  ref.invalidate(transactionsStreamProvider);
                  ref.invalidate(walletsStreamProvider);

                  await Supabase.instance.client.auth.signOut();
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, {String? subtitle, bool isDanger = false, VoidCallback? onTap, Widget? trailing}) {
    final color = isDanger ? Colors.redAccent : Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          onTap: trailing != null ? null : (onTap ?? () {}),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isDanger ? Colors.red.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: Icon(icon, color: isDanger ? Colors.redAccent : AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color)),
                      if (subtitle != null) ...[
                        const Spacer(),
                        Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (trailing != null)
                  trailing
                else if (!isDanger)
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}