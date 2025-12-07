import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/language_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        children: [
          const ListTile(title: Text("Language Settings")),
          Consumer<LanguageProvider>(
            builder: (context, provider, child) {
              return DropdownButton<Locale>(
                value: provider.locale,
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text("English")),
                  DropdownMenuItem(value: Locale('hi'), child: Text("Hindi")),
                  // Add others
                ],
                onChanged: (val) {
                  if (val != null) provider.setLocale(val);
                },
              );
            },
          )
        ],
      ),
    );
  }
}
