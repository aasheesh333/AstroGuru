import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../logic/user_provider.dart';
import 'package:provider/provider.dart';
import '../utils/validators.dart';
import '../logic/image_helper.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/security_service.dart';
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
  final TextEditingController _professionController = TextEditingController();
  String? _gender;
  String? _maritalStatus;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isGuest = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      _isGuest = prefs.getBool('guest_mode') ?? false;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _nameController.text = userProvider.name;
      _emailController.text = userProvider.email; // Fill email
      if (userProvider.dob.isNotEmpty) {
        try {
          _selectedDate = DateTime.parse(userProvider.dob);
          _dobController.text = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
        } catch (_) {}
      }
      _professionController.text = userProvider.profession;
      _gender = userProvider.gender.isEmpty ? null : userProvider.gender;
      _maritalStatus = userProvider.maritalStatus.isEmpty ? null : userProvider.maritalStatus;
      if (mounted) setState(() => _loaded = true);
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
        newDob: _selectedDate,
        newGender: _gender ?? '',
        newProfession: _professionController.text.trim(),
        newMaritalStatus: _maritalStatus ?? '',
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

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email is required for password reset")),
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
              backgroundColor: AppColors.surfaceColor,
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

  Future<void> _deleteAccount() async {
    // Soft Delete: Mark for deletion in 24 hours
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: _isGuest
            ? _buildGuestBlocked(l10n)
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    // Show a quick loading indicator while the upload runs.
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryGold),
                      ),
                    );
                    final result = await ImageHelper.pickCompressAndSave(user.uid);
                    if (mounted) Navigator.of(context, rootNavigator: true).pop();
                    if (!mounted) return;
                    if (result.hasAny) {
                      await userProvider.updateProfile(
                        newImageUrl: result.url,
                        newImageBase64: result.base64,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.profileImageUpdated)),
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not update profile photo.')),
                      );
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
                          color: AppColors.surfaceColor,
                          border: Border.all(color: AppColors.primaryGold, width: 2),
                        ),
                        child: ClipOval(
                          child: _Avatar(url: userProvider.profileImageUrl, base64: userProvider.profileImageBase64, size: 100),
                        ),
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
                  validator: (val) {
                    if (_selectedDate == null) return AppLocalizations.of(context)!.error; // Generic required

                    final now = DateTime.now();
                    int age = now.year - _selectedDate!.year;
                    if (now.month < _selectedDate!.month ||
                       (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
                      age--;
                    }

                    if (age < 10) return "Minimum age must be 10 years.";
                    if (age > 150) return "Invalid age (Max 150 years).";
                    return null;
                  },
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
                      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 155)), // Allow slightly older to show validation
                      lastDate: DateTime.now(), // Allow selection to show validation
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.genderLabel,
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryGold),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  dropdownColor: AppColors.surfaceColor,
                  items: [
                    DropdownMenuItem(value: 'male', child: Text(AppLocalizations.of(context)!.genderMale)),
                    DropdownMenuItem(value: 'female', child: Text(AppLocalizations.of(context)!.genderFemale)),
                    DropdownMenuItem(value: 'other', child: Text(AppLocalizations.of(context)!.genderOther)),
                    DropdownMenuItem(value: 'prefer_not_to_say', child: Text(AppLocalizations.of(context)!.genderPreferNot)),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _maritalStatus,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.maritalStatusLabel,
                    prefixIcon: const Icon(Icons.favorite_border, color: AppColors.primaryGold),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  dropdownColor: AppColors.surfaceColor,
                  items: [
                    DropdownMenuItem(value: 'single', child: Text(AppLocalizations.of(context)!.maritalSingle)),
                    DropdownMenuItem(value: 'married', child: Text(AppLocalizations.of(context)!.maritalMarried)),
                    DropdownMenuItem(value: 'in_relationship', child: Text(AppLocalizations.of(context)!.maritalInRelationship)),
                    DropdownMenuItem(value: 'divorced', child: Text(AppLocalizations.of(context)!.maritalDivorced)),
                    DropdownMenuItem(value: 'widowed', child: Text(AppLocalizations.of(context)!.maritalWidowed)),
                    DropdownMenuItem(value: 'prefer_not_to_say', child: Text(AppLocalizations.of(context)!.maritalPreferNot)),
                  ],
                  onChanged: (v) => setState(() => _maritalStatus = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _professionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.professionLabel,
                    hintText: AppLocalizations.of(context)!.professionHint,
                    prefixIcon: const Icon(Icons.work_outline, color: AppColors.primaryGold),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

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

                // Conditionally show Forgot Password based on provider
                FutureBuilder<List<UserInfo>>(
                  future: Future.value(() {
                    try {
                      return FirebaseAuth.instance.currentUser?.providerData ?? <UserInfo>[];
                    } catch (_) {
                      // Firebase may not be initialized in widget tests; assume
                      // password auth is the default so the button still shows.
                      return <UserInfo>[];
                    }
                  }()),
                  builder: (context, snapshot) {
                     if (!snapshot.hasData) return const SizedBox.shrink();
                     bool isGoogleUser = snapshot.data!.any((p) => p.providerId == 'google.com');

                     if (isGoogleUser) return const SizedBox.shrink();

                     return Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          AppLocalizations.of(context)!.forgotPassword,
                          style: const TextStyle(color: AppColors.primaryGold, fontSize: 12),
                        ),
                      ),
                    );
                  }
                ),

                const SizedBox(height: 32),

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

  Widget _buildGuestBlocked(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.primaryGold, size: 72),
            const SizedBox(height: 24),
            Text(
              l10n.loginRequiredTitle,
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.loginRequiredMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: l10n.loginNow,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String? base64;
  final double size;

  const _Avatar({required this.url, required this.base64, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (ctx, _) => Container(width: size, height: size, color: AppColors.surfaceColor),
        errorWidget: (ctx, _, __) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    if (base64 != null && base64!.isNotEmpty) {
      try {
        return Image.memory(base64Decode(base64!), width: size, height: size, fit: BoxFit.cover);
      } catch (_) {
        return _placeholder();
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceColor,
      child: const Icon(Icons.person, size: 50, color: AppColors.textSecondary),
    );
  }
}
