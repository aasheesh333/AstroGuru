import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../logic/language_provider.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.profile ?? "Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
           Text(
            AppLocalizations.of(context)?.languageSettings ?? "Language Settings",
            style: const TextStyle(color: AppColors.primaryGold, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Consumer<LanguageProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: provider.locale,
                    dropdownColor: const Color(0xFF1E1E2C),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: LanguageProvider.supportedLanguages.map((lang) {
                      return DropdownMenuItem(
                        value: Locale(lang['code']),
                        child: Text("${lang['name']} (${lang['nativeName']})"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) provider.setLocale(val);
                    },
                  ),
                ),
              );
            },
          ),
          // Placeholder for future profile features
          const SizedBox(height: 20),
          const ListTile(
            leading: Icon(Icons.person, color: Colors.white),
            title: Text("User Name", style: TextStyle(color: Colors.white)),
            subtitle: Text("Guest User", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
