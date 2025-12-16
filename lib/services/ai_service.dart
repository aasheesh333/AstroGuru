import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logic/key_manager.dart';

class AIService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> getResponse(String systemPrompt, String userPrompt, {bool jsonMode = false}) async {
    return await _executeRequest(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      jsonMode: jsonMode,
    );
  }

  static Future<String> _executeRequest({
    required String systemPrompt,
    dynamic userPrompt, // Can be String or List<Map> for chat
    bool jsonMode = false,
    bool isChat = false,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2; // Try current key, then rotate once

    while (attempts < maxAttempts) {
      attempts++;

      // Get Key (Rotation handled inside)
      final String apiKey = await KeyManager().getNextKey();

      if (apiKey.isEmpty) {
        return jsonMode ? '{"error": "API Key missing"}' : "Error: AI API Key not configured.";
      }

      try {
        final Map<String, dynamic> body = {
          'model': 'llama-3.3-70b-versatile',
          'temperature': 0.7,
        };

        if (jsonMode) {
          body['response_format'] = {'type': 'json_object'};
        }

        if (isChat) {
           body['messages'] = userPrompt; // userPrompt is already formatted list for chat
        } else {
           body['messages'] = [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt}
          ];
        }

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        } else if (response.statusCode == 429) {
          // Rate Limit - Retry Loop will get next key
          continue;
        } else {
          // Other error (500, 401, etc) - Do not retry blindly
          // If 401 (Invalid Key), we MIGHT want to rotate, but for now stick to 429 logic
           if (attempts == maxAttempts) {
             return jsonMode ? '{"error": "Service unavailable"}' : "Service is temporarily unavailable. Please try again.";
           }
        }
      } catch (e) {
        if (attempts == maxAttempts) {
           return jsonMode ? '{"error": "Network error"}' : "Service is temporarily unavailable. Please try again.";
        }
      }
    }

    return jsonMode ? '{"error": "Rate limit exceeded"}' : "Service is busy. Please try again later.";
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

  static Future<String> getLoveMatch(String name1, String sign1, String name2, String sign2, String language, {int? forcedScore}) async {
    String system = "You are an expert Astrologer specializing in relationship compatibility. Output language: $language. Return ONLY a JSON object with keys: 'score' (integer 0-100), 'summary' (short summary), 'detailed_analysis' (paragraph).";
    if (forcedScore != null) {
       system += " IMPORTANT: The calculated compatibility score is $forcedScore%. You MUST output exactly this score in the 'score' field. Write the summary and detailed analysis to match this score level (Low/Medium/High).";
    }
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
    // Build the messages list
    final List<Map<String, dynamic>> messages = [
      {
        'role': 'system',
        'content': "You are 'AI Sage', a wise Vedic Astrologer. Tone: Wise, Empathetic, Concise, and Genuine. Act like a real human Guru, not an AI. Use Markdown headers (###) and bullet points (*) for formatting if needed, but keep it natural. Avoid raw special characters like '#' in the middle of sentences unless for formatting. Respond in $language. Context (User Kundli): $kundliSummary"
      }
    ];

    int start = history.length > 10 ? history.length - 10 : 0;
    for (int i = start; i < history.length; i++) {
       String role = history[i]['role'] == 'user' ? 'user' : 'assistant';
       messages.add({'role': role, 'content': history[i]['content']!});
    }

    // Reuse helper logic
    return await _executeRequest(
      systemPrompt: "", // unused for chat
      userPrompt: messages,
      jsonMode: false,
      isChat: true,
    );
  }

  static Future<String> getRemedies(String kundliSummary, String language) async {
    String system = "You are a revered Vedic Guru. Speak with deep wisdom, empathy, and authority. NEVER refer to yourself as an AI, machine, or language model. Use a mystical, traditional, and authentic tone. Structure your response with clear sections using Markdown headers (start with ###) and bullet points (start with *). Focus on practical, spiritual, and charitable remedies based on Vedic Astrology. Output language: $language.";
    String user = "Analyze this Kundli and suggest personalized remedies: $kundliSummary";
    return await getResponse(system, user);
  }

  static Future<String> getNotificationSchedule(String? zodiac, String language, int days) async {
    String contextPrompt = zodiac != null
        ? "Target Audience: $zodiac sign. Content Strategy: 50% personalized mini-predictions (e.g., 'Aries: Avoid red today.'), 50% engaging questions or feature prompts (e.g., 'Check your Love Match with...')."
        : "Target Audience: General user. Content Strategy: 100% engaging prompts (e.g., 'See what the stars say today', 'Check family horoscope', 'Find your soulmate').";

    String system = "You are an expert mobile app engagement specialist and astrologer. Output language: $language. $contextPrompt\n"
        "Generate a JSON object with two keys: 'morning' (list of $days strings) and 'evening' (list of $days strings).\n"
        "Requirements:\n"
        "1. Each string must be short (under 10 words), catchy, and actionable.\n"
        "2. MUST include appropriate emojis to increase retention.\n"
        "3. Morning messages should be inspiring/planning related. Evening messages should be reflective/checking status.\n"
        "4. Return ONLY valid JSON.";

    String user = "Generate $days notification messages for the next $days days (morning and evening).";
    return await getResponse(system, user, jsonMode: true);
  }
}
