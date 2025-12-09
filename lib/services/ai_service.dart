import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> getResponse(String systemPrompt, String userPrompt) async {
    // Check both local and CI keys
    final String apiKey = dotenv.env['APP_GROQ_API_KEY'] ?? dotenv.env['GROQ_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
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
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Service is temporarily unavailable. Please try again.";
      }
    } catch (e) {
      return "Service is temporarily unavailable. Please try again.";
    }
  }

  static Future<String> getDailyHoroscope(String sign, DateTime date, String language) async {
    String system = "You are an expert Vedic Astrologer. Tone: Friendly, Spiritual, Practical. Output language: $language.";
    String user = "Generate a daily horoscope for $sign for ${date.toIso8601String()}. Focus on career, health, and relationships.";
    return await getResponse(system, user);
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
