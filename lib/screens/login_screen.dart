import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../logic/user_provider.dart';
import '../widgets/baba_avatar.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;

  // Auth State
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _dobController.dispose();
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
      if (Platform.isAndroid) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyBwE74YsLUWHPW7VqXceFgAUtiACYG6rXw',
            appId: '1:10129614422:android:14fe96393d410dd465fdf7',
            messagingSenderId: '10129614422',
            projectId: 'astroprerna-7ee7c',
            storageBucket: 'astroprerna-7ee7c.firebasestorage.app',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
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

    if (_isSignUp) {
      if (!_formKey.currentState!.validate()) {
        setState(() => _isLoading = false);
        return;
      }
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your Date of Birth")),
        );
        setState(() => _isLoading = false);
        return;
      }
      final age = DateTime.now().difference(_selectedDate!).inDays / 365;
      if (age < 10) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0E1016),
              title: const Text("Age Restriction", style: TextStyle(color: Color(0xFFD4AF37))),
              content: const Text(
                "You must be at least 10 years old to sign up. Please use a guardian's account or wait until you are older.",
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
        }
        setState(() => _isLoading = false);
        return;
      }

      // Password Complexity Check
      if (password.length < 6 || !password.contains(RegExp(r'[A-Za-z]')) || !password.contains(RegExp(r'[0-9]'))) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be at least 6 characters and contain both letters and numbers.")),
        );
        setState(() => _isLoading = false);
        return;
      }
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

          await _storeUserData(name, _selectedDate!);

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

          // Check Ban Status and Deletion Request in Firestore
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;

            // 1. Check Ban
            if (data['banned'] == true) {
               final reason = data['ban_reason'] ?? "Internal Policy";
               await auth.signOut();

               if (mounted) {
                 showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0E1016),
                    title: const Text("Access Denied", style: TextStyle(color: Colors.red)),
                    content: Text(
                      "Username is banned due to internal policy.\nReason: $reason",
                      style: const TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK", style: TextStyle(color: AppColors.primaryGold)),
                      ),
                    ],
                  ),
                 );
               }
               setState(() => _isLoading = false);
               return; // Stop processing
            }

            // 2. Check Deletion Request
            if (data.containsKey('delete_requested_at')) {
               bool regain = await showDialog(
                 context: context,
                 barrierDismissible: false,
                 builder: (context) => AlertDialog(
                   backgroundColor: const Color(0xFF0E1016),
                   title: const Text("Account Scheduled for Deletion", style: TextStyle(color: Colors.red)),
                   content: const Text(
                     "You have previously requested to delete this account. You can regain access or cancel to continue deletion.",
                     style: TextStyle(color: Colors.white),
                   ),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(context, false), // Cancel Login
                       child: const Text("Cancel Login", style: TextStyle(color: Colors.red)),
                     ),
                     ElevatedButton(
                       style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
                       onPressed: () => Navigator.pop(context, true), // Regain Access
                       child: const Text("Regain Access"),
                     ),
                   ],
                 ),
               ) ?? false;

               if (regain) {
                 await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                   'delete_requested_at': FieldValue.delete()
                 });
                 // Proceed to success
               } else {
                 await auth.signOut();
                 setState(() => _isLoading = false);
                 return;
               }
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

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email to reset password")),
      );
      return;
    }

    // Rate Limiting Logic
    final prefs = await SharedPreferences.getInstance();
    List<String> attempts = prefs.getStringList('forgot_password_attempts') ?? [];
    DateTime now = DateTime.now();

    // Filter attempts within last 24 hours
    List<String> recentAttempts = attempts.where((ts) {
      try {
        DateTime attemptTime = DateTime.parse(ts);
        return now.difference(attemptTime).inHours < 24;
      } catch (e) {
        return false;
      }
    }).toList();

    if (recentAttempts.length >= 5) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0E1016),
            title: const Text("Limit Exceeded", style: TextStyle(color: Colors.red)),
            content: const Text(
              "You have exceeded the maximum number of password reset attempts. Please try again after 24 hours.",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: AppColors.primaryGold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Record attempt
      recentAttempts.add(now.toIso8601String());
      await prefs.setStringList('forgot_password_attempts', recentAttempts);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent. Check your inbox.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Error sending reset email";
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _storeUserData(String name, DateTime dob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_dob', dob.toIso8601String());

    // Calculate Zodiac
    String zodiac = _getZodiacSign(dob);
    await prefs.setString('user_zodiac', zodiac);
    await prefs.setString('user_name', name);
  }

  String _getZodiacSign(DateTime date) {
    int day = date.day;
    int month = date.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricorn";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius";
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return "Pisces";
    return "Aries";
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

    // Check if zodiac/DOB is missing (for existing users or login flow)
    if (!prefs.containsKey('user_zodiac') && mounted) {
      // In a real app we might prompt them, but for now we default or check firestore if implemented
      // If this was a fresh login, we might not have the DOB locally.
      // But for this task, the requirement is mainly about the Sign Up flow.
    }

    // Refresh Provider
    if (mounted) {
       await Provider.of<UserProvider>(context, listen: false).loadUserData();
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
              child: Form(
                key: _formKey,
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
                       TextFormField(
                        controller: _nameController,
                        validator: AppValidators.validateName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.person, color: AppColors.primaryGold),
                          errorStyle: const TextStyle(color: Colors.redAccent),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.textSecondary),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.primaryGold),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth Input
                      TextFormField(
                        controller: _dobController,
                        validator: (val) => val == null || val.isEmpty ? "Date of Birth is required" : null,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        hintText: 'Select Date',
                        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryGold),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.textSecondary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.primaryGold),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onTap: () async {
                        DateTime now = DateTime.now();
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(now.year - 10, now.month, now.day),
                          firstDate: DateTime(1900),
                          lastDate: now,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primaryGold,
                                  onPrimary: Colors.black,
                                  surface: AppColors.surfaceColor,
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: AppColors.scaffoldBackgroundColor,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                            _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    validator: (val) => val == null || val.isEmpty ? "Email is required" : null,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'you@example.com',
                      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.email, color: AppColors.primaryGold),
                      errorStyle: const TextStyle(color: Colors.redAccent),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.textSecondary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.primaryGold),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    validator: (val) => val == null || val.isEmpty ? "Password is required" : null,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.lock, color: AppColors.primaryGold),
                      errorStyle: const TextStyle(color: Colors.redAccent),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.textSecondary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.primaryGold),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: AppColors.primaryGold, fontSize: 12),
                        ),
                      ),
                    ),

                  SizedBox(height: _isSignUp ? 32 : 16),

                  // Action Button
                  // ValueListenableBuilder to disable button visually if fields are invalid
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _emailController,
                    builder: (context, emailValue, child) {
                      return ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _passwordController,
                        builder: (context, passValue, _) {
                          // Basic empty check for button state visual, real validation happens in _submit via form key
                          bool isDisabled = emailValue.text.isEmpty || passValue.text.isEmpty;
                          if (_isSignUp) isDisabled = isDisabled || _nameController.text.isEmpty;

                          return Opacity(
                            opacity: isDisabled ? 0.5 : 1.0,
                            child: GradientButton(
                              text: _isSignUp ? 'Sign Up' : 'Log In',
                              isLoading: _isLoading,
                              onPressed: isDisabled ? () {} : _submit,
                            ),
                          );
                        }
                      );
                    }
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
      ),
    );
  }
}
