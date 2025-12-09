import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';
import '../widgets/baba_avatar.dart';
import '../widgets/gradient_button.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

// HomeScreen is now just the content widget (no Scaffold)
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
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        isGuest = prefs.getBool('guest_mode') ?? false;
      });
      _loadHoroscope();
    } catch (e) {
      // Handle error safely
    }
  }

  void _loadHoroscope() async {
    try {
      final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
      String result = await AIService.getDailyHoroscope("Aries", DateTime.now(), lang);

      if (isGuest) {
        int cutoff = result.length > 100 ? 100 : result.length;
        result = "${result.substring(0, cutoff)}...\n\n(Log in to read more)";
      }

      if (mounted) {
        setState(() {
          horoscope = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          horoscope = "Failed to load horoscope.";
        });
      }
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
    // Return content directly (no Scaffold)
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const BabaAvatar(size: 100),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: AppColors.surfaceColor.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: AppColors.primaryGold),
                        SizedBox(width: 10),
                        Text("Daily Horoscope", style: TextStyle(color: AppColors.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: AppColors.textSecondary),
                    const SizedBox(height: 10),
                    Text(
                      horoscope,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                GradientButton(
                  text: "Generate Kundli",
                  onPressed: () => _checkAccess('/kundli'),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  text: "Ask AI Sage",
                  onPressed: () => _checkAccess('/chat'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
