import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/services/ai_service.dart';

void main() {
  group('AIService prompt builders', () {
    test('dailyHoroscopePrompt embeds the kundli context when provided', () {
      final ctx = 'User birth details:\n- Lagna (Ascendant): Cancer\n- Moon Sign: Scorpio';
      final system = AIService.dailyHoroscopeSystemPrompt(
        language: 'en',
        kundliContext: ctx,
      );
      final user = AIService.dailyHoroscopeUserPrompt(
        sign: 'Aries',
        date: DateTime(2026, 6, 1),
      );

      expect(system, contains(ctx),
          reason: 'system prompt must inject the kundli context so the AI can personalize');
      expect(user, contains('Aries'));
      expect(user, contains('2026-06-01'));
    });

    test('dailyHoroscopePrompt works without kundli context', () {
      final system = AIService.dailyHoroscopeSystemPrompt(language: 'en');
      expect(system, contains('Vedic Astrologer'));
      expect(system, contains('Output language: English'),
          reason: 'prompt should use the full language name, not the ISO code');
    });

    test('weeklyHoroscopePrompt mirrors daily and embeds context', () {
      final ctx = 'Lagna: Cancer';
      final system = AIService.weeklyHoroscopeSystemPrompt(
        language: 'en',
        kundliContext: ctx,
      );
      expect(system, contains(ctx));
      final user = AIService.weeklyHoroscopeUserPrompt(
        sign: 'Leo',
        date: DateTime(2026, 6, 1),
      );
      expect(user, contains('weekly'));
      expect(user, contains('Leo'));
    });

    test('monthlyHoroscopePrompt embeds context and uses month/year', () {
      final ctx = 'Lagna: Cancer';
      final system = AIService.monthlyHoroscopeSystemPrompt(
        language: 'en',
        kundliContext: ctx,
      );
      expect(system, contains(ctx));
      final user = AIService.monthlyHoroscopeUserPrompt(
        sign: 'Scorpio',
        date: DateTime(2026, 6, 1),
      );
      expect(user, contains('Scorpio'));
      expect(user, contains('6'));
      expect(user, contains('2026'));
    });

    test('chatResponsePrompt embeds the kundli context instead of the old placeholder', () {
      final messages = AIService.chatResponseMessages(
        query: 'What does my chart say about career?',
        userContext: 'Lagna: Cancer, Moon: Scorpio, Doshas: Mangal Dosh',
        language: 'en',
        history: const [
          {'role': 'user', 'content': 'Hi'},
          {'role': 'assistant', 'content': 'Namaste'},
        ],
      );
      expect(messages.first['role'], 'system');
      expect(messages.first['content'] as String, contains('Cancer'));
      expect(messages.first['content'] as String, contains('Scorpio'));
      expect(messages.first['content'] as String,
          isNot(contains('General Query.')),
          reason: 'the old "General Query." placeholder must be gone');
      expect(messages.last['role'], 'user');
      expect(messages.last['content'], 'What does my chart say about career?');
    });

    test('chatResponsePrompt trims history to the last 10 entries', () {
      final history = <Map<String, String>>[];
      for (int i = 0; i < 15; i++) {
        history.add({'role': 'user', 'content': 'msg $i'});
      }
      final messages = AIService.chatResponseMessages(
        query: 'final',
        userContext: 'ctx',
        language: 'en',
        history: history,
      );
      // system + last 10 history + new user query = 12
      expect(messages.length, 12);
      // Should not contain the first 5 history entries.
      final allContent = messages.map((m) => m['content'] as String).join('\n');
      expect(allContent, isNot(contains('msg 0')));
      expect(allContent, isNot(contains('msg 4')));
      expect(allContent, contains('msg 5'));
    });

    test('remedyPrompt embeds the kundli context', () {
      final system = AIService.remedySystemPrompt(
        language: 'en',
        kundliContext: 'Lagna: Cancer, Doshas: Mangal Dosh',
      );
      final user = AIService.remedyUserPrompt(kundliContext: 'Lagna: Cancer');
      expect(system, contains('Lagna: Cancer'));
      expect(user, contains('Lagna: Cancer'));
    });

    test('quotePrompt embeds the kundli context when provided', () {
      final system = AIService.quoteSystemPrompt(
        language: 'en',
        kundliContext: 'Moon: Scorpio',
      );
      final user = AIService.quoteUserPrompt(
        sign: 'Aries',
        kundliContext: 'Moon: Scorpio',
      );
      expect(system, contains('spiritual guide'));
      expect(user, contains('Aries'));
    });

    test('prompts do not contain the legacy "General Query." placeholder', () {
      // Sanity check across all builders.
      final all = [
        AIService.dailyHoroscopeSystemPrompt(language: 'en', kundliContext: 'x'),
        AIService.weeklyHoroscopeSystemPrompt(language: 'en', kundliContext: 'x'),
        AIService.monthlyHoroscopeSystemPrompt(language: 'en', kundliContext: 'x'),
        AIService.remedySystemPrompt(language: 'en', kundliContext: 'x'),
        AIService.quoteSystemPrompt(language: 'en', kundliContext: 'x'),
        AIService.chatResponseMessages(
          query: 'q', userContext: 'x', language: 'en', history: const [],
        ).map((m) => m['content'] as String).join('\n'),
      ].join('\n');
      expect(all, isNot(contains('General Query.')));
    });
  });
}
