import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;

  void _verifyPhoneNumber() async {
    // Verified Firebase implementation with detailed logging
    String phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid phone number")));
      return;
    }

    // Ensure country code
    if (!phone.startsWith("+")) {
      phone = "+91$phone";
    }

    setState(() => _isLoading = true);
    debugPrint("Initiating phone verification for: $phone");

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint("Verification completed automatically.");
          // Auto-resolution (Instant verification)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          debugPrint("Verification failed: ${e.code} - ${e.message}");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification Failed: ${e.message}")));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("Code sent. Verification ID: $verificationId");
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("Auto retrieval timeout. Verification ID: $verificationId");
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Exception during verifyPhoneNumber: $e");
      // If Firebase is not initialized (no google-services.json), this will catch
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e. Make sure google-services.json is added.")));
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint("Sign in successful.");
      // Success
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool("user_logged_in", true);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Sign in failed: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
      }
    }
  }

  void _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.length != 6 || _verificationId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid 6-digit OTP")));
       return;
    }

    setState(() => _isLoading = true);
    debugPrint("Verifying OTP...");

    PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp);
    await _signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.stars, size: 80, color: AppColors.primaryGold),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)?.appName ?? "AstroPrerna",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 40),

            if (!_codeSent) ...[
              const Text("Enter your phone number to continue", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixText: "+91 ",
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGold)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPhoneNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Get OTP", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              const Text("Enter the 6-digit OTP sent to your phone", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 5),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  counterText: "",
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGold)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Verify & Login", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => setState(() { _codeSent = false; _isLoading = false; }),
                child: const Text("Change Phone Number", style: TextStyle(color: AppColors.primaryGold)),
              )
            ],
          ],
        ),
      ),
    );
  }
}
