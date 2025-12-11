import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class RemedyService {
  // 50% Rule-based Remedies (Static Library)
  static const Map<String, String> _ruleBasedRemedies = {
    'Mangal Dosh': "Recite Hanuman Chalisa daily. Offer red flowers to Lord Hanuman on Tuesdays.",
    'Kaal Sarp Dosh': "Perform Rudrabhishek on Mondays. Chant 'Om Namah Shivaya' 108 times daily.",
    'Guru Chandal Dosh': "Donate yellow pulses or clothes on Thursdays. Respect elders and teachers.",
    'Surya Grahan Dosh': "Offer water to the rising Sun daily. Chant the Aditya Hridaya Stotram.",
    'Chandra Grahan Dosh': "Donate white items (rice, milk) on Mondays. Meditate for mental peace.",
    'Sade Sati': "Light a mustard oil lamp under a Peepal tree on Saturdays. Recite Shani Chalisa.",
  };

  static Future<String> getRemedies(List<String> doshas, String kundliSummary, String language, {String? birthDetailsKey}) async {
    StringBuffer remedies = StringBuffer();

    // 1. Add Rule-Based Remedies (50%)
    remedies.writeln("### Traditional Remedies (Rule-Based):");
    if (doshas.isEmpty) {
      remedies.writeln("- No major doshas detected. Focus on strengthening your favorable planets.");
    } else {
      for (String dosha in doshas) {
        if (_ruleBasedRemedies.containsKey(dosha)) {
          remedies.writeln("- **$dosha**: ${_ruleBasedRemedies[dosha]}");
        }
      }
    }

    remedies.writeln("\n### Personalized Vedic Remedies:");

    // 2. Add AI Remedies (50%) - with Caching
    try {
      String aiRemedies = "";
      bool fetchedFromCache = false;

      if (birthDetailsKey != null) {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('remedy_cache_$birthDetailsKey');
        if (cached != null && cached.isNotEmpty) {
          aiRemedies = cached;
          fetchedFromCache = true;
        }
      }

      if (!fetchedFromCache) {
        aiRemedies = await AIService.getRemedies(kundliSummary, language);
        // Cache it if we have a key
        if (birthDetailsKey != null && aiRemedies.isNotEmpty && !aiRemedies.contains("Error")) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('remedy_cache_$birthDetailsKey', aiRemedies);
        }
      }

      remedies.writeln(aiRemedies);
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching remedies: $e");
      }
      remedies.writeln("Unable to fetch personalized remedies at the moment.");
    }

    return remedies.toString();
  }
}
