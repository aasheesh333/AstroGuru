import 'package:flutter/material.dart';
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
        title: const Text('Generate Kundli'),
        automaticallyImplyLeading: false,
      ),
      body: const KundliInputContent(),
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
        title: const Text("Login Required", style: TextStyle(color: Color(0xFFD4AF37))),
        content: const Text("Please log in to unlock detailed Kundli generation.", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Log in Now"),
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
              'Enter Birth Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Accurate details ensure precise predictions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            _buildTextField(
              'Full Name',
              Icons.person_outline,
              controller: _nameController,
              validator: AppValidators.validateName,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Date of Birth',
              Icons.calendar_today_outlined,
              isDate: true,
              controller: _dateController,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter Date of Birth';
                if (_selectedDate != null) {
                  final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
                  if (_selectedDate!.isAfter(threeMonthsAgo)) {
                    return 'Date must be at least 3 months in the past';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Time of Birth',
              Icons.access_time_outlined,
              isTime: true,
              controller: _timeController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Place of Birth',
              Icons.location_on_outlined,
              controller: _placeController,
              validator: AppValidators.validateLocation,
            ),

            const SizedBox(height: 48),
            GradientButton(
              text: 'Generate Kundli',
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
          return 'Please enter $label';
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
