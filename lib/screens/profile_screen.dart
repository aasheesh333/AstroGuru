import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../logic/language_provider.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("user_logged_in", false);
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _launchUrl(String url) async {
     final Uri uri = Uri.parse(url);
     if (!await launchUrl(uri)) {
       // Handle error
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.profile ?? "Profile"),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // User Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF1E1E2C),
              child: Icon(Icons.person, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            // User Details
            const Text(
              "User Name",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              "+91 98765 43210",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Menu Items
            _buildMenuItem(
              icon: Icons.edit,
              text: "Edit Profile",
              onTap: () {
                // Future: Navigate to edit profile
              },
            ),
            _buildMenuItem(
              icon: Icons.language,
              text: AppLocalizations.of(context)?.languageSettings ?? "Language Settings",
              onTap: () {
                Navigator.pushNamed(context, '/language');
              },
            ),
            _buildMenuItem(
              icon: Icons.star_border,
              text: "Rate App",
              onTap: () {
                // Future: Open store
              },
            ),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              text: "Privacy Policy",
              onTap: () => _launchUrl("https://example.com/privacy"),
            ),
            _buildMenuItem(
              icon: Icons.headset_mic_outlined,
              text: "Help & Support",
              onTap: () => _launchUrl("mailto:support@astroprerna.app"),
            ),

            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Log Out", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryGold, size: 20),
      ),
      title: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}
