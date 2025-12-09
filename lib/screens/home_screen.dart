import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';
import '../widgets/baba_avatar.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String horoscope = "Loading...";
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('guest_mode') ?? false;
    });
    _loadHoroscope();
  }

  void _loadHoroscope() async {
    // Placeholder logic for sign
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    String result = await AIService.getDailyHoroscope("Aries", DateTime.now(), lang);

    if (isGuest && result.length > 100) {
      // Truncate for guest
      result = "${result.substring(0, 100)}...\n\n(Log in to read more)";
    }

    if (mounted) {
      setState(() {
        horoscope = result;
      });
    }
  }

  void _checkAccess(String route) {
    if (isGuest) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0E1016),
          title: const Text("Login Required", style: TextStyle(color: Color(0xFFD4AF37))),
          content: const Text("Please log in with phone number to unlock this feature.", style: TextStyle(color: Colors.white)),
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
    } else {
      Navigator.pushNamed(context, route);
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
                ElevatedButton(onPressed: () => _checkAccess('/kundli'), child: const Text("Kundli")),
                ElevatedButton(onPressed: () => _checkAccess('/chat'), child: const Text("Ask Sage")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
