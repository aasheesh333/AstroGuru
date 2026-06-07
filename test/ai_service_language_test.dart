import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/services/ai_service.dart';

void main() {
  group('AIService.languageNameFor', () {
    test('returns full English name for known codes', () {
      expect(AIService.languageNameFor('en'), 'English');
      expect(AIService.languageNameFor('hi'), 'Hindi');
      expect(AIService.languageNameFor('bn'), 'Bengali');
      expect(AIService.languageNameFor('mr'), 'Marathi');
      expect(AIService.languageNameFor('ta'), 'Tamil');
      expect(AIService.languageNameFor('te'), 'Telugu');
      expect(AIService.languageNameFor('gu'), 'Gujarati');
      expect(AIService.languageNameFor('pa'), 'Punjabi');
      expect(AIService.languageNameFor('kn'), 'Kannada');
      expect(AIService.languageNameFor('ml'), 'Malayalam');
      expect(AIService.languageNameFor('or'), 'Odia');
      expect(AIService.languageNameFor('ur'), 'Urdu');
      expect(AIService.languageNameFor('as'), 'Assamese');
    });

    test('returns the code as-is for unknown codes (safe fallback)', () {
      expect(AIService.languageNameFor('xx'), 'xx');
      expect(AIService.languageNameFor(''), '');
    });
  });

  group('AIService.detectLanguageOverride', () {
    test('returns null when message has no language request', () {
      expect(
        AIService.detectLanguageOverride('What does my chart say?'),
        isNull,
      );
      expect(
        AIService.detectLanguageOverride('Namaste, kaise hain aap?'),
        isNull,
      );
    });

    test('detects English script request', () {
      expect(
        AIService.detectLanguageOverride('Please speak in English'),
        'en',
      );
      expect(
        AIService.detectLanguageOverride('Can you reply in English please?'),
        'en',
      );
      expect(
        AIService.detectLanguageOverride('English me baat karo'),
        'en',
      );
      expect(
        AIService.detectLanguageOverride('Speak English only'),
        'en',
      );
    });

    test('detects Hindi request in Devanagari script', () {
      expect(
        AIService.detectLanguageOverride('हिंदी में जवाब दो'),
        'hi',
      );
      expect(
        AIService.detectLanguageOverride('कृपया हिंदी में बात करें'),
        'hi',
      );
    });

    test('detects Hindi request in Roman script', () {
      expect(
        AIService.detectLanguageOverride('Hindi me baat karo'),
        'hi',
      );
      expect(
        AIService.detectLanguageOverride('Please reply in Hindi'),
        'hi',
      );
    });

    test('detects other supported Indian languages', () {
      expect(
        AIService.detectLanguageOverride('Tamil la sollu'),
        'ta',
      );
      expect(
        AIService.detectLanguageOverride('বাংলায় উত্তর দিন'),
        'bn',
      );
      expect(
        AIService.detectLanguageOverride('Marathi madhe sang'),
        'mr',
      );
    });

    test('is case-insensitive', () {
      expect(
        AIService.detectLanguageOverride('PLEASE SPEAK IN ENGLISH'),
        'en',
      );
      expect(
        AIService.detectLanguageOverride('hindi mein baat karo'),
        'hi',
      );
    });

    test('does not match when language name is incidental', () {
      // "Spanish" is not supported and the message has no "speak in" cue.
      expect(
        AIService.detectLanguageOverride('I am learning Spanish'),
        isNull,
      );
      expect(
        AIService.detectLanguageOverride('Tell me about English history'),
        isNull,
      );
    });
  });

  group('AIService.chatResponseMessages language handling', () {
    test('system prompt uses full language name, not just the code', () {
      final messages = AIService.chatResponseMessages(
        query: 'Hello',
        userContext: 'ctx',
        language: 'hi',
        history: const [],
      );
      final system = messages.first['content'] as String;
      expect(system, contains('Hindi'),
          reason: 'system prompt must use the full language name');
      expect(system, isNot(contains('Respond in hi.')),
          reason: 'should not expose the raw language code as the only cue');
    });

    test('system prompt includes a strictness instruction', () {
      final messages = AIService.chatResponseMessages(
        query: 'Hello',
        userContext: 'ctx',
        language: 'en',
        history: const [],
      );
      final system = messages.first['content'] as String;
      // The prompt should make it clear that the AI should not switch
      // languages unless the user explicitly asks.
      expect(
        system,
        anyOf(
          contains('strictly'),
          contains('only'),
          contains('Do not switch'),
          contains('unless the user'),
        ),
        reason: 'prompt should make the language rule explicit and strict',
      );
    });

    test('system prompt for English mentions English explicitly', () {
      final messages = AIService.chatResponseMessages(
        query: 'Hello',
        userContext: 'ctx',
        language: 'en',
        history: const [],
      );
      final system = messages.first['content'] as String;
      expect(system, contains('English'));
    });
  });
}
