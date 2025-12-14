import '../logic/security_service.dart';
import 'dart:convert'; // For Base64
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http; // Added http
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../logic/user_provider.dart';
import '../logic/user_session.dart';
import '../logic/language_provider.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final auth = await _ensureAuthInitialized();
    if (auth == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
         // Check Ban Status
         final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
         final doc = await docRef.get();

         if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
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
               return;
            }
            // Check Deletion
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
                       onPressed: () => Navigator.pop(context, false),
                       child: const Text("Cancel Login", style: TextStyle(color: Colors.red)),
                     ),
                     ElevatedButton(
                       style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
                       onPressed: () => Navigator.pop(context, true),
                       child: const Text("Regain Access"),
                     ),
                   ],
                 ),
               ) ?? false;

               if (regain) {
                 await docRef.update({'delete_requested_at': FieldValue.delete()});
               } else {
                 await auth.signOut();
                 setState(() => _isLoading = false);
                 return;
               }
            }
         }

         // Handle New User Data (Sync Google Profile)
         if (userCredential.additionalUserInfo?.isNewUser == true) {
            String name = user.displayName ?? "User";
            String email = user.email ?? "";
            String? photoUrl = user.photoURL;
            String? base64Image;

            if (photoUrl != null) {
               try {
                 final response = await http.get(Uri.parse(photoUrl));
                 if (response.statusCode == 200) {
                   base64Image = base64Encode(response.bodyBytes);
                   await UserSession.setString('profile_image_base64', base64Image);
                 }
               } catch (e) {
                 print("Error fetching Google profile image: $e");
               }
            }

            // Save to Firestore
            await docRef.set({
              'name': name,
              'email': email,
              'created_at': Timestamp.now(),
              if (base64Image != null) 'profile_image_base64': base64Image,
              // DOB is usually not available from Google Sign In unless specific scopes requested,
              // and even then it's restricted. We'll leave DOB empty for user to fill later.
            }, SetOptions(merge: true));

            await UserSession.setString('user_name', name);
            // We don't have DOB, so Zodiac defaults to Aries until user edits profile.
         }

         await _onAuthSuccess(user);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0E1016),
              title: const Text("Account Exists", style: TextStyle(color: AppColors.primaryGold)),
              content: Text(
                AppLocalizations.of(context)!.accountExistsWithDifferentCredential,
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${AppLocalizations.of(context)!.googleSignInError}: ${e.message}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.googleSignInError}: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      if (age < 10 || age > 150) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0E1016),
              title: const Text("Age Restriction", style: TextStyle(color: Color(0xFFD4AF37))),
              content: const Text(
                "You must be at least 10 years old to use this app.",
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
                content: Text(
                  "A verification link has been sent to your email. Please verify it and then log in.\n\n${AppLocalizations.of(context)!.checkSpamFolder}",
                  style: const TextStyle(color: Colors.white),
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
                    content: Text(
                      "Please verify your email address to continue.\n${AppLocalizations.of(context)!.checkSpamFolder}",
                      style: const TextStyle(color: Colors.white),
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

    try {
      // Server-side Rate Limiting
      await SecurityService.checkPasswordResetLimit(email);

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent. ${AppLocalizations.of(context)!.checkSpamFolder}")),
        );
      }
    } on String catch (e) {
      // Check for custom limit exceeded message
      if (e.contains("Limit Exceeded")) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0E1016),
              title: const Text("Limit Exceeded", style: TextStyle(color: Colors.red)),
              content: Text(
                e,
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
        }
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
    await UserSession.setString('user_dob', dob.toIso8601String());

    // Calculate Zodiac
    String zodiac = _getZodiacSign(dob);
    await UserSession.setString('user_zodiac', zodiac);
    await UserSession.setString('user_name', name);
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

    // Store user data in UserSession (Authenticated Isolation)
    await UserSession.setString('user_email', user?.email ?? "");
    await UserSession.setString('user_phone', user?.phoneNumber ?? "");

    // Store Name
    String displayName = user?.displayName ?? _nameController.text;
    if (displayName.isEmpty) displayName = "User";
    await UserSession.setString('user_name', displayName);

    // Persist Language for User
    if (mounted) {
       final langCode = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
       await UserSession.setUserLanguage(langCode);
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
                      _isSignUp ? AppLocalizations.of(context)!.createAccount : AppLocalizations.of(context)!.welcomeBack,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                        ? AppLocalizations.of(context)!.signUpSubtitle
                        : AppLocalizations.of(context)!.loginSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    if (_isSignUp) ...[
                       TextFormField(
                        controller: _nameController,
                        validator: (val) => AppValidators.validateName(val, context),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.name,
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
                        labelText: AppLocalizations.of(context)!.dateOfBirth,
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
                      labelText: AppLocalizations.of(context)!.emailLabel,
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
                      labelText: AppLocalizations.of(context)!.passwordLabel,
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
                        child: Text(
                          AppLocalizations.of(context)!.forgotPassword,
                          style: const TextStyle(color: AppColors.primaryGold, fontSize: 12),
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
                              text: _isSignUp ? AppLocalizations.of(context)!.signUpBtn : AppLocalizations.of(context)!.loginBtn,
                              isLoading: _isLoading,
                              onPressed: isDisabled ? () {} : _submit,
                            ),
                          );
                        }
                      );
                    }
                  ),

                  // Google Sign-In Button
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Image.asset('assets/images/google_logo.png', height: 24, width: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, color: Colors.white)),
                    label: Text(
                      AppLocalizations.of(context)!.continueWithGoogle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textSecondary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                      _isSignUp ? AppLocalizations.of(context)!.alreadyHaveAccount : AppLocalizations.of(context)!.dontHaveAccount,
                      style: const TextStyle(color: AppColors.primaryGold),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Skip Button
                  if (!_isSignUp)
                    TextButton(
                      onPressed: _skipLogin,
                      child: Text(
                        AppLocalizations.of(context)!.skipBtn,
                        style: const TextStyle(color: AppColors.textSecondary),
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
