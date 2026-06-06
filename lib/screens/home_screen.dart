import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/language_provider.dart';
import '../logic/user_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../utils/rate_app_launcher.dart';
import 'login_screen.dart';
import 'horoscope_detail_screen.dart';
import 'love_match_screen.dart';
import '../utils/zodiac_utils.dart';

// HomeScreen Content Widget
class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String horoscopeSummary = "Loading daily forecast...";
  Map<String, dynamic>? horoscopeData;

  String quoteText = "The stars incline, but do not bind.";
  String quoteAuthor = "";

  bool isGuest = false;
  String? _lastKnownZodiac;
  String? _lastKnownLang;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    bool needsReload = false;

    // Check Zodiac Change
    if (_lastKnownZodiac != null && _lastKnownZodiac != userProvider.zodiac) {
       _lastKnownZodiac = userProvider.zodiac;
       needsReload = true;
    } else if (_lastKnownZodiac == null) {
       _lastKnownZodiac = userProvider.zodiac;
    }

    // Check Language Change
    if (_lastKnownLang != null && _lastKnownLang != langProvider.locale.languageCode) {
       _lastKnownLang = langProvider.locale.languageCode;
       needsReload = true;
    } else if (_lastKnownLang == null) {
       _lastKnownLang = langProvider.locale.languageCode;
    }

    if (needsReload) {
      _loadData(forceRefresh: true);
    }
  }

  void _loadData({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      bool guest = prefs.getBool('guest_mode') ?? false;

      setState(() {
        isGuest = guest;
      });

      _checkDailyUpdates(prefs, forceRefresh);
      _maybeRequestInAppReview();
    } catch (e) {
      // Handle error safely
    }
  }

  /// Ask the user to rate the app once they have been using it for at least
  /// 7 days and have performed 3 or more key actions. We only ask once.
  Future<void> _incrementCompletedActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt('completed_actions') ?? 0;
      await prefs.setInt('completed_actions', current + 1);
    } catch (_) {
      // Non-critical counter; ignore failures.
    }
  }

  Future<void> _maybeRequestInAppReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('in_app_review_requested') == true) return;

      final firstOpen = prefs.getInt('first_open_ms');
      final now = DateTime.now().millisecondsSinceEpoch;
      if (firstOpen == null) {
        await prefs.setInt('first_open_ms', now);
        return;
      }
      final ageMs = now - firstOpen;
      if (ageMs < const Duration(days: 7).inMilliseconds) return;

      final actions = prefs.getInt('completed_actions') ?? 0;
      if (actions < 3) return;

      await RateAppLauncher.openPlayStoreListing();
      await prefs.setBool('in_app_review_requested', true);
    } catch (_) {
      // InAppReview may not be available on emulators / unsupported devices.
    }
  }

  void _checkDailyUpdates(SharedPreferences prefs, bool forceRefresh) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    String today = DateTime.now().toIso8601String().split('T')[0];
    // Cache invalidation logic relies on date AND language
    String lastDateKey = 'last_fetch_date_$lang';
    String lastDate = prefs.getString(lastDateKey) ?? "";

    if (forceRefresh || lastDate != today) {
       await _fetchNewData(prefs, today, lang, lastDateKey);
    } else {
       _loadFromPrefs(prefs, lang);
    }
  }

  Future<void> _fetchNewData(SharedPreferences prefs, String today, String lang, String lastDateKey) async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String sign = isGuest ? "Aries" : userProvider.zodiac;
    // For non-guest users with a DOB, build the kundli context once and
    // pass it to every AI call. For guests, the kundli context is empty
    // and the AI service falls back to zodiac-only prompts.
    final kundliContext = isGuest ? null : userProvider.getKundliContext();

    try {
      String horoscopeJson = await AIService.getDailyHoroscope(
        sign,
        DateTime.now(),
        lang,
        kundliContext: kundliContext,
      );
      await prefs.setString('daily_horoscope_json_$lang', horoscopeJson);
    } catch (e) {
      // Keep old or default
    }

    // Fetch Quote
    try {
      String quoteJson = await AIService.getDailyQuote(
        isGuest ? null : sign,
        lang,
        kundliContext: kundliContext,
      );
      await prefs.setString('daily_quote_json_$lang', quoteJson);
    } catch (e) {
      // Keep old
    }

    await prefs.setString(lastDateKey, today);
    _loadFromPrefs(prefs, lang);
  }

  void _loadFromPrefs(SharedPreferences prefs, String lang) {
    String? hJson = prefs.getString('daily_horoscope_json_$lang');
    String? qJson = prefs.getString('daily_quote_json_$lang');

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
    _incrementCompletedActions();
    if (isGuest) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          title: Text(AppLocalizations.of(context)!.loginRequiredTitle, style: const TextStyle(color: AppColors.deepGold)),
          content: Text(AppLocalizations.of(context)!.loginRequiredMsg, style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: Text(AppLocalizations.of(context)!.loginNow),
            ),
          ],
        ),
      );
    } else {
      if (route == 'LoveMatch') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoveMatchScreen()));
      } else if (route == 'HoroscopeDetail') {
        if (horoscopeData != null) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final signName = isGuest ? "Aries" : userProvider.zodiac;
          Navigator.push(context, MaterialPageRoute(builder: (_) => HoroscopeDetailScreen(
            signName: signName,
            signIcon: ZodiacUtils.getIcon(signName),
            data: horoscopeData!
          )));
        }
      } else if (route == '/chat') {
        // Switch to AI Chat Tab (Index 3)
        widget.onTabChange?.call(3);
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
        String signName = isGuest ? "Aries" : userProvider.zodiac;
        // Localize Sign Name
        String localizedSignName = ZodiacUtils.getLocalizedName(context, signName);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Row
              Row(
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         "${AppLocalizations.of(context)!.greeting}, $displayName!",
                         style: const TextStyle(
                           fontSize: 28,
                           fontWeight: FontWeight.bold,
                           color: Colors.white
                         ),
                       ),
                     ],
                   ),
                ],
              ),

              const SizedBox(height: 24),

              // Daily Horoscope Card
          Text(
            AppLocalizations.of(context)!.homeSubtitle,
            style: const TextStyle(
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
                color: AppColors.surfaceColor, // Dark card bg
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.dailyHoroscopeTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Icon(Icons.arrow_forward_ios, color: AppColors.primaryGold, size: 16),
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
                        child: Icon(ZodiacUtils.getIcon(signName), color: AppColors.primaryGold, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$localizedSignName ${AppLocalizations.of(context)!.forecast}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
              child: Text(AppLocalizations.of(context)!.askAiSageBtn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 24),

          // Grid: Kundli & Love Match
          Row(
            children: [
              Expanded(
                child: _buildGridCard(
                  title: AppLocalizations.of(context)!.generateKundliBtn,
                  icon: Icons.auto_awesome, // Sparkle icon
                  iconColor: AppColors.accentTeal, // Teal accent
                  onTap: () => _checkAccess('/kundli'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridCard(
                  title: AppLocalizations.of(context)!.loveMatchBtn,
                  icon: Icons.favorite, // Heart icon
                  iconColor: AppColors.accentPink, // Pink accent
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
                colors: [AppColors.deepPurple, AppColors.primaryPurple], // Purple gradient
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
          color: AppColors.surfaceColor,
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
