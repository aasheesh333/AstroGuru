import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../logic/language_provider.dart';
import 'login_screen.dart';
import '../widgets/gradient_button.dart';
import '../theme/app_colors.dart';

// ProfileScreen wrapper (not used by MainScreen but kept for completeness or direct nav)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: const ProfileContent(),
    );
  }
}

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  String userName = "Loading...";
  String userIdentifier = ""; // Phone or Email
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      isGuest = prefs.getBool('guest_mode') ?? false;
      if (isGuest) {
        userName = "Guest User";
        userIdentifier = "";
      } else {
        userName = prefs.getString('user_name') ?? "User";
        // Prefer email, fallback to phone
        String email = prefs.getString('user_email') ?? "";
        String phone = prefs.getString('user_phone') ?? "";
        userIdentifier = email.isNotEmpty ? email : phone;
      }
    });
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear Session
    await prefs.setBool('user_logged_in', false);
    await prefs.setBool('guest_mode', false);
    await prefs.remove('user_phone');
    await prefs.remove('user_email');
    await prefs.remove('user_name');

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      // Ignore errors
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1016),
        title: const Text("Login Required", style: TextStyle(color: Color(0xFFD4AF37))),
        content: const Text("Please log in with phone number to unlock this feature.", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Log in Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceColor,
                    border: Border.all(color: AppColors.primaryGold, width: 2),
                  ),
                  child: const Icon(Icons.person, size: 50, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                if (!isGuest && userIdentifier.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      userIdentifier,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),

          // Options List
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildProfileItem(
                  icon: Icons.edit,
                  title: "Edit Profile",
                  onTap: isGuest ? _showLoginDialog : () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit Profile logic not implemented yet.")));
                  },
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.language,
                  title: "Language Settings",
                  trailing: SizedBox(
                    width: 120,
                    child: Consumer<LanguageProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<Locale>(
                            value: provider.locale,
                            isExpanded: true,
                            dropdownColor: AppColors.surfaceColor,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGold),
                            style: const TextStyle(color: AppColors.textPrimary),
                            items: const [
                              DropdownMenuItem(value: Locale('en'), child: Text("English")),
                              DropdownMenuItem(value: Locale('hi'), child: Text("Hindi")),
                              DropdownMenuItem(value: Locale('bn'), child: Text("Bengali")),
                              DropdownMenuItem(value: Locale('mr'), child: Text("Marathi")),
                              DropdownMenuItem(value: Locale('ta'), child: Text("Tamil")),
                              DropdownMenuItem(value: Locale('te'), child: Text("Telugu")),
                              DropdownMenuItem(value: Locale('gu'), child: Text("Gujarati")),
                              DropdownMenuItem(value: Locale('pa'), child: Text("Punjabi")),
                              DropdownMenuItem(value: Locale('kn'), child: Text("Kannada")),
                              DropdownMenuItem(value: Locale('ml'), child: Text("Malayalam")),
                              DropdownMenuItem(value: Locale('or'), child: Text("Odia")),
                              DropdownMenuItem(value: Locale('as'), child: Text("Assamese")),
                              DropdownMenuItem(value: Locale('ur'), child: Text("Urdu")),
                            ],
                            onChanged: (val) {
                              if (val != null) provider.setLocale(val);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.star_rate_rounded,
                  title: "Rate App",
                  onTap: () {},
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  onTap: () {},
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.headset_mic_outlined,
                  title: "Help & Support",
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GradientButton(
              text: isGuest ? "Log in to unlock full features" : "Log Out",
              onPressed: _handleLogout,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryGold, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
