import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../logic/kundli_service.dart';
import '../logic/remedy_service.dart';
import '../logic/language_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KundliScreen extends StatefulWidget {
  const KundliScreen({super.key});

  @override
  State<KundliScreen> createState() => _KundliScreenState();
}

class _KundliScreenState extends State<KundliScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final TextEditingController _latController = TextEditingController(text: "28.6139");
  final TextEditingController _lonController = TextEditingController(text: "77.2090");
  Map<String, dynamic>? chartData;
  Map<String, dynamic>? remediesData;
  String? aiRemedies;
  bool loadingRemedies = false;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
     String adUnitId = dotenv.env['APP_ADMOB_BANNER_ID'] ?? dotenv.env['ADMOB_BANNER_ID'] ?? '';
     if (adUnitId.isEmpty) return;

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

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _calculate() async {
    final DateTime dt = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute,
    );
    // Hardcoded Lat/Lon for New Delhi for MVP (As user said don't change UI for location input yet, or it's just 'KundliInputScreen' if existing?)
    // The previous code had hardcoded New Delhi. We stick to that unless there is an input field I missed.
    final chart = KundliService.calculateChart(dt, 28.6139, 77.2090);

    setState(() {
      chartData = chart;
      remediesData = RemedyService.getTraditionalRemedies(chart);
      loadingRemedies = true;
    });

    // Fetch AI Remedies
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    String aiRes = await RemedyService.getHybridRemedies(chart, lang);

    if (mounted) {
      setState(() {
        aiRemedies = aiRes;
        loadingRemedies = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.kundli ?? "Kundli")),
      body: Column(
        children: [
          if (_isBannerAdReady)
             SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ListTile(
            title: Text("${AppLocalizations.of(context)?.enterBirthDetails ?? 'Date'}: ${selectedDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.calendar_today, color: Colors.white),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(1900), lastDate: DateTime.now());
              if (d != null) setState(() => selectedDate = d);
            },
          ),
          ListTile(
            title: Text("Time: ${selectedTime.format(context)}", style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.access_time, color: Colors.white),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: selectedTime);
              if (t != null) setState(() => selectedTime = t);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    decoration: const InputDecoration(labelText: "Lat", labelStyle: TextStyle(color: Colors.grey)),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                  )
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _lonController,
                    decoration: const InputDecoration(labelText: "Lon", labelStyle: TextStyle(color: Colors.grey)),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                  )
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _calculate, child: Text(AppLocalizations.of(context)?.calculate ?? "Generate Kundli")),
          const Divider(),
          if (chartData != null) ...[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Planetary Positions", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                  ListTile(title: Text("Lagna (Asc): ${chartData!['lagna']['rashi']} (${chartData!['lagna']['degree'].toStringAsFixed(2)}°)", style: const TextStyle(color: Colors.white))),
                  ...(chartData!['planets'] as List).map((p) => ListTile(
                    title: Text("${p['name']}: ${p['rashi']} (${p['degree'].toStringAsFixed(2)}°) ${p['isRetrograde'] ? '(R)' : ''}", style: const TextStyle(color: Colors.white)),
                    subtitle: Text("Nakshatra: ${p['nakshatra']} (${p['nakshatra_pada']})", style: const TextStyle(color: Colors.grey)),
                  )).toList(),
                  const SizedBox(height: 20),

                  const Text("Doshas Detected", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                   if ((chartData!['doshas'] as List).isEmpty)
                     const Text("No major doshas detected.", style: TextStyle(color: Colors.white))
                   else
                     ...(chartData!['doshas'] as List).map((d) => Text("• $d", style: const TextStyle(color: Colors.redAccent))).toList(),

                   const SizedBox(height: 20),
                   const Text("Remedies (Hybrid)", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                   if (loadingRemedies)
                      const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                   else
                      Text(aiRemedies ?? "No remedies generated.", style: const TextStyle(color: Colors.white)),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}
