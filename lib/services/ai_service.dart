import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> getResponse(String systemPrompt, String userPrompt, {bool jsonMode = false}) async {
    // Check both local and CI keys
    final String apiKey = dotenv.env['APP_GROQ_API_KEY'] ?? dotenv.env['GROQ_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      return jsonMode ? '{"error": "API Key missing"}' : "Error: AI API Key not configured.";
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt}
          ],
          'temperature': 0.7,
          'response_format': jsonMode ? {'type': 'json_object'} : null,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return jsonMode ? '{"error": "Service unavailable"}' : "Service is temporarily unavailable. Please try again.";
      }
    } catch (e) {
      return jsonMode ? '{"error": "Network error"}' : "Service is temporarily unavailable. Please try again.";
    }
  }

  static Future<String> getDailyHoroscope(String sign, DateTime date, String language) async {
    String system = "You are an expert Vedic Astrologer. Output language: $language. Return ONLY a JSON object with the following keys: 'summary' (2 sentences), 'love' (forecast), 'career' (forecast), 'health' (forecast), 'lucky_number', 'lucky_color'. Ensure the JSON is valid.";
    String user = "Generate a daily horoscope for $sign for ${date.toIso8601String()}.";
    return await getResponse(system, user, jsonMode: true);
  }

  static Future<String> getLoveMatch(String name1, String sign1, String name2, String sign2, String language) async {
    String system = "You are an expert Astrologer specializing in relationship compatibility. Output language: $language. Return ONLY a JSON object with keys: 'score' (integer 0-100), 'summary' (short summary), 'detailed_analysis' (paragraph).";
    String user = "Analyze compatibility between $name1 ($sign1) and $name2 ($sign2).";
    return await getResponse(system, user, jsonMode: true);
  }

  static Future<String> getDailyQuote(String? sign, String language) async {
    String system = "You are a spiritual guide. Output language: $language. Return ONLY a JSON object with keys: 'quote', 'author'.";
    String user = sign != null
        ? "Give me a spiritual quote relevant to a $sign today."
        : "Give me a general inspiring spiritual quote.";
    return await getResponse(system, user, jsonMode: true);
  }

  static Future<String> getChatResponse(String query, String kundliSummary, String language) async {
    String system = "You are 'AI Sage', a wise Vedic Astrologer. Use the provided Kundli summary to answer specific questions. Tone: Wise, Empathetic. Output language: $language.";
    String user = "User Kundli: $kundliSummary. Question: $query";
    return await getResponse(system, user);
  }

  static Future<String> getRemedies(String kundliSummary, String language) async {
    String system = "Generate personalized astrological remedies based on Vedic astrology. Output language: $language.";
    String user = "Analyze this Kundli and suggest remedies: $kundliSummary";
    return await getResponse(system, user);
  }
}
