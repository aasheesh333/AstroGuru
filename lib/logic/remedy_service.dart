import 'package:flutter/foundation.dart';
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

  static Future<String> getRemedies(List<String> doshas, String kundliSummary, String language) async {
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

    remedies.writeln("\n### Personalized AI Remedies:");

    // 2. Add AI Remedies (50%)
    // We ask the AI to provide complementary remedies based on the full chart summary
    try {
      String aiRemedies = await AIService.getRemedies(kundliSummary, language);
      remedies.writeln(aiRemedies);
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching AI remedies: $e");
      }
      remedies.writeln("Unable to fetch personalized remedies at the moment.");
    }

    return remedies.toString();
  }
}
