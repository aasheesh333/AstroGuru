import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadHoroscope();
    _loadAd();
    _loadInterstitialAd();
  }

  void _loadAd() {
     // Use APP_ prefix for local as per requirement, but also fallback
     String adUnitId = dotenv.env['APP_ADMOB_BANNER_ID'] ?? dotenv.env['ADMOB_BANNER_ID'] ?? '';
     if (adUnitId.isEmpty) return; // Skip if no ID

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _isBannerAdReady = false;
        },
      ),
    );
    _bannerAd?.load();
  }

  void _loadInterstitialAd() {
    String adUnitId = dotenv.env['APP_ADMOB_INTERSTITIAL_ID'] ?? dotenv.env['ADMOB_INTERSTITIAL_ID'] ?? '';
    if (adUnitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAndNavigate(String route) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd(); // Load next
          Navigator.pushNamed(context, route);
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          Navigator.pushNamed(context, route);
        },
      );
      _interstitialAd!.show();
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  void _loadHoroscope() async {
    // Placeholder logic for sign - In a real app, this would come from User Profile/SharedPrefs
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    // We pass null for planetary positions here as HomeScreen might not have recalculated Kundli yet.
    // Ideally we cache the last calculated Kundli.
    String result = await AIService.getDailyHoroscope("Aries", DateTime.now(), lang, null);
    if (mounted) {
      setState(() {
        horoscope = result;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.appName ?? "AstroPrerna"),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isBannerAdReady)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
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
                       Text(AppLocalizations.of(context)?.dailyHoroscope ?? "Daily Horoscope", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)),
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
                ElevatedButton(
                  onPressed: () => _showInterstitialAndNavigate('/kundli'),
                  child: Text(AppLocalizations.of(context)?.kundli ?? "Kundli")
                ),
                ElevatedButton(
                  onPressed: () => _showInterstitialAndNavigate('/chat'),
                  child: Text(AppLocalizations.of(context)?.chat ?? "Ask Sage")
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
