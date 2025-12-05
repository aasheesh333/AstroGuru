import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import 'kundli_result_screen.dart';

class KundliInputScreen extends StatefulWidget {
  const KundliInputScreen({super.key});

  @override
  State<KundliInputScreen> createState() => _KundliInputScreenState();
}

class _KundliInputScreenState extends State<KundliInputScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Kundli'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
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

              _buildTextField('Full Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField('Date of Birth', Icons.calendar_today_outlined, isDate: true),
              const SizedBox(height: 16),
              _buildTextField('Time of Birth', Icons.access_time_outlined, isTime: true),
              const SizedBox(height: 16),
              _buildTextField('Place of Birth', Icons.location_on_outlined),

              const SizedBox(height: 48),
              GradientButton(
                text: 'Generate Kundli',
                onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (_) => const KundliResultScreen()),
                   );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool isDate = false, bool isTime = false}) {
    return TextFormField(
      style: const TextStyle(color: AppColors.textPrimary),
      readOnly: isDate || isTime,
      onTap: () async {
        if (isDate) {
          showDatePicker(
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
        } else if (isTime) {
          showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: AppTheme.darkTheme,
                child: child!,
              );
            },
          );
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
