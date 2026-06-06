import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/logic/user_context_builder.dart';
import 'package:astroguru/logic/recent_mentions.dart';

void main() {
  group('UserContextBuilder.build', () {
    test('includes name, email, zodiac and kundli', () {
      final ctx = UserContextBuilder.build(
        name: 'Asheesh',
        email: 'a@b.com',
        zodiac: 'Aries',
        kundliContext: '- Lagna: Leo\n- Moon Sign: Cancer',
        recent: const RecentMentions(),
      );
      expect(ctx, contains('Name: Asheesh'));
      expect(ctx, contains('Email: a@b.com'));
      expect(ctx, contains('Zodiac: Aries'));
      expect(ctx, contains('Lagna: Leo'));
      expect(ctx.contains('Mumbai'), isFalse);
      expect(ctx.contains('Pune'), isFalse);
    });

    test('omits empty fields gracefully', () {
      final ctx = UserContextBuilder.build(
        name: '',
        email: '',
        zodiac: 'Aries',
        kundliContext: '',
        recent: const RecentMentions(),
      );
      expect(ctx.contains('Name:'), isFalse);
      expect(ctx.contains('Email:'), isFalse);
    });

    test('appends recent mentions block when present', () {
      final ctx = UserContextBuilder.build(
        name: 'X',
        email: '',
        zodiac: 'Aries',
        kundliContext: '',
        recent: const RecentMentions(
            place: 'Pune', date: '5 Jan 2026', time: '4 pm'),
      );
      expect(ctx, contains('Recent mentions'));
      expect(ctx, contains('Pune'));
      expect(ctx, contains('5 Jan 2026'));
      expect(ctx, contains('4 pm'));
    });
  });
}
