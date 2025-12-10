import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
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

  /// Generates a unique cache key based on the input parameters.
  static String _generateCacheKey(List<String> doshas, String kundliSummary, String language) {
    // We create a hash of the inputs to ensure uniqueness
    final String data = "${doshas.join(',')}|$kundliSummary|$language";
    final bytes = utf8.encode(data);
    final digest = md5.convert(bytes);
    return 'remedy_cache_$digest';
  }

  static Future<String> getRemedies(List<String> doshas, String kundliSummary, String language) async {
    // 1. Check Cache
    final String cacheKey = _generateCacheKey(doshas, kundliSummary, language);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedRemedies = prefs.getString(cacheKey);

    if (cachedRemedies != null && cachedRemedies.isNotEmpty) {
      if (kDebugMode) {
        print("Fetching remedies from Cache for key: $cacheKey");
      }
      return cachedRemedies;
    }

    // 2. Generate Remedies
    StringBuffer remedies = StringBuffer();

    // Add Rule-Based Remedies (First Section)
    remedies.writeln("### Traditional Remedies");
    if (doshas.isEmpty) {
      remedies.writeln("- No major doshas detected. Focus on strengthening your favorable planets.");
    } else {
      for (String dosha in doshas) {
        if (_ruleBasedRemedies.containsKey(dosha)) {
          remedies.writeln("- **$dosha**: ${_ruleBasedRemedies[dosha]}");
        }
      }
    }
    remedies.writeln(""); // Spacing

    // Add AI Remedies (Second Section)
    // Note: We removed the hardcoded "### Personalized AI Remedies:" header.
    // The AI is now instructed to use its own mystical headers.
    try {
      String aiRemedies = await AIService.getRemedies(kundliSummary, language);
      remedies.writeln(aiRemedies);
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching AI remedies: $e");
      }
      remedies.writeln("Unable to fetch personalized insights at this moment.");
    }

    final String result = remedies.toString();

    // 3. Save to Cache
    await prefs.setString(cacheKey, result);

    return result;
  }
}
