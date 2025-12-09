import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Timer
import 'onboarding_screen.dart';
import 'login_screen.dart';

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
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
      final bool userLoggedIn = prefs.getBool('user_logged_in') ?? false;
      final bool guestMode = prefs.getBool('guest_mode') ?? false;

      if (!mounted) return;

      if (!onboardingSeen) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      } else if (userLoggedIn || guestMode) {
        // If logged in OR guest mode, go to Home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Seen onboarding but not logged in/guest -> Login
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      debugPrint("Error in SplashScreen: $e");
      if (mounted) {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
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
             Image.asset('assets/images/logo.png', width: 150),
             const SizedBox(height: 20),
             const Text("AstroPrerna", style: TextStyle(color: Color(0xFFFDBD00), fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
