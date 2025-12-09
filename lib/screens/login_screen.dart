import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Import needed for Firebase.apps check
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../widgets/baba_avatar.dart';
import 'main_screen.dart'; // Import MainScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Removed field initialization to prevent crash if Firebase isn't initialized

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;

  // Helper to safely access FirebaseAuth
  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }

  void _skipLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_logged_in', false);
    await prefs.setBool('guest_mode', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home'); // Navigate to MainScreen
    }
  }

  void _startPhoneAuth() async {
    // Check if Firebase is ready before showing dialog
    if (_auth == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0E1016),
          title: const Text("Configuration Error", style: TextStyle(color: Color(0xFFD4AF37))),
          content: const Text(
            "Firebase is not initialized. Phone login is disabled in this environment. Please use 'Skip for Now'.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Show phone number input dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1016),
        title: const Text("Enter Phone Number", style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: "+91...",
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyPhoneNumber(_phoneController.text.trim());
            },
            child: const Text("Send OTP"),
          ),
        ],
      ),
    );
  }

  void _verifyPhoneNumber(String phoneNumber) async {
    final auth = _auth;
    if (auth == null) return; // Should have been caught by _startPhoneAuth

    if (phoneNumber.isEmpty) return;
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = "+91$phoneNumber"; // Default to India if no code
    }

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential);
          _onLoginSuccess(phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Verification Failed: ${e.message}")),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          _showOtpDialog(phoneNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showOtpDialog(String phoneNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1016),
        title: const Text("Enter OTP", style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "######",
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signInWithOTP(phoneNumber);
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  void _signInWithOTP(String phoneNumber) async {
    final auth = _auth;
    if (auth == null) return;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await auth.signInWithCredential(credential);
      _onLoginSuccess(phoneNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid OTP: $e")),
        );
      }
    }
  }

  void _onLoginSuccess(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_logged_in', true);
    await prefs.setBool('guest_mode', false);
    await prefs.setString('user_phone', phoneNumber);
    await prefs.setString('user_name', "User"); // Default name

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home'); // Navigate to MainScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Center(child: BabaAvatar(size: 120)),
                const SizedBox(height: 32),
                Text(
                  'Welcome to AstroPrerna',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your personal AI Astrologer guide for daily life and future predictions.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                GradientButton(
                  text: 'Continue with Phone Number',
                  onPressed: _startPhoneAuth,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _skipLogin,
                  child: Text(
                    'Skip for Now',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
