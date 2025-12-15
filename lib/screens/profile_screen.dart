import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../logic/language_provider.dart';
import '../logic/user_provider.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/gradient_button.dart';
import '../theme/app_colors.dart';

// ProfileScreen wrapper (not used by MainScreen but kept for completeness or direct nav)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.profile)),
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
  // String userName = "Loading...";
  // String userIdentifier = ""; // Phone or Email
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuest();
  }

  void _checkGuest() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
       setState(() {
         isGuest = prefs.getBool('guest_mode') ?? false;
       });
       if (!isGuest) {
         Provider.of<UserProvider>(context, listen: false).loadUserData();
       }
    }
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
        title: Text(AppLocalizations.of(context)!.loginRequiredTitle, style: const TextStyle(color: Color(0xFFD4AF37))),
        content: Text(AppLocalizations.of(context)!.loginRequiredMsg, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: Text(AppLocalizations.of(context)!.loginNow),
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
                Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    ImageProvider? img;
                    if (provider.profileImageBase64 != null) {
                       img = MemoryImage(base64Decode(provider.profileImageBase64!));
                    }

                    return Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceColor,
                            border: Border.all(color: AppColors.primaryGold, width: 2),
                            image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
                          ),
                          child: img == null ? const Icon(Icons.person, size: 50, color: AppColors.textPrimary) : null,
                        ),
                        const SizedBox(height: 16),

                        // Auto-scaling, centered, single-line name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isGuest ? AppLocalizations.of(context)!.guestUser : provider.name,
                              style: Theme.of(context).textTheme.displayMedium,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        if (!isGuest)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              provider.email,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                      ],
                    );
                  }
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
                  title: AppLocalizations.of(context)!.editProfile,
                  onTap: isGuest ? _showLoginDialog : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                    // Provider updates automatically via EditProfileScreen logic
                  },
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.language,
                  title: AppLocalizations.of(context)!.languageSettings,
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
                              DropdownMenuItem(value: Locale('hi'), child: Text("हिन्दी")), // Hindi
                              DropdownMenuItem(value: Locale('bn'), child: Text("বাংলা")), // Bengali
                              DropdownMenuItem(value: Locale('mr'), child: Text("मराठी")), // Marathi
                              DropdownMenuItem(value: Locale('ta'), child: Text("தமிழ்")), // Tamil
                              DropdownMenuItem(value: Locale('te'), child: Text("తెలుగు")), // Telugu
                              DropdownMenuItem(value: Locale('gu'), child: Text("ગુજરાતી")), // Gujarati
                              DropdownMenuItem(value: Locale('pa'), child: Text("ਪੰਜਾਬੀ")), // Punjabi
                              DropdownMenuItem(value: Locale('kn'), child: Text("ಕನ್ನಡ")), // Kannada
                              DropdownMenuItem(value: Locale('ml'), child: Text("മലയാളം")), // Malayalam
                              DropdownMenuItem(value: Locale('or'), child: Text("ଓଡ଼ିଆ")), // Odia
                              DropdownMenuItem(value: Locale('as'), child: Text("অসমীয়া")), // Assamese
                              DropdownMenuItem(value: Locale('ur'), child: Text("اردو")), // Urdu
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                provider.setLocale(val);
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.surfaceColor,
                                    title: Text(AppLocalizations.of(context)!.languageChanged, style: const TextStyle(color: AppColors.primaryGold)),
                                    content: Text(AppLocalizations.of(context)!.restartMsg, style: const TextStyle(color: Colors.white)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: AppColors.primaryGold)),
                                      ),
                                    ],
                                  ),
                                );
                              }
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
                  title: AppLocalizations.of(context)!.rateApp,
                  onTap: () {},
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.privacy_tip_outlined,
                  title: AppLocalizations.of(context)!.privacyPolicy,
                  onTap: () {},
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.headset_mic_outlined,
                  title: AppLocalizations.of(context)!.helpSupport,
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GradientButton(
              text: isGuest ? AppLocalizations.of(context)!.loginToUnlock : AppLocalizations.of(context)!.logout,
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
