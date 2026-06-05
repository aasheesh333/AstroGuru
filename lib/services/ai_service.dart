import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AIService {
  /// Call the server-side `groqProxy` Cloud Function. The actual API key is
  /// stored only in the backend; the client only sees the response.
  /// Implements exponential backoff on resource-exhausted (429 / 503) errors.
  static Future<String> _callProxy({
    required List<Map<String, dynamic>> messages,
    bool jsonMode = false,
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    const int maxAttempts = 4;
    int delayMs = 1000; // start at 1s, double up to 8s

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final callable = FirebaseFunctions.instance
            .httpsCallable('groqProxy', options: HttpsCallableOptions(
              timeout: const Duration(seconds: 60),
            ));
        final result = await callable.call({
          'messages': messages,
          'jsonMode': jsonMode,
          'maxTokens': maxTokens,
          'temperature': temperature,
        });
        final data = Map<String, dynamic>.from(result.data as Map);
        return (data['content'] as String?) ?? '';
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'resource-exhausted' && attempt < maxAttempts) {
          // 429: exponential backoff
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs = (delayMs * 2).clamp(1000, 8000);
          continue;
        }
        if (kDebugMode) {
          debugPrint('groqProxy failed (${e.code}): ${e.message}');
        }
        rethrow;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('groqProxy unexpected error: $e');
        }
        rethrow;
      }
    }
    throw TimeoutException('groqProxy: max retries exceeded');
  }

  static Future<String> getResponse(String systemPrompt, String userPrompt, {bool jsonMode = false}) async {
    return await _callProxy(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      jsonMode: jsonMode,
    );
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

    return await _callProxy(messages: messages);
  }

  static Future<String> getRemedies(String kundliSummary, String language) async {
    String system = "You are a revered Vedic Guru. Speak with deep wisdom, empathy, and authority. NEVER refer to yourself as an AI, machine, or language model. Use a mystical, traditional, and authentic tone. Structure your response with clear sections using Markdown headers (start with ###) and bullet points (start with *). Focus on practical, spiritual, and charitable remedies based on Vedic Astrology. Output language: $language.";
    String user = "Analyze this Kundli and suggest personalized remedies: $kundliSummary";
    return await getResponse(system, user);
  }

  static Future<String> getNotificationSchedule(String? zodiac, String language, int days, {DateTime? startDate}) async {
    String dateStr = startDate != null ? startDate.toIso8601String() : "today";
    String contextPrompt = zodiac != null
        ? "Target Audience: $zodiac sign. Content Strategy: 50% personalized mini-predictions (e.g., 'Aries: Avoid red today.'), 50% engaging questions or feature prompts (e.g., 'Check your Love Match with...')."
        : "Target Audience: General user. Content Strategy: 100% engaging prompts (e.g., 'See what the stars say today', 'Check family horoscope', 'Find your soulmate').";

    String system = "You are an expert mobile app engagement specialist and astrologer. Output language: $language. $contextPrompt\n"
        "Generate a JSON object with THREE keys: 'morning' (list of $days strings), 'evening' (list of $days strings), and 'afternoon' (list of objects).\n"
        "Requirements:\n"
        "1. Morning/Evening: List of $days strings each. Short (under 10 words), catchy, actionable, with emojis.\n"
        "2. Morning = Inspiring/Planning. Evening = Reflective/Status.\n"
        "3. 'afternoon': Generate 3-5 objects for the $days day period. Structure: { 'message': string, 'day_offset': int (0 to ${days-1}), 'hour': int (12-16) }.\n"
        "4. Afternoon content: Focus on Festivals, Shubh Muhurat, or specific astrological transits occurring on that specific date (Starting $dateStr). If no festival, use general motivation.\n"
        "5. Return ONLY valid JSON.";

    String user = "Generate notification schedule for the next $days days starting $dateStr.";
    return await getResponse(system, user, jsonMode: true);
  }
}
