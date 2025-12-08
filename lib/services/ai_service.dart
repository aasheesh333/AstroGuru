import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> getResponse(String systemPrompt, String userPrompt) async {
    // Try local APP_ prefix first, then global (though .env usually has APP_ for local)
    // The user requirement says Local: APP_GROQ_API_KEY, GitHub: GROQ_API_KEY.
    // In code, we usually read what's in .env or passed via --dart-define.
    // Since we only load .env in main.dart, we check that.
    String apiKey = dotenv.env['APP_GROQ_API_KEY'] ?? dotenv.env['GROQ_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      // Last resort: check if it was injected as a const (not common with dotenv but possible if we used --dart-define)
      // For now, return error.
      return "Error: AI API Key not configured.";
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userPrompt}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        // Log error internally if needed, but show friendly message to user
        debugPrint("AI Service Error: ${response.statusCode} - ${response.body}");
        return "Service temporarily busy. Please try again.";
      }
    } catch (e) {
      debugPrint("AI Connection Error: $e");
      return "Service temporarily busy. Please try again.";
    }
  }

  static Future<String> getDailyHoroscope(String sign, DateTime date, String language, Map<String, dynamic>? planetaryPositions) async {
    String positions = planetaryPositions != null ? planetaryPositions.toString() : "Standard positions";
    String system = "You are an expert Vedic Astrologer. Tone: Friendly, Spiritual, Practical. Output language: $language.";
    String user = "Generate a daily horoscope for $sign for ${date.toIso8601String()}. \n"
                  "Planetary Context: $positions. \n"
                  "Focus on Career, Health, and Relationships. Provide a structured response.";
    return await getResponse(system, user);
  }

  static Future<String> getChatResponse(String query, String kundliSummary, String language) async {
    String system = "You are 'AI Sage', a wise Vedic Astrologer. Use the provided Kundli summary to answer specific questions. Tone: Wise, Empathetic. Output language: $language.";
    String user = "User Kundli Data: $kundliSummary. \nQuestion: $query";
    return await getResponse(system, user);
  }

  static Future<String> getRemedies(String kundliSummary, String language) async {
    String system = "Generate personalized astrological remedies based on Vedic astrology. Output language: $language.";
    String user = "Analyze this Kundli and suggest remedies based on weak planets and doshas: $kundliSummary";
    return await getResponse(system, user);
  }
}
