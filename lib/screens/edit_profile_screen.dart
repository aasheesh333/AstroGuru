import '../logic/security_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../logic/image_helper.dart';
import '../logic/user_session.dart';
import '../logic/user_provider.dart';
import '../utils/validators.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  DateTime? _selectedDate;
  String? _profileImageBase64;
  bool _isLoading = false;

  // Rate Limiting
  bool _canChangeName = true;
  bool _canChangeDob = true;
  String? _nameLimitMsg;
  String? _dobLimitMsg;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check Limits from Firestore
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
         final data = doc.data()!;
         final now = DateTime.now();
         final windowStart = now.subtract(const Duration(days: 14));

         // Check Name Limits
         List<dynamic> nameHistory = data['name_change_history'] ?? [];
         int nameChanges = nameHistory.where((ts) {
            if (ts is Timestamp) return ts.toDate().isAfter(windowStart);
            return false;
         }).length;

         if (nameChanges >= 3) {
           _canChangeName = false;
           _nameLimitMsg = "Limit reached: 3 changes in 14 days.";
         }

         // Check DOB Limits
         List<dynamic> dobHistory = data['dob_change_history'] ?? [];
         int dobChanges = dobHistory.where((ts) {
            if (ts is Timestamp) return ts.toDate().isAfter(windowStart);
            return false;
         }).length;

         if (dobChanges >= 2) {
           _canChangeDob = false;
           _dobLimitMsg = "Limit reached: 2 changes in 14 days.";
         }
      }
    } catch (e) {
      print("Error loading limits: $e");
    }

    // Load Data from Provider for consistency
    if (mounted) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
         _nameController.text = provider.name;
         _emailController.text = provider.email;
         _profileImageBase64 = provider.profileImageBase64;
         if (provider.dob.isNotEmpty) {
            try {
              _selectedDate = DateTime.parse(provider.dob);
              _dobController.text = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
            } catch (_) {}
         }
      });
    }
  }

  Future<void> _pickImage() async {
    String? base64Img = await ImageHelper.pickAndCompressImage();
    if (base64Img != null) {
      setState(() {
        _profileImageBase64 = base64Img;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final provider = Provider.of<UserProvider>(context, listen: false);

      if (user != null) {
        bool nameChanged = _nameController.text.trim() != provider.name;
        bool dobChanged = _selectedDate != null && (_selectedDate!.toIso8601String() != provider.dob);
        bool imgChanged = _profileImageBase64 != provider.profileImageBase64;

        if (!nameChanged && !dobChanged && !imgChanged) {
           Navigator.pop(context); // No changes
           return;
        }

        // Validate Age if DOB changed
        if (dobChanged && _selectedDate != null) {
          final age = DateTime.now().difference(_selectedDate!).inDays / 365;
          if (age < 10 || age > 150) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF0E1016),
                title: const Text("Age Restriction", style: TextStyle(color: Color(0xFFD4AF37))),
                content: const Text(
                  "You must be between 10 and 150 years old.",
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
            setState(() => _isLoading = false);
            return;
          }
        }

        // Update Change History in Firestore if changed
        if (nameChanged) {
           if (!_canChangeName) {
             throw "Name update limit reached.";
           }
           await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
             'name_change_history': FieldValue.arrayUnion([Timestamp.now()])
           }, SetOptions(merge: true));
        }
        if (dobChanged) {
           if (!_canChangeDob) {
             throw "Date of Birth update limit reached.";
           }
           await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
             'dob_change_history': FieldValue.arrayUnion([Timestamp.now()])
           }, SetOptions(merge: true));
        }

        // Use Provider to Update Global State & Persistence
        await provider.updateProfile(
          newName: nameChanged ? _nameController.text.trim() : null,
          newDob: dobChanged ? _selectedDate : null,
          newImageBase64: imgChanged ? _profileImageBase64 : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Updated Successfully!")),
          );
          Navigator.pop(context);
        }
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

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) return;
    try {
      await SecurityService.checkPasswordResetLimit(_emailController.text);

      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent. Check your inbox.")),
        );
      }
    } on String catch (e) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
        content: const Text(
          "Are you sure you want to delete your account?\n\nThis will schedule your account for deletion. If you do not log in within 24 hours, your data will be permanently removed.",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
             onPressed: () => Navigator.pop(context, true),
             child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
       final user = FirebaseAuth.instance.currentUser;
       if (user != null) {
         try {
           // Set flag in Firestore
           await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
             'delete_requested_at': FieldValue.serverTimestamp(),
           }, SetOptions(merge: true));

           if (mounted) {
             showDialog(
               context: context,
               barrierDismissible: false,
               builder: (context) => AlertDialog(
                 backgroundColor: AppColors.surfaceColor,
                 title: const Text("Request Processed", style: TextStyle(color: AppColors.primaryGold)),
                 content: const Text(
                   "Your account deletion request has been processed.\n\nYour account will be deleted in 24 hours.\n\nIf you log in within 24 hours, you can regain access.",
                   style: TextStyle(color: AppColors.textPrimary)
                 ),
                 actions: [
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
                     onPressed: () async {
                       await FirebaseAuth.instance.signOut();
                       await UserSession.clearSession(); // Logic handled by prefix switch
                       final prefs = await SharedPreferences.getInstance();
                       await prefs.setBool('user_logged_in', false); // Global flag

                       if (mounted) {
                         Navigator.pop(context);
                         Navigator.pushAndRemoveUntil(
                           context,
                           MaterialPageRoute(builder: (_) => const LoginScreen()),
                           (route) => false
                         );
                       }
                     },
                     child: const Text("OK"),
                   )
                 ],
               ),
             );
           }
         } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
           }
         }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_profileImageBase64 != null) {
      imageProvider = MemoryImage(base64Decode(_profileImageBase64!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Image
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryGold, width: 2),
                          image: imageProvider != null
                             ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                             : null,
                          color: Colors.white10,
                        ),
                        child: imageProvider == null
                           ? const Icon(Icons.person, size: 60, color: Colors.white54)
                           : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  enabled: _canChangeName,
                  style: TextStyle(color: _canChangeName ? Colors.white : Colors.grey),
                  validator: AppValidators.validateName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    helperText: _nameLimitMsg,
                    helperStyle: TextStyle(color: _canChangeName ? Colors.grey : Colors.red),
                    prefixIcon: const Icon(Icons.person, color: AppColors.primaryGold),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    disabledBorder: OutlineInputBorder( // Greyed out
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // DOB
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  enabled: _canChangeDob,
                  style: TextStyle(color: _canChangeDob ? Colors.white : Colors.grey),
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    helperText: _dobLimitMsg,
                    helperStyle: TextStyle(color: _canChangeDob ? Colors.grey : Colors.red),
                    prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryGold),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGold),
                    ),
                  ),
                  onTap: !_canChangeDob ? null : () async {
                    DateTime now = DateTime.now();
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime(now.year - 20),
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
                       }
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Email (Read Only)
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.grey),
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white10,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text("Forgot Password?", style: TextStyle(color: AppColors.primaryGold)),
                  ),
                ),

                const SizedBox(height: 32),

                GradientButton(
                  text: "Save Changes",
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                ),

                const SizedBox(height: 40),

                GestureDetector(
                  onTap: _deleteAccount,
                  child: const Text(
                    "Delete Account",
                    style: TextStyle(
                      color: Colors.red,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
