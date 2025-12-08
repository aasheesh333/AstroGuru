import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkFlow();
  }

  void _checkFlow() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final bool languageSelected = prefs.getBool('language_selected') ?? false;
    final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    final bool userLoggedIn = prefs.getBool('user_logged_in') ?? false;

    if (mounted) {
      if (!languageSelected) {
        Navigator.pushReplacementNamed(context, '/language');
      } else if (!onboardingSeen) {
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
             Image.asset('assets/images/logo.png', width: 150),
             const SizedBox(height: 20),
             const Text("AstroPrerna", style: TextStyle(color: Color(0xFFFDBD00), fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
