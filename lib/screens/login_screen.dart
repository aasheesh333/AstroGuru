import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../widgets/baba_avatar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Auth State
  bool _codeSent = false;
  String? _verificationId;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

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
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<FirebaseAuth?> _ensureAuthInitialized() async {
    if (_auth != null) return _auth;

    try {
      await Firebase.initializeApp();
      return FirebaseAuth.instance;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Firebase Init Failed: $e"),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  void _verifyPhoneNumber() async {
    setState(() => _isLoading = true);

    final auth = await _ensureAuthInitialized();
    if (auth == null) {
      setState(() => _isLoading = false);
      return;
    }

    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter phone number")),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Append +91 if missing
    if (!phone.startsWith('+')) {
      if (!phone.startsWith('91')) {
        phone = "+91$phone";
      } else {
        phone = "+$phone";
      }
    }

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android
          await auth.signInWithCredential(credential);
          await _onAuthSuccess(auth.currentUser);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification Failed: ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter 6-digit OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = await _ensureAuthInitialized();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await auth?.signInWithCredential(credential);
      await _onAuthSuccess(auth?.currentUser);

    } on FirebaseAuthException catch (e) {
       setState(() => _isLoading = false);
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Invalid OTP")),
        );
       }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _onAuthSuccess(User? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_logged_in', true);
    await prefs.setBool('guest_mode', false);
    await prefs.setString('user_phone', user?.phoneNumber ?? "");
    // Default name if not set
    if (prefs.getString('user_name') == null) {
      await prefs.setString('user_name', "User");
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BabaAvatar(size: 100),
                  const SizedBox(height: 24),
                  Text(
                    _codeSent ? 'Enter OTP' : 'Welcome to AstroPrerna',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                      ? 'We sent a code to ${_phoneController.text}'
                      : 'Log in with your phone number',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  if (!_codeSent) ...[
                    // Phone Number Input
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+91 9876543210',
                        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.phone, color: AppColors.primaryGold),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.textSecondary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.primaryGold),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ] else ...[
                    // OTP Input
                     TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'OTP',
                        counterText: "",
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.lock_clock, color: AppColors.primaryGold),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.textSecondary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.primaryGold),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action Button
                  GradientButton(
                    text: _codeSent ? 'Verify OTP' : 'Get OTP',
                    isLoading: _isLoading,
                    onPressed: _codeSent ? _verifyOtp : _verifyPhoneNumber,
                  ),

                  const SizedBox(height: 16),

                  if (_codeSent)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _codeSent = false;
                          _otpController.clear();
                        });
                      },
                      child: const Text(
                        "Change Phone Number",
                        style: TextStyle(color: AppColors.primaryGold),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Skip Button
                  if (!_codeSent)
                    TextButton(
                      onPressed: _skipLogin,
                      child: const Text(
                        'Skip for Now',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
