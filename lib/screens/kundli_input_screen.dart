import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../utils/validators.dart';
import 'kundli_result_screen.dart';
import 'login_screen.dart';

class KundliInputScreen extends StatelessWidget {
  const KundliInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.generateKundliBtn),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: const KundliInputContent(),
      ),
    );
  }
}

class KundliInputContent extends StatefulWidget {
  const KundliInputContent({super.key});

  @override
  State<KundliInputContent> createState() => _KundliInputContentState();
}

class _KundliInputContentState extends State<KundliInputContent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestMode();
  }

  void _checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isGuest = prefs.getBool('guest_mode') ?? false;
      });
    }
  }

  void _handleGenerate() {
    if (isGuest) {
      _showLoginDialog();
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Validation handled by Form/Validators
      String name = _nameController.text.trim();
      String place = _placeController.text.trim();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KundliResultScreen(
            name: name,
            date: _selectedDate!,
            time: _selectedTime!,
            place: place,
          ),
        ),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1016),
        title: Text(AppLocalizations.of(context)!.loginRequiredTitle, style: const TextStyle(color: Color(0xFFD4AF37))),
        content: Text(AppLocalizations.of(context)!.loginRequiredMsg, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: Text(AppLocalizations.of(context)!.loginNow),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.enterDetails,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.enterDetailsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            _buildTextField(
              AppLocalizations.of(context)!.name,
              Icons.person_outline,
              controller: _nameController,
              validator: (val) => AppValidators.validateName(val, context),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              AppLocalizations.of(context)!.dateOfBirth,
              Icons.calendar_today_outlined,
              isDate: true,
              controller: _dateController,
              validator: (value) {
                if (value == null || value.isEmpty) return AppLocalizations.of(context)!.error; // Generic Error fallback
                if (_selectedDate != null) {
                  // Only allow up to today (handled by DatePicker), but maybe logical check
                  if (_selectedDate!.isAfter(DateTime.now())) {
                    return AppLocalizations.of(context)!.errorDateFuture;
                  }

                  // Optional: Min age check or '3 months past' check?
                  final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
                  if (_selectedDate!.isAfter(threeMonthsAgo)) {
                    return AppLocalizations.of(context)!.errorDateRecent;
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              AppLocalizations.of(context)!.timeOfBirth,
              Icons.access_time_outlined,
              isTime: true,
              controller: _timeController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              AppLocalizations.of(context)!.placeOfBirth,
              Icons.location_on_outlined,
              controller: _placeController,
              validator: (val) => AppValidators.validateLocation(val, context),
            ),

            const SizedBox(height: 48),
            GradientButton(
              text: AppLocalizations.of(context)!.generateKundliBtn,
              onPressed: _handleGenerate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {
    bool isDate = false,
    bool isTime = false,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      readOnly: isDate || isTime,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          // Use localized error string
          // Note: This fallback might need a generic "Required" message if not covered by AppValidators
          return "$label ${AppLocalizations.of(context)!.error}";
        }
        return null;
      },
      onTap: () async {
        if (isDate) {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: AppTheme.darkTheme,
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _selectedDate = picked;
              controller.text = "${picked.day}/${picked.month}/${picked.year}";
            });
          }
        } else if (isTime) {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: AppTheme.darkTheme,
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _selectedTime = picked;
              controller.text = picked.format(context);
            });
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        filled: true,
        fillColor: AppColors.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold),
        ),
      ),
    );
  }
}
