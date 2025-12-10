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

  static Future<String> getWeeklyHoroscope(String sign, DateTime date, String language) async {
    String system = "You are an expert Vedic Astrologer. Output language: $language. Return ONLY a JSON object with the following keys: 'summary' (2 sentences), 'love' (forecast), 'career' (forecast), 'health' (forecast), 'lucky_number', 'lucky_color'. Ensure the JSON is valid.";
    String user = "Generate a weekly horoscope for $sign for the week containing ${date.toIso8601String()}.";
    return await getResponse(system, user, jsonMode: true);
  }

  static Future<String> getMonthlyHoroscope(String sign, DateTime date, String language) async {
    String system = "You are an expert Vedic Astrologer. Output language: $language. Return ONLY a JSON object with the following keys: 'summary' (2 sentences), 'love' (forecast), 'career' (forecast), 'health' (forecast), 'lucky_number', 'lucky_color'. Ensure the JSON is valid.";
    String user = "Generate a monthly horoscope for $sign for the month of ${date.month}, ${date.year}.";
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

  static Future<String> getChatResponse(String query, String kundliSummary, String language, List<Map<String, String>> history) async {
    // Check both local and CI keys
    final String apiKey = dotenv.env['APP_GROQ_API_KEY'] ?? dotenv.env['GROQ_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      return "Error: AI API Key not configured.";
    }

    // Build the messages list including history
    final List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
        'content': "You are 'AI Sage', a wise Vedic Astrologer. Tone: Wise, Empathetic, Concise, and Genuine. Act like a real human Guru, not an AI. Use Markdown headers (###) and bullet points (*) for formatting if needed, but keep it natural. Avoid raw special characters like '#' in the middle of sentences unless for formatting. Output language: $language. Context (User Kundli): $kundliSummary"
      }
    ];

    // Add history (limit to last 10 messages to save context window)
    // IMPORTANT: 'history' includes the current message as the last item (added by UI),
    // so we just add the whole (trimmed) history.
    int start = history.length > 10 ? history.length - 10 : 0;
    for (int i = start; i < history.length; i++) {
       // Map 'sage' role to 'assistant' for the API
       String role = history[i]['role'] == 'user' ? 'user' : 'assistant';
       messages.add({'role': role, 'content': history[i]['content']!});
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
          'messages': messages,
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

  static Future<String> getRemedies(String kundliSummary, String language) async {
    String system = "You are a revered Vedic Guru. Speak with deep wisdom, empathy, and authority. Do not use AI-like phrases (e.g., 'As an AI'). Structure your response with clear sections using Markdown headers (start with ###) and bullet points (start with *). Focus on practical, spiritual, and charitable remedies. Output language: $language.";
    String user = "Analyze this Kundli and suggest personalized remedies: $kundliSummary";
    return await getResponse(system, user);
  }
}
