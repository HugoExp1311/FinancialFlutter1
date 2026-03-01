import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  'https://i.pravatar.cc/150?img=11',
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alex Johnson',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
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
  }) {
    final color = isDanger
        ? AppTheme.expenseColor
        : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: () {},
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
