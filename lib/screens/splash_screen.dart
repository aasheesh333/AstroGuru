import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../logic/language_provider.dart';
// import '../l10n/app_localizations.dart'; // Removed to fix build error

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLanguage();
  }

  void _checkLanguage() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    final bool userLoggedIn = prefs.getBool('user_logged_in') ?? false;

    if (mounted) {
      if (!onboardingSeen) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else if (!userLoggedIn) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF371B58),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Use BabaAvatar here if needed, or simple text
             Image.asset('assets/images/logo.png', width: 150),
             const SizedBox(height: 20),
             const Text("AstroPrerna", style: TextStyle(color: Color(0xFFFDBD00), fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
