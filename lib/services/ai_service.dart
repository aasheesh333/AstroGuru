import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../logic/key_manager.dart';

/// Calls Groq's OpenAI-compatible chat completions endpoint directly from
/// the client. The API key is resolved via [KeyManager], which prefers the
/// `groq_api_keys/groq_api_list` Firestore doc and falls back to a local
/// `.env` value. We retry on 429 with a small exponential backoff.
class AIService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const int _maxAttempts = 3;
  static const String _model = 'llama-3.3-70b-versatile';

  /// Lowered from 0.7 to 0.6 — the higher temperature made horoscopes
  /// feel like obvious template copy. 0.6 keeps the language natural
  /// while reducing generic phrasing.
  static const double _defaultTemperature = 0.6;

  // --- Language support ---------------------------------------------------

  /// Maps ISO-639-1 codes used by the app's LanguageProvider to the full
  /// English name of the language. The AI is much more reliable when
  /// given a full language name ("Hindi") than a bare 2-letter code
  /// ("hi") in the system prompt, especially for Indian languages.
  /// Codes that the app does not ship are not in this map; callers
  /// should use [languageNameFor] which falls back gracefully.
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'Hindi',
    'bn': 'Bengali',
    'mr': 'Marathi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'gu': 'Gujarati',
    'pa': 'Punjabi',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'or': 'Odia',
    'ur': 'Urdu',
    'as': 'Assamese',
  };

  /// Returns the full English language name for an ISO code, or the
  /// code itself if the language is not in the table. An empty input
  /// is returned as-is.
  static String languageNameFor(String code) {
    if (code.isEmpty) return code;
    return _languageNames[code.toLowerCase()] ?? code;
  }

  /// Patterns that suggest the user is asking the AI to switch its
  /// response language. Each pattern is a case-insensitive substring
  /// to look for; the value is the ISO code to switch to.
  ///
  /// We keep the list small and explicit to avoid false positives on
  /// incidental mentions like "I am learning Spanish". A valid request
  /// must contain a "speak/reply/answer/baat/bolo/sollu/..." cue near
  /// the language name.
  static const Map<String, String> _languageOverridePatterns = {
    // English-script cues
    'speak in english': 'en',
    'reply in english': 'en',
    'answer in english': 'en',
    'respond in english': 'en',
    'in english please': 'en',
    'speak english': 'en',
    'use english': 'en',
    'switch to english': 'en',
    'english me baat': 'en',
    'english mein baat': 'en',
    'english me bata': 'en',
    'english mein bata': 'en',
    'speak in hindi': 'hi',
    'reply in hindi': 'hi',
    'answer in hindi': 'hi',
    'respond in hindi': 'hi',
    'in hindi please': 'hi',
    'speak hindi': 'hi',
    'use hindi': 'hi',
    'switch to hindi': 'hi',
    'hindi me baat': 'hi',
    'hindi mein baat': 'hi',
    'hindi me bata': 'hi',
    'hindi mein bata': 'hi',
    'hindi me jawab': 'hi',
    'hindi mein jawab': 'hi',
    'hindi me reply': 'hi',
    'speak in bengali': 'bn',
    'speak in marathi': 'mr',
    'speak in tamil': 'ta',
    'speak in telugu': 'te',
    'speak in gujarati': 'gu',
    'speak in punjabi': 'pa',
    'speak in kannada': 'kn',
    'speak in malayalam': 'ml',
    'speak in odia': 'or',
    'speak in urdu': 'ur',
    'speak in assamese': 'as',
    // Romanized Dravidian & other regional cues
    'tamil la sollu': 'ta',
    'tamil la solra': 'ta',
    'tamil la pesu': 'ta',
    'tamil la pesunga': 'ta',
    'tamil la pesa': 'ta',
    'tamil la': 'ta',
    'tamil me': 'ta',
    'tamil mein': 'ta',
    'telugu lo cheppu': 'te',
    'telugu lo': 'te',
    'telugu me': 'te',
    'telugu mein': 'te',
    'bengali te bolo': 'bn',
    'bengali te bolen': 'bn',
    'bangla te bolo': 'bn',
    'bangla te bolen': 'bn',
    'bengali me': 'bn',
    'bengali mein': 'bn',
    'bangla me': 'bn',
    'bangla mein': 'bn',
    'marathi madhe sang': 'mr',
    'marathi madhe sanga': 'mr',
    'marathi me': 'mr',
    'marathi mein': 'mr',
    'gujarati ma bol': 'gu',
    'gujarati ma bolo': 'gu',
    'gujarati me': 'gu',
    'gujarati mein': 'gu',
    'punjabi vich bol': 'pa',
    'punjabi vich bola': 'pa',
    'punjabi me': 'pa',
    'punjabi mein': 'pa',
    'kannada alli helu': 'kn',
    'kannada alli': 'kn',
    'kannada me': 'kn',
    'kannada mein': 'kn',
    'malayalam il parayoo': 'ml',
    'malayalam il parayuka': 'ml',
    'malayalam il': 'ml',
    'malayalam me': 'ml',
    'malayalam mein': 'ml',
    'odia re katha bala': 'or',
    'odia re kaha': 'or',
    'odia me': 'or',
    'odia mein': 'or',
    'urdu me bolo': 'ur',
    'urdu me': 'ur',
    'urdu mein': 'ur',
    'assamese ot koi dao': 'as',
    'assamese ot': 'as',
    'assamese me': 'as',
    'assamese mein': 'as',
    // Devanagari / regional-script direct mentions
    'हिंदी में': 'hi',
    'हिंदी मे': 'hi',
    'हिन्दी में': 'hi',
    'हिन्दी मे': 'hi',
    'বাংলায়': 'bn',
    'বাংলাতে': 'bn',
    'মরাঠিতে': 'mr',
    'தமிழில்': 'ta',
    'తెలుగులో': 'te',
    'ગુજરાતીમાં': 'gu',
    'ਪੰਜਾਬੀ ਵਿੱਚ': 'pa',
    'ಕನ್ನಡದಲ್ಲಿ': 'kn',
    'മലയാളത്തിൽ': 'ml',
    'ଓଡ଼ିଆରେ': 'or',
    'اردو میں': 'ur',
    'অসমীয়াত': 'as',
  };

  /// Inspects a user message for an explicit request to switch the AI's
  /// response language. Returns the ISO code to switch to, or null if
  /// the message does not contain such a request.
  ///
  /// The detection is conservative: the message must contain a verb
  /// cue ("speak/reply/baat/bolo/...") near the language name, so
  /// incidental mentions like "I am learning Spanish" do not trigger
  /// an override.
  static String? detectLanguageOverride(String message) {
    if (message.isEmpty) return null;
    final lower = message.toLowerCase();
    for (final entry in _languageOverridePatterns.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static Future<String> _postGroq({
    required List<Map<String, dynamic>> messages,
    bool jsonMode = false,
    int maxTokens = 1024,
    double? temperature,
  }) async {
    final apiKey = await KeyManager().getApiKey();
    if (apiKey.isEmpty) {
      throw StateError('Groq API key is not configured.');
    }

    int delayMs = 1000;
    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final body = <String, dynamic>{
          'model': _model,
          'messages': messages,
          'temperature': temperature ?? _defaultTemperature,
          'max_tokens': maxTokens,
        };
        if (jsonMode) {
          body['response_format'] = {'type': 'json_object'};
        }

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final msg = choices[0]['message'] as Map?;
            if (msg != null) {
              return (msg['content'] ?? '').toString();
            }
          }
          return '';
        }

        if (response.statusCode == 429 && attempt < _maxAttempts) {
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs = (delayMs * 2).clamp(1000, 8000);
          continue;
        }

        if (kDebugMode) {
          debugPrint('groq http ${response.statusCode}: ${response.body}');
        }
        throw StateError('Groq request failed: HTTP ${response.statusCode}');
      } on TimeoutException {
        if (attempt < _maxAttempts) {
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs = (delayMs * 2).clamp(1000, 8000);
          continue;
        }
        rethrow;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('groq unexpected error: $e');
        }
        rethrow;
      }
    }
    throw TimeoutException('Groq: max retries exceeded');
  }

  // --- Prompt builders (public for testing) -------------------------------

  static String _horoscopeSystemPrompt(String language, String? kundliContext) {
    final langName = languageNameFor(language);
    final base = "You are an expert Vedic Astrologer. Output language: $langName. "
        "Write every value in the JSON in $langName. "
        "Return ONLY a JSON object with the following keys: 'summary' (2 sentences), "
        "'love' (forecast), 'career' (forecast), 'health' (forecast), 'lucky_number', "
        "'lucky_color'. Ensure the JSON is valid.";
    if (kundliContext == null || kundliContext.isEmpty) return base;
    return "$base\nPersonalize the forecast for the user whose Kundli is:\n$kundliContext";
  }

  static String dailyHoroscopeSystemPrompt({
    required String language,
    String? kundliContext,
  }) =>
      _horoscopeSystemPrompt(language, kundliContext);

  static String dailyHoroscopeUserPrompt({
    required String sign,
    required DateTime date,
  }) =>
      "Generate a daily horoscope for $sign for ${date.toIso8601String()}.";

  static String weeklyHoroscopeSystemPrompt({
    required String language,
    String? kundliContext,
  }) =>
      _horoscopeSystemPrompt(language, kundliContext);

  static String weeklyHoroscopeUserPrompt({
    required String sign,
    required DateTime date,
  }) =>
      "Generate a weekly horoscope for $sign for the week containing ${date.toIso8601String()}.";

  static String monthlyHoroscopeSystemPrompt({
    required String language,
    String? kundliContext,
  }) =>
      _horoscopeSystemPrompt(language, kundliContext);

  static String monthlyHoroscopeUserPrompt({
    required String sign,
    required DateTime date,
  }) =>
      "Generate a monthly horoscope for $sign for the month of ${date.month}, ${date.year}.";

  // --- Public API ---------------------------------------------------------

  static Future<String> getResponse(
    String systemPrompt,
    String userPrompt, {
    bool jsonMode = false,
  }) {
    return _postGroq(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      jsonMode: jsonMode,
    );
  }

  static Future<String> getDailyHoroscope(
    String sign,
    DateTime date,
    String language, {
    String? kundliContext,
  }) {
    return getResponse(
      dailyHoroscopeSystemPrompt(language: language, kundliContext: kundliContext),
      dailyHoroscopeUserPrompt(sign: sign, date: date),
      jsonMode: true,
    );
  }

  static Future<String> getWeeklyHoroscope(
    String sign,
    DateTime date,
    String language, {
    String? kundliContext,
  }) {
    return getResponse(
      weeklyHoroscopeSystemPrompt(language: language, kundliContext: kundliContext),
      weeklyHoroscopeUserPrompt(sign: sign, date: date),
      jsonMode: true,
    );
  }

  static Future<String> getMonthlyHoroscope(
    String sign,
    DateTime date,
    String language, {
    String? kundliContext,
  }) {
    return getResponse(
      monthlyHoroscopeSystemPrompt(language: language, kundliContext: kundliContext),
      monthlyHoroscopeUserPrompt(sign: sign, date: date),
      jsonMode: true,
    );
  }

  static Future<String> getLoveMatch(
    String name1,
    String sign1,
    String name2,
    String sign2,
    String language, {
    int? forcedScore,
    String? kundliContext1,
    String? kundliContext2,
  }) {
    String system = "You are an expert Astrologer specializing in relationship compatibility. Output language: ${languageNameFor(language)}. Write 'summary' and 'detailed_analysis' in ${languageNameFor(language)}. Return ONLY a JSON object with keys: 'score' (integer 0-100), 'summary' (short summary), 'detailed_analysis' (paragraph).";
    if (forcedScore != null) {
      system += " IMPORTANT: The calculated compatibility score is $forcedScore%. You MUST output exactly this score in the 'score' field. Write the summary and detailed analysis to match this score level (Low/Medium/High).";
    }
    if (kundliContext1 != null && kundliContext1.isNotEmpty) {
      system += "\nUser 1 ($name1) Kundli: $kundliContext1";
    }
    if (kundliContext2 != null && kundliContext2.isNotEmpty) {
      system += "\nUser 2 ($name2) Kundli: $kundliContext2";
    }
    final user = "Analyze compatibility between $name1 ($sign1) and $name2 ($sign2).";
    return getResponse(system, user, jsonMode: true);
  }

  static String quoteSystemPrompt({
    required String language,
    String? kundliContext,
  }) {
    final langName = languageNameFor(language);
    final base = "You are a spiritual guide. Output language: $langName. Write both the 'quote' and 'author' values in $langName. Return ONLY a JSON object with keys: 'quote', 'author'.";
    if (kundliContext == null || kundliContext.isEmpty) return base;
    return "$base\nTie the quote to: $kundliContext";
  }

  static String quoteUserPrompt({
    required String? sign,
    String? kundliContext,
  }) {
    if (sign != null) {
      return "Give me a spiritual quote relevant to a $sign today.";
    }
    return "Give me a general inspiring spiritual quote.";
  }

  static Future<String> getDailyQuote(
    String? sign,
    String language, {
    String? kundliContext,
  }) {
    return getResponse(
      quoteSystemPrompt(language: language, kundliContext: kundliContext),
      quoteUserPrompt(sign: sign, kundliContext: kundliContext),
      jsonMode: true,
    );
  }

  /// Builds the full message list (system + history + new query) for the
  /// AI Sage chat endpoint. Exposed for testing.
  ///
  /// The system prompt embeds the full user context (identity, address,
  /// kundli, recent mentions) so the Sage can answer with full awareness
  /// of who the user is and what they have mentioned in the conversation.
  ///
  /// Language rule: the Sage responds strictly in the app's selected
  /// language (passed in as a 2-letter code; we translate it to the
  /// full name so the model does not have to). The user can ask the
  /// Sage to switch languages mid-conversation; once it switches, it
  /// keeps that new language for the rest of the chat. The prompt
  /// makes this contract explicit so the model does not silently
  /// drift back to English when a user message is in English script.
  static List<Map<String, dynamic>> chatResponseMessages({
    required String query,
    required String userContext,
    required String language,
    required List<Map<String, String>> history,
  }) {
    final langName = languageNameFor(language);
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': "You are 'AI Sage', a wise Vedic Astrologer. Tone: Wise, Empathetic, Concise, and Genuine. Act like a real human Guru, not an AI. Use Markdown headers (###) and bullet points (*) for formatting if needed, but keep it natural. Avoid raw special characters like '#' in the middle of sentences unless for formatting.\n\n"
            "LANGUAGE RULE: Respond strictly in $langName. Every word of your reply must be in $langName; do not mix in English or any other language. Do not switch languages unless the user explicitly asks you to. If the user writes in a different language or script, you may still reply in $langName — they will understand. If the user clearly asks (e.g. 'speak in Hindi', 'Hindi me baat karo', 'हिंदी में जवाब दो') to switch to a specific language, switch to that language and continue in it for the rest of the conversation.\n\n"
            "$userContext"
      }
    ];

    final start = history.length > 10 ? history.length - 10 : 0;
    for (int i = start; i < history.length; i++) {
      final role = history[i]['role'] == 'user' ? 'user' : 'assistant';
      messages.add({'role': role, 'content': history[i]['content']!});
    }
    messages.add({'role': 'user', 'content': query});

    return messages;
  }

  static Future<String> getChatResponse(
    String query,
    String userContext,
    String language,
    List<Map<String, String>> history,
  ) {
    return _postGroq(
      messages: chatResponseMessages(
        query: query,
        userContext: userContext,
        language: language,
        history: history,
      ),
    );
  }

  static String remedySystemPrompt({
    required String language,
    String? kundliContext,
  }) {
    final langName = languageNameFor(language);
    final base = "You are a revered Vedic Guru. Speak with deep wisdom, empathy, and authority. NEVER refer to yourself as an AI, machine, or language model. Use a mystical, traditional, and authentic tone. Structure your response with clear sections using Markdown headers (start with ###) and bullet points (start with *). Focus on practical, spiritual, and charitable remedies based on Vedic Astrology. Output language: $langName. Write every section, header, and bullet in $langName.";
    if (kundliContext == null || kundliContext.isEmpty) return base;
    return "$base\nPersonalize remedies for this Kundli:\n$kundliContext";
  }

  static String remedyUserPrompt({String? kundliContext}) {
    if (kundliContext != null && kundliContext.isNotEmpty) {
      return "Analyze this Kundli and suggest personalized remedies: $kundliContext";
    }
    return "Suggest general Vedic remedies.";
  }

  static Future<String> getRemedies(String kundliContext, String language) {
    return getResponse(
      remedySystemPrompt(language: language, kundliContext: kundliContext),
      remedyUserPrompt(kundliContext: kundliContext),
    );
  }

  static Future<String> getNotificationSchedule(
    String? zodiac,
    String language,
    int days, {
    DateTime? startDate,
  }) {
    final dateStr = startDate != null ? startDate.toIso8601String() : "today";
    final contextPrompt = zodiac != null
        ? "Target Audience: $zodiac sign. Content Strategy: 50% personalized mini-predictions (e.g., 'Aries: Avoid red today.'), 50% engaging questions or feature prompts (e.g., 'Check your Love Match with...')."
        : "Target Audience: General user. Content Strategy: 100% engaging prompts (e.g., 'See what the stars say today', 'Check family horoscope', 'Find your soulmate').";

    final langName = languageNameFor(language);
    final system = "You are an expert mobile app engagement specialist and astrologer. Output language: $langName. Write every notification string in $langName. $contextPrompt\n"
        "Generate a JSON object with THREE keys: 'morning' (list of $days strings), 'evening' (list of $days strings), and 'afternoon' (list of objects).\n"
        "Requirements:\n"
        "1. Morning/Evening: List of $days strings each. Short (under 10 words), catchy, actionable, with emojis.\n"
        "2. Morning = Inspiring/Planning. Evening = Reflective/Status.\n"
        "3. 'afternoon': Generate 3-5 objects for the $days day period. Structure: { 'message': string, 'day_offset': int (0 to ${days-1}), 'hour': int (12-16) }.\n"
        "4. Afternoon content: Focus on Festivals, Shubh Muhurat, or specific astrological transits occurring on that specific date (Starting $dateStr). If no festival, use general motivation.\n"
        "5. Return ONLY valid JSON.";

    final user = "Generate notification schedule for the next $days days starting $dateStr.";
    return getResponse(system, user, jsonMode: true);
  }
}
