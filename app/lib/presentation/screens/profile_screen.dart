import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(supabaseProvider).auth.currentUser;
    final lang = ref.watch(languageProvider); 

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor, width: 2),
              ),
              child: const CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(
                  'https://thf.bing.com/th/id/OIP.NifcFumqU3GDz-nL_NKS-AHaE-?o=7&cb=thfc1rm=3&rs=1&pid=ImgDetMain&o=7&rm=3',
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? AppTranslations.getText(lang, 'unknown_user'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.getText(lang, 'premium_member'),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),

            _buildSettingItem(
              context,
              Icons.person_outline_rounded,
              AppTranslations.getText(lang, 'account_settings'),
            ),

            _buildSettingItem(
              context,
              Icons.language_rounded,
              AppTranslations.getText(lang, 'language'),
              onTap: () {
                // Chuyển đổi qua lại giữa 'vi' và 'en'
                ref.read(languageProvider.notifier).state = lang == 'vi'
                    ? 'en'
                    : 'vi';
              },
            ),

            _buildSettingItem(
              context,
              Icons.security_rounded,
              AppTranslations.getText(lang, 'security_faceid'),
            ),
            _buildSettingItem(
              context,
              Icons.notifications_none_rounded,
              AppTranslations.getText(lang, 'notifications'),
            ),
            _buildSettingItem(
              context,
              Icons.help_outline_rounded,
              AppTranslations.getText(lang, 'help_support'),
            ),
            const SizedBox(height: 48),
            _buildSettingItem(
              context,
              Icons.logout_rounded,
              AppTranslations.getText(lang, 'logout'),
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