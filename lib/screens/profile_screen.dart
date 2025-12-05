import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surfaceColor,
              child: Icon(Icons.person, size: 50, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'User Name',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '+91 98765 43210',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Options
            _buildProfileOption(context, 'Edit Profile', Icons.edit_outlined),
            _buildProfileOption(context, 'Language Settings', Icons.language),
            _buildProfileOption(context, 'Rate App', Icons.star_outline),
            _buildProfileOption(context, 'Privacy Policy', Icons.privacy_tip_outlined),
            _buildProfileOption(context, 'Help & Support', Icons.headset_mic_outlined),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GradientButton(
                text: 'Log Out',
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryGold),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
      onTap: () {},
    );
  }
}
