import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../logic/language_provider.dart';
import 'login_screen.dart';

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
  String userPhone = "";
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
        userPhone = "";
      } else {
        userName = prefs.getString('user_name') ?? "User";
        userPhone = prefs.getString('user_phone') ?? "";
      }
    });
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear Session
    await prefs.setBool('user_logged_in', false);
    await prefs.setBool('guest_mode', false);

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
        content: const Text("Please log in to edit your profile.", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Log in"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          subtitle: isGuest ? null : Text(userPhone),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text("Edit Profile"),
          onTap: isGuest ? _showLoginDialog : () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit Profile logic not implemented yet.")));
          },
        ),
        const Divider(),
        const ListTile(title: Text("Language Settings")),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Consumer<LanguageProvider>(
            builder: (context, provider, child) {
              return DropdownButton<Locale>(
                value: provider.locale,
                isExpanded: true,
                dropdownColor: const Color(0xFF0E1016),
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
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _handleLogout,
          child: Text(isGuest ? "Log in to unlock full features" : "Logout"),
        ),
      ],
    );
  }
}
