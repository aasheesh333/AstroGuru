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

  // Google Auth Completion State
  bool _isGoogleAuth = false;
  User? _pendingGoogleUser;
  String? _pendingGooglePhotoUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

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

            // 1. Check Ban
            if (data['banned'] == true) {
               final reason = data['ban_reason'] ?? "Internal Policy";
               await auth.signOut();
               await _googleSignIn.signOut();
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
            // 2. Check Deletion
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
                 await _googleSignIn.signOut();
                 setState(() => _isLoading = false);
                 return;
               }
            }

            // 3. Check for Date of Birth (Required for Login)
            if (data.containsKey('dob') && data['dob'] != null) {
              await _onAuthSuccess(user);
              return;
            }
         }

         // --- Handle New or Incomplete Google User ---
         // If we are here, either the doc doesn't exist OR dob is missing.
         // We must get the user to complete their profile (DOB).

         setState(() {
           _isSignUp = true;
           _isGoogleAuth = true;
           _pendingGoogleUser = user;
           _pendingGooglePhotoUrl = user.photoURL; // Store to fetch later

           // Pre-fill Fields
           _nameController.text = user.displayName ?? "";
           _emailController.text = user.email ?? "";

           // Clear password just in case
           _passwordController.clear();

           _isLoading = false;
         });

         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Please complete your profile details.")),
           );
         }
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
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.googleSignInError}: $e")),
        );
      }
      setState(() => _isLoading = false);
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

    // Basic Validation
    if (!_isGoogleAuth && (email.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      setState(() => _isLoading = false);
      return;
    }

    // For Google Auth, Password is NOT required
    if (_isGoogleAuth && email.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email is missing. Please try signing in again.")),
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

      // Strict Age Validation
      if (age < 10) {
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

      if (age > 150) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0E1016),
              title: const Text("Invalid Date", style: TextStyle(color: Colors.red)),
              content: const Text(
                "Please enter a valid date of birth.",
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

      // Password Complexity Check (Only for Standard Signup)
      if (!_isGoogleAuth) {
        if (password.length < 6 || !password.contains(RegExp(r'[A-Za-z]')) || !password.contains(RegExp(r'[0-9]'))) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password must be at least 6 characters and contain both letters and numbers.")),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
    }

    try {
      if (_isSignUp) {
        User? user;

        if (_isGoogleAuth) {
           // --- Handle Google Completion ---
           user = auth.currentUser;
           // If for some reason auth is lost, try to use the pending one or re-login
           if (user == null && _pendingGoogleUser != null) {
             user = _pendingGoogleUser;
           }

           if (user == null) {
              // Fatal Error state
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Authentication session lost. Please try again.")),
              );
              setState(() {
                _isLoading = false;
                _isGoogleAuth = false;
                _isSignUp = false;
              });
              return;
           }

           // Fetch and Convert Profile Image if available
           String? base64Image;
           if (_pendingGooglePhotoUrl != null) {
             try {
               final response = await http.get(Uri.parse(_pendingGooglePhotoUrl!));
               if (response.statusCode == 200) {
                 base64Image = base64Encode(response.bodyBytes);
                 await UserSession.setString('profile_image_base64', base64Image);
               }
             } catch (e) {
               debugPrint("Error fetching Google profile image: $e");
             }
           }

           // Update Firestore
           await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'name': name,
              'email': email,
              'dob': _selectedDate!.toIso8601String(),
              'created_at': Timestamp.now(),
              if (base64Image != null) 'profile_image_base64': base64Image,
           }, SetOptions(merge: true));

           await _storeUserData(name, _selectedDate!);
           await _onAuthSuccess(user);

        } else {
          // --- Standard Email/Password Sign Up ---
          UserCredential userCredential = await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          user = userCredential.user;
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
        }
      } else {
        // --- Standard Log In ---
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? user = userCredential.user;

        if (user != null) {
          if (!user.emailVerified) {
             await user.reload();
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

          // Check Ban/Deletion/Data (similar to google sign in checks)
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
               return;
            }

            // 2. Check Deletion
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
                 await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                   'delete_requested_at': FieldValue.delete()
                 });
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
      await SecurityService.checkPasswordResetLimit(email);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent. ${AppLocalizations.of(context)!.checkSpamFolder}")),
        );
      }
    } on String catch (e) {
      if (e.contains("Limit Exceeded")) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0E1016),
              title: const Text("Limit Exceeded", style: TextStyle(color: Colors.red)),
              content: Text(e, style: const TextStyle(color: Colors.white)),
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Error sending reset email";
      if (e.code == 'user-not-found') message = 'No user found with this email.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _storeUserData(String name, DateTime dob) async {
    await UserSession.setString('user_dob', dob.toIso8601String());
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

    await UserSession.setString('user_email', user?.email ?? "");
    await UserSession.setString('user_phone', user?.phoneNumber ?? "");

    String displayName = user?.displayName ?? _nameController.text;
    if (displayName.isEmpty) displayName = "User";
    await UserSession.setString('user_name', displayName);

    if (mounted) {
       final langCode = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
       await UserSession.setUserLanguage(langCode);
    }

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
                      readOnly: _isGoogleAuth, // Read-only if in Google Auth mode
                      style: TextStyle(color: _isGoogleAuth ? Colors.grey : Colors.white),
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
                        // Add lock icon suffix if read-only
                        suffixIcon: _isGoogleAuth
                           ? const Icon(Icons.lock_outline, color: AppColors.textSecondary)
                           : null,
                      ),
                    ),

                    // Password Input - Hidden in Google Auth Mode
                    if (!_isGoogleAuth) ...[
                      const SizedBox(height: 16),
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
                    ],

                    SizedBox(height: _isSignUp ? 32 : 16),

                    // Action Button
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _emailController,
                      builder: (context, emailValue, child) {
                        return ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _passwordController,
                          builder: (context, passValue, _) {
                             // Logic adjusted for Google Auth
                            bool isDisabled = emailValue.text.isEmpty;
                            if (!_isGoogleAuth && passValue.text.isEmpty) isDisabled = true;
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

                    // Google Sign-In Button (Hide if already in Google completion mode)
                    if (!_isGoogleAuth) ...[
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
                    ],

                    const SizedBox(height: 16),

                    // Toggle Login/Signup (Modified for Google Auth Cancel)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_isGoogleAuth) {
                            // Cancel Google Auth Mode
                            _isGoogleAuth = false;
                            _isSignUp = false; // Return to login default
                            _emailController.clear();
                            _nameController.clear();
                            _dobController.clear();
                            _passwordController.clear();
                            _selectedDate = null;
                            _googleSignIn.signOut();
                          } else {
                            _isSignUp = !_isSignUp;
                          }
                        });
                      },
                      child: Text(
                        _isGoogleAuth
                           ? "Cancel"
                           : (_isSignUp ? AppLocalizations.of(context)!.alreadyHaveAccount : AppLocalizations.of(context)!.dontHaveAccount),
                        style: const TextStyle(color: AppColors.primaryGold),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Skip Button
                    if (!_isSignUp && !_isGoogleAuth)
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
