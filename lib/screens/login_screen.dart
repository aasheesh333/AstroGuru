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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Auth State
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final auth = await _ensureAuthInitialized();
    if (auth == null) {
      setState(() => _isLoading = false);
      return;
    }

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (_isSignUp && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your full name")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (_isSignUp) {
        // Sign Up
        UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;
        if (user != null) {
          await user.updateDisplayName(name);
          await user.sendEmailVerification();

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF0E1016),
                title: const Text("Verify Email", style: TextStyle(color: Color(0xFFD4AF37))),
                content: const Text(
                  "A verification link has been sent to your email. Please verify it and then log in.",
                  style: TextStyle(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      setState(() {
                        _isSignUp = false; // Switch to login mode
                        _passwordController.clear();
                      });
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // Log In
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? user = userCredential.user;

        if (user != null) {
          if (!user.emailVerified) {
             await user.reload(); // Refresh user data to check verification status again
             if (!auth.currentUser!.emailVerified) {
               if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0E1016),
                    title: const Text("Email Not Verified", style: TextStyle(color: Color(0xFFD4AF37))),
                    content: const Text(
                      "Please verify your email address to continue.",
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                           Navigator.pop(context);
                           await user.sendEmailVerification();
                           if(mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Verification link resent.")),
                             );
                           }
                        },
                        child: const Text("Resend Link"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
               }
               setState(() => _isLoading = false);
               return;
             }
          }
          await _onAuthSuccess(user);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Authentication failed";
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAuthSuccess(User? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_logged_in', true);
    await prefs.setBool('guest_mode', false);
    await prefs.setString('user_email', user?.email ?? "");
    await prefs.setString('user_phone', user?.phoneNumber ?? ""); // Keep for consistency if needed later

    // Store Name
    String displayName = user?.displayName ?? _nameController.text;
    if (displayName.isEmpty) displayName = "User";
    await prefs.setString('user_name', displayName);

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
                    _isSignUp ? 'Create Account' : 'Welcome Back',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                      ? 'Sign up to unlock all features'
                      : 'Log in with your email',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  if (_isSignUp) ...[
                     TextField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.person, color: AppColors.primaryGold),
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
                    const SizedBox(height: 16),
                  ],

                  // Email Input
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'you@example.com',
                      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.email, color: AppColors.primaryGold),
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

                  const SizedBox(height: 16),

                  // Password Input
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.lock, color: AppColors.primaryGold),
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

                  const SizedBox(height: 32),

                  // Action Button
                  GradientButton(
                    text: _isSignUp ? 'Sign Up' : 'Log In',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        // Clear controllers when switching? Maybe not for UX.
                      });
                    },
                    child: Text(
                      _isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up",
                      style: const TextStyle(color: AppColors.primaryGold),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Skip Button
                  if (!_isSignUp)
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
