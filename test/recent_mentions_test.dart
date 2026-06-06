import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/logic/recent_mentions.dart';

void main() {
  group('RecentMentions.extract', () {
    test('returns empty when no user messages', () {
      final out = RecentMentions.extract(const []);
      expect(out.place, isNull);
      expect(out.date, isNull);
      expect(out.time, isNull);
    });

    test('picks the most recent place mention', () {
      final history = [
        {'role': 'user', 'content': 'I live in Delhi'},
        {'role': 'assistant', 'content': 'okay'},
        {'role': 'user', 'content': 'I moved to Mumbai last month'},
      ];
      final out = RecentMentions.extract(history);
      expect(out.place, equals('Mumbai'));
    });

    test('picks the most recent date mention', () {
      final history = [
        {'role': 'user', 'content': 'On 5th Jan 2025 I started a new job'},
        {'role': 'user', 'content': 'By 12 March 2026 things changed'},
      ];
      final out = RecentMentions.extract(history);
      expect(out.date, equals('12 March 2026'));
    });

    test('picks the most recent time mention', () {
      final history = [
        {'role': 'user', 'content': 'I woke up at 6:30 AM'},
        {'role': 'user', 'content': 'the meeting is at 4 pm'},
      ];
      final out = RecentMentions.extract(history);
      expect(out.time, anyOf(equals('4 pm'), equals('4:00 pm')));
    });

    test('ignores assistant messages', () {
      final history = [
        {'role': 'user', 'content': 'I live in Pune'},
        {'role': 'assistant', 'content': 'I will remember you are in Pune'},
      ];
      final out = RecentMentions.extract(history);
      expect(out.place, equals('Pune'));
    });

    test('picks up place mentioned many messages back', () {
      final history = List.generate(20, (i) => {'role': 'user', 'content': 'msg $i'})
        ..add({'role': 'user', 'content': 'I live in Chennai'});
      final out = RecentMentions.extract(history);
      expect(out.place, equals('Chennai'));
    });
  });
}
