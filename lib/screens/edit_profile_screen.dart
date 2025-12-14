import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../logic/user_provider.dart';
import 'package:provider/provider.dart';
import '../utils/validators.dart';
import '../logic/image_helper.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Added email controller
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _nameController.text = userProvider.name;
      _emailController.text = userProvider.email; // Fill email
      if (userProvider.dob.isNotEmpty) {
        try {
          _selectedDate = DateTime.parse(userProvider.dob);
          _dobController.text = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
        } catch (_) {}
      }
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "No user logged in";

      // Rate Limiting Logic (Firestore)
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      List<dynamic> nameChanges = [];
      List<dynamic> dobChanges = [];

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          nameChanges = List.from(data['name_changes'] ?? []);
          dobChanges = List.from(data['dob_changes'] ?? []);
        }
      }

      // Filter last 14 days
      final now = DateTime.now();
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));

      nameChanges.retainWhere((ts) => (ts as Timestamp).toDate().isAfter(fourteenDaysAgo));
      dobChanges.retainWhere((ts) => (ts as Timestamp).toDate().isAfter(fourteenDaysAgo));

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      bool nameChanged = _nameController.text.trim() != userProvider.name;

      DateTime? currentDob;
      try {
         if (userProvider.dob.isNotEmpty) currentDob = DateTime.parse(userProvider.dob);
      } catch (_) {}

      bool dobChanged = _selectedDate != null && _selectedDate != currentDob;

      if (nameChanged) {
        if (nameChanges.length >= 3) {
          throw AppLocalizations.of(context)!.rateLimitError;
        }
        nameChanges.add(Timestamp.now());
      }

      if (dobChanged) {
        if (dobChanges.length >= 2) {
          throw AppLocalizations.of(context)!.rateLimitError;
        }
        dobChanges.add(Timestamp.now());
      }

      // Update Firestore
      await docRef.set({
        'name_changes': nameChanges,
        'dob_changes': dobChanges,
      }, SetOptions(merge: true));

      // Update Provider & Firebase Auth (Fixed parameter names)
      await userProvider.updateProfile(
        newName: _nameController.text.trim(),
        newDob: _selectedDate
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    // Soft Delete: Mark for deletion in 24 hours
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1016),
        title: Text(AppLocalizations.of(context)!.deleteAccount, style: const TextStyle(color: Colors.red)),
        content: Text(AppLocalizations.of(context)!.softDeleteMsg, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.deleteAccount, style: const TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'delete_requested_at': Timestamp.now()
          });
          await FirebaseAuth.instance.signOut();
           if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
           }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editProfile),
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
                GestureDetector(
                  onTap: () async {
                    final base64String = await ImageHelper.pickAndCompressImage();
                    if (base64String != null) {
                       await userProvider.updateProfile(newImageBase64: base64String);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryGold, width: 2),
                          image: userProvider.profileImageBase64 != null
                             ? DecorationImage(image: MemoryImage(base64Decode(userProvider.profileImageBase64!)), fit: BoxFit.cover)
                             : null,
                        ),
                        child: userProvider.profileImageBase64 == null
                           ? const Icon(Icons.person, size: 50, color: AppColors.textSecondary)
                           : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.primaryGold, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 16, color: Colors.black),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Email Field (Read Only)
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  enabled: false,
                  style: const TextStyle(color: Colors.grey),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.emailLabel,
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                    suffixIcon: const Icon(Icons.lock, color: Colors.grey, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceColor.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: AppLocalizations.of(context)!.emailImmutable,
                    helperStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  validator: (val) => AppValidators.validateName(val, context),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.name,
                    prefixIcon: const Icon(Icons.person, color: AppColors.primaryGold),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.dateOfBirth,
                    prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryGold),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                       builder: (context, child) {
                        return Theme(data: ThemeData.dark(), child: child!);
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
                const SizedBox(height: 40),

                GradientButton(
                  text: AppLocalizations.of(context)!.saveChanges,
                  isLoading: _isLoading,
                  onPressed: _updateProfile,
                ),
                const SizedBox(height: 16),
                 TextButton(
                  onPressed: _deleteAccount,
                  child: Text(AppLocalizations.of(context)!.deleteAccount, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
