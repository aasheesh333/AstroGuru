import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
        backgroundColor: const AppColors.surfaceColor,
        title: Text(AppLocalizations.of(context)!.loginRequiredTitle, style: const TextStyle(color: AppColors.deepGold)),
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

  Future<void> _launch(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open link.")));
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open link.")));
      }
    }
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
                    final url = provider.profileImageUrl;
                    final b64 = provider.profileImageBase64;
                    return Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceColor,
                            border: Border.all(color: AppColors.primaryGold, width: 2),
                          ),
                          child: ClipOval(
                            child: _ProfileImage(url: url, base64: b64, size: 100),
                          ),
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
              color: AppColors.surfaceColor.withValues(alpha: 0.8),
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
                  icon: Icons.privacy_tip_outlined,
                  title: AppLocalizations.of(context)!.privacyPolicy,
                  onTap: () => _launch("https://dhanuk.page.gd/AstroPrerna/Privacy-Policy.html"),
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.description_outlined,
                  title: "Terms & Conditions",
                  onTap: () => _launch("https://dhanuk.page.gd/AstroPrerna/Terms-and-Conditions.html"),
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.headset_mic_outlined,
                  title: AppLocalizations.of(context)!.helpSupport,
                  onTap: () => _launch("https://dhanuk.page.gd/AstroPrerna/Help-and-Support.html"),
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.star_border,
                  title: AppLocalizations.of(context)!.rateApp,
                  onTap: _requestInAppReview,
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.feedback_outlined,
                  title: AppLocalizations.of(context)!.sendFeedback,
                  onTap: () => _launch(
                    "mailto:Aasheeshkatheriya@gmail.com?subject=${AppLocalizations.of(context)!.feedbackSubject}&body=${AppLocalizations.of(context)!.feedbackBody}",
                  ),
                ),
                const Divider(color: AppColors.scaffoldBackgroundColor),
                _buildProfileItem(
                  icon: Icons.info_outline,
                  title: AppLocalizations.of(context)!.about,
                  onTap: _showAboutDialog,
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

  Future<void> _requestInAppReview() async {
    // Reuse the rateApp gate: only ask the user once per 90 days.
    final prefs = await SharedPreferences.getInstance();
    final lastAsked = prefs.getInt('last_review_asked_at') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastAsked < const Duration(days: 90).inMilliseconds) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackThanks)),
      );
      return;
    }
    try {
      await InAppReview.instance.requestReview();
      await prefs.setInt('last_review_asked_at', now);
    } catch (e) {
      // InAppReview may not be available on all devices/emulators.
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ratingDialogFailed)),
      );
    }
  }

  Future<void> _showAboutDialog() async {
    String version = "—";
    String build = "—";
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      build = info.buildNumber;
    } catch (_) {
      // Keep the placeholder values if PackageInfo fails.
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text(
          'AstroPrerna',
          style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your personal AI-powered Vedic astrology companion.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appVersion(version, build),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2026 AstroPrerna',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.ok,
              style: const TextStyle(color: AppColors.primaryGold),
            ),
          ),
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

/// Shared widget that renders a user profile image: prefer the Firebase
/// Storage download URL, fall back to the legacy base64 string, fall back to
/// a default person icon.
class _ProfileImage extends StatelessWidget {
  final String? url;
  final String? base64;
  final double size;

  const _ProfileImage({required this.url, required this.base64, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (ctx, _) => Container(
          width: size,
          height: size,
          color: AppColors.surfaceColor,
        ),
        errorWidget: (ctx, _, __) => _fallback(base64),
      );
    }
    return _fallback(base64);
  }

  Widget _fallback(String? b64) {
    if (b64 != null && b64.isNotEmpty) {
      try {
        return Image.memory(base64Decode(b64), width: size, height: size, fit: BoxFit.cover);
      } catch (_) {
        return _placeholder();
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceColor,
      child: const Icon(Icons.person, size: 50, color: AppColors.textPrimary),
    );
  }
}
