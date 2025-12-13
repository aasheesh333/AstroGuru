import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/language_provider.dart';
import '../logic/user_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'horoscope_detail_screen.dart';
import 'love_match_screen.dart';

// HomeScreen Content Widget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String horoscopeSummary = "Loading daily forecast...";
  Map<String, dynamic>? horoscopeData;

  String quoteText = "The stars incline, but do not bind.";
  String quoteAuthor = "";

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

      bool guest = prefs.getBool('guest_mode') ?? false;

      setState(() {
        isGuest = guest;
      });

      _checkDailyUpdates(prefs);
    } catch (e) {
      // Handle error safely
    }
  }

  void _checkDailyUpdates(SharedPreferences prefs) async {
    String today = DateTime.now().toIso8601String().split('T')[0];
    String lastDate = prefs.getString('last_fetch_date') ?? "";

    if (lastDate != today) {
       await _fetchNewData(prefs, today);
    } else {
       _loadFromPrefs(prefs);
    }
  }

  Future<void> _fetchNewData(SharedPreferences prefs, String today) async {
    if (!mounted) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;

    String sign = "Aries";

    try {
      String horoscopeJson = await AIService.getDailyHoroscope(sign, DateTime.now(), lang);
      await prefs.setString('daily_horoscope_json', horoscopeJson);
    } catch (e) {
      // Keep old or default
    }

    // Fetch Quote
    try {
      String quoteJson = await AIService.getDailyQuote(isGuest ? null : sign, lang);
      await prefs.setString('daily_quote_json', quoteJson);
    } catch (e) {
      // Keep old
    }

    await prefs.setString('last_fetch_date', today);
    _loadFromPrefs(prefs);
  }

  void _loadFromPrefs(SharedPreferences prefs) {
    String? hJson = prefs.getString('daily_horoscope_json');
    String? qJson = prefs.getString('daily_quote_json');

    if (hJson != null) {
      try {
        final data = jsonDecode(hJson);
        setState(() {
          horoscopeData = data;
          horoscopeSummary = data['summary'] ?? "No summary available.";
          if (isGuest && horoscopeSummary.length > 80) {
             horoscopeSummary = "${horoscopeSummary.substring(0, 80)}...";
          }
        });
      } catch (e) {
        setState(() => horoscopeSummary = "Forecast unavailable.");
      }
    }

    if (qJson != null) {
      try {
        final data = jsonDecode(qJson);
        setState(() {
          quoteText = data['quote'] ?? quoteText;
          quoteAuthor = data['author'] ?? "";
        });
      } catch (e) {
        // Ignore
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
          content: const Text("Please log in to unlock this feature.", style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
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
      if (route == 'LoveMatch') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoveMatchScreen()));
      } else if (route == 'HoroscopeDetail') {
        if (horoscopeData != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => HoroscopeDetailScreen(
            signName: "Daily Forecast",
            signIcon: Icons.auto_awesome,
            data: horoscopeData!
          )));
        }
      } else {
        Navigator.pushNamed(context, route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        String displayName = isGuest ? "Guest" : userProvider.name.split(' ')[0];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         "Namaste, $displayName!",
                         style: const TextStyle(
                           fontSize: 28,
                           fontWeight: FontWeight.bold,
                           color: Colors.white
                         ),
                       ),
                     ],
                   ),

                   // Profile Icon Small
                   if (!isGuest && userProvider.profileImageBase64 != null)
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: MemoryImage(base64Decode(userProvider.profileImageBase64!)),
                        backgroundColor: Colors.transparent,
                      )
                   else if (!isGuest)
                      const CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.person),
                      )
                ],
              ),

              const SizedBox(height: 24),

              // Daily Horoscope Card
          const Text(
            "What do the stars have for you today?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey
            ),
          ),

          const SizedBox(height: 24),

          // Daily Horoscope Card
          GestureDetector(
            onTap: () => _checkAccess('HoroscopeDetail'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1016), // Dark card bg
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Daily Horoscope", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(Icons.arrow_forward_ios, color: AppColors.primaryGold, size: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGold.withOpacity(0.1),
                        ),
                        child: const Icon(Icons.balance, color: AppColors.primaryGold, size: 32), // Libra Icon
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Forecast", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              horoscopeSummary,
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Ask AI Sage Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _checkAccess('/chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: AppColors.primaryGold.withOpacity(0.4),
              ),
              child: const Text("Ask AI Sage", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 24),

          // Grid: Kundli & Love Match
          Row(
            children: [
              Expanded(
                child: _buildGridCard(
                  title: "Generate Kundli",
                  icon: Icons.auto_awesome, // Sparkle icon
                  iconColor: const Color(0xFF1DE9B6), // Teal accent
                  onTap: () => _checkAccess('/kundli'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridCard(
                  title: "Love Match",
                  icon: Icons.favorite, // Heart icon
                  iconColor: const Color(0xFFFF4081), // Pink accent
                  onTap: () => _checkAccess('LoveMatch'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quote Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF371B58), Color(0xFF6A0DAD)], // Purple gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: AppColors.primaryGold, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "\"$quoteText\"",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      if (quoteAuthor.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          "- $quoteAuthor",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),

              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildGridCard({required String title, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF0E1016),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
