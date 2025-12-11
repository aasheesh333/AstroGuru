import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class RemedyService {
  // 50% Rule-based Remedies (Static Library)
  static const Map<String, String> _ruleBasedRemedies = {
    'Mangal': "Recite Hanuman Chalisa daily. Offer red flowers to Lord Hanuman on Tuesdays.",
    'Mars': "Recite Hanuman Chalisa daily. Offer red flowers to Lord Hanuman on Tuesdays.",
    'Kaal Sarp': "Perform Rudrabhishek on Mondays. Chant 'Om Namah Shivaya' 108 times daily.",
    'Guru Chandal': "Donate yellow pulses or clothes on Thursdays. Respect elders and teachers.",
    'Chandal': "Donate yellow pulses or clothes on Thursdays. Respect elders and teachers.",
    'Surya Grahan': "Offer water to the rising Sun daily. Chant the Aditya Hridaya Stotram.",
    'Sun Eclipse': "Offer water to the rising Sun daily. Chant the Aditya Hridaya Stotram.",
    'Chandra Grahan': "Donate white items (rice, milk) on Mondays. Meditate for mental peace.",
    'Moon Eclipse': "Donate white items (rice, milk) on Mondays. Meditate for mental peace.",
    'Sade Sati': "Light a mustard oil lamp under a Peepal tree on Saturdays. Recite Shani Chalisa.",
    'Saturn': "Light a mustard oil lamp under a Peepal tree on Saturdays. Recite Shani Chalisa.",
  };

  static Future<String> getRemedies(List<String> doshas, String kundliSummary, String language, {String? birthDetailsKey}) async {
    StringBuffer remedies = StringBuffer();

    // 1. Add Rule-Based Remedies (50%)
    remedies.writeln("### Traditional Remedies (Rule-Based):");
    if (doshas.isEmpty) {
      remedies.writeln("- No major doshas detected. Focus on strengthening your favorable planets.");
    } else {
      bool foundAny = false;
      for (String dosha in doshas) {
        String? match;
        // Robust case-insensitive partial matching
        for (var key in _ruleBasedRemedies.keys) {
           if (dosha.toLowerCase().contains(key.toLowerCase()) || key.toLowerCase().contains(dosha.toLowerCase())) {
             match = _ruleBasedRemedies[key];
             break;
           }
        }

        if (match != null) {
           remedies.writeln("- **$dosha**: $match");
           foundAny = true;
        } else {
           // List the dosha even if no specific static remedy is found, so user knows it was detected
           remedies.writeln("- **$dosha**: Consult detailed AI analysis below for specific remedies.");
           foundAny = true;
        }
      }
      if (!foundAny) {
         remedies.writeln("- No specific traditional remedies found for the detected conditions.");
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
