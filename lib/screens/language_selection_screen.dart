import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/language_provider.dart';
import '../theme/app_colors.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    provider.setLocale(Locale(code));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Language"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: LanguageProvider.supportedLanguages.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.grey),
        itemBuilder: (context, index) {
          final lang = LanguageProvider.supportedLanguages[index];
          return ListTile(
            title: Text(
              lang['nativeName'],
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              lang['name'],
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.primaryGold, size: 16),
            onTap: () => _selectLanguage(context, lang['code']),
          );
        },
      ),
    );
  }
}
