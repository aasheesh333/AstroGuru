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
        gender: '',
        profession: '',
        maritalStatus: '',
        recent: const RecentMentions(),
      );
      expect(ctx, contains('Name: Asheesh'));
      expect(ctx, contains('Email: a@b.com'));
      expect(ctx, contains('Zodiac: Aries'));
      expect(ctx, contains('Lagna: Leo'));
    });

    test('omits empty fields gracefully', () {
      final ctx = UserContextBuilder.build(
        name: '',
        email: '',
        zodiac: 'Aries',
        kundliContext: '',
        gender: '',
        profession: '',
        maritalStatus: '',
        recent: const RecentMentions(),
      );
      expect(ctx.contains('Name:'), isFalse);
      expect(ctx.contains('Email:'), isFalse);
      expect(ctx.contains('Gender:'), isFalse);
      expect(ctx.contains('Profession:'), isFalse);
      expect(ctx.contains('Marital Status:'), isFalse);
    });

    test('appends recent mentions block when present', () {
      final ctx = UserContextBuilder.build(
        name: 'X',
        email: '',
        zodiac: 'Aries',
        kundliContext: '',
        gender: '',
        profession: '',
        maritalStatus: '',
        recent: const RecentMentions(
          place: 'Pune', date: '5 Jan 2026', time: '4 pm'),
      );
      expect(ctx, contains('Recent mentions'));
      expect(ctx, contains('Pune'));
      expect(ctx, contains('5 Jan 2026'));
      expect(ctx, contains('4 pm'));
    });

    test('includes gender, profession, marital status when set', () {
      final ctx = UserContextBuilder.build(
        name: 'Asheesh',
        email: '',
        zodiac: 'Aries',
        kundliContext: '',
        gender: 'male',
        profession: 'Software Engineer',
        maritalStatus: 'in_relationship',
        recent: const RecentMentions(),
      );
      expect(ctx, contains('Gender: Male'));
      expect(ctx, contains('Profession: Software Engineer'));
      expect(ctx, contains('Marital Status: In a relationship'));
    });
  });
}
