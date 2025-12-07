import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';
import '../widgets/baba_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String horoscope = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadHoroscope();
  }

  void _loadHoroscope() async {
    // Placeholder logic for sign
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    String result = await AIService.getDailyHoroscope("Aries", DateTime.now(), lang);
    if (mounted) {
      setState(() {
        horoscope = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AstroPrerna"),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const BabaAvatar(size: 100),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: const Color(0xFF0E1016),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Daily Horoscope", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(horoscope, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            // Shortcuts
            Wrap(
              spacing: 20,
              children: [
                ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/kundli'), child: const Text("Kundli")),
                ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/chat'), child: const Text("Ask Sage")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
