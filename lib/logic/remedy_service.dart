import '../services/ai_service.dart';

class RemedyService {

  // Traditional Remedies Library (Fixed)
  static final Map<String, String> _planetRemedies = {
    'Sun': "Chant Aditya Hridayam Stotram. Offer water to the Sun at sunrise. Donate wheat or copper on Sundays.",
    'Moon': "Perform Shiva Abhishek with milk. Wear a Pearl (Moti) in silver. Respect your mother.",
    'Mars': "Recite Hanuman Chalisa daily. Donate red lentils (Masoor Dal). Wear Red Coral (Moonga).",
    'Mercury': "Worship Tulsi plant. Chant 'Om Budhaya Namaha'. Wear Emerald (Panna). Feed green grass to cows.",
    'Jupiter': "Chant 'Om Brim Brihaspataye Namaha'. Wear Yellow Sapphire (Pukhraj). Donate turmeric or yellow sweets.",
    'Venus': "Worship Goddess Durga. Chant 'Om Shukraya Namaha'. Wear Diamond or Opal. Respect women.",
    'Saturn': "Light a mustard oil lamp under a Peepal tree on Saturdays. Chant Hanuman Chalisa. Donate black sesame seeds.",
    'Rahu': "Float coconut in flowing water. Chant 'Om Ram Rahave Namaha'. Wear Gomed (Hessonite).",
    'Ketu': "Feed street dogs. Chant 'Om Kem Ketave Namaha'. Wear Cat's Eye (Lehsunia).",
  };

  static final Map<String, String> _doshaRemedies = {
    'Mangal Dosh': "Perform Kumbh Vivah before marriage. Visit Hanuman temple on Tuesdays.",
    'Kaalsarp Yoga': "Perform Kaalsarp Dosh Nivaran Puja at Trimbakeshwar or Kalahasti. Chant Mahamrityunjaya Mantra.",
    'Pitra Dosh': "Perform Pind Daan or Tarpan for ancestors during Pitru Paksha. Feed crows and cows.",
    'Shrapit Yoga': "Recite Shani-Rahu curse removal mantras. Perform Rudrabhishek.",
    'Grahan Yoga': "Chant Aditya Hridayam (for Sun) or Om Namah Shivaya (for Moon). Avoid eating during eclipses.",
    'Guru Chandal Yoga': "Worship Lord Vishnu. Respect teachers and elders. Donate yellow items.",
    'Vish Yoga': "Worship Shani Dev and Lord Shiva together. Chant Mahamrityunjaya Mantra.",
    'Kemdrum Yoga': "Keep a Fast on Mondays. Worship Lord Shiva.",
  };

  static Map<String, dynamic> getTraditionalRemedies(Map<String, dynamic> chart) {
    List<String> planetRemedies = [];
    List<String> doshaRemedies = [];

    // Analyze weak planets (simplified logic: if strength < 50)
    // Note: chart['planets'] needs to have 'strength' calculated by KundliService
    if (chart['planets'] != null) {
      for (var p in chart['planets']) {
         if (p['strength'] != null && p['strength'] < 40.0) { // Threshold for weakness
           if (_planetRemedies.containsKey(p['name'])) {
             planetRemedies.add("${p['name']}: ${_planetRemedies[p['name']]}");
           }
         }
      }
    }

    // Doshas
    if (chart['doshas'] != null) {
      for (String dosha in chart['doshas']) {
        if (_doshaRemedies.containsKey(dosha)) {
          doshaRemedies.add("$dosha: ${_doshaRemedies[dosha]}");
        }
      }
    }

    return {
      'traditional_planet_remedies': planetRemedies,
      'traditional_dosha_remedies': doshaRemedies,
    };
  }

  static Future<String> getHybridRemedies(Map<String, dynamic> chart, String language) async {
    // 1. Get Traditional
    Map<String, dynamic> traditional = getTraditionalRemedies(chart);
    String traditionalText = "Traditional Remedies:\n";
    if ((traditional['traditional_planet_remedies'] as List).isNotEmpty) {
      traditionalText += "Planetary:\n" + (traditional['traditional_planet_remedies'] as List).join("\n") + "\n";
    }
    if ((traditional['traditional_dosha_remedies'] as List).isNotEmpty) {
      traditionalText += "Doshas:\n" + (traditional['traditional_dosha_remedies'] as List).join("\n");
    }

    // 2. Get AI Personalized
    String chartSummary = "Lagna: ${chart['lagna']['rashi']}, Moon Sign: ${chart['planets'].firstWhere((p) => p['name'] == 'Moon')['rashi']}. Doshas: ${chart['doshas']}.";
    String aiRemedies = await AIService.getRemedies(chartSummary, language);

    // 3. Combine
    return "$traditionalText\n\nAI Personalized Insights:\n$aiRemedies";
  }
}
