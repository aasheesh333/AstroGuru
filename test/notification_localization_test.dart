import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/services/notification_service.dart';
import 'package:astroguru/logic/hindu_festivals.dart';

void main() {
  group('LocalizedNotificationStrings', () {
    test('holds all localized fields and festival builders', () {
      const strings = LocalizedNotificationStrings(
        dailyTitle: 'Daily Horoscope Ready',
        dailyBody: 'Check what the stars say',
        eveningTitle: 'Tonight Stars',
        eveningBody: 'Evening guidance',
        reengageTitle: 'Stars missed you',
        reengageBody: 'Come back',
        reengage2Title: 'Dont miss your sign',
        reengage2Body: 'Kundli waiting',
        festivalTitleFor: _festivalTitle,
        festivalBodyFor: _festivalBody,
      );

      expect(strings.dailyTitle, 'Daily Horoscope Ready');
      expect(strings.dailyBody, 'Check what the stars say');
      expect(strings.eveningTitle, 'Tonight Stars');
      expect(strings.eveningBody, 'Evening guidance');
      expect(strings.reengageTitle, 'Stars missed you');
      expect(strings.reengageBody, 'Come back');
      expect(strings.reengage2Title, 'Dont miss your sign');
      expect(strings.reengage2Body, 'Kundli waiting');
      expect(strings.festivalTitleFor('Diwali'), '🎉 Diwali blessings');
      expect(strings.festivalBodyFor('Holi'), 'Holi joy to you');
    });
  });

  group('HinduFestival.nameFor', () {
    final allFestivals = HinduFestivals.upcomingFrom(
      DateTime(2026, 1, 1),
      days: 365 * 2,
    );

    test('returns a non-English name for hi for every festival', () {
      final seen = <String>{};
      for (final entry in allFestivals) {
        if (seen.contains(entry.festival.name)) continue;
        seen.add(entry.festival.name);

        final hiName = entry.festival.nameFor('hi');
        expect(hiName, isNotEmpty,
            reason: '${entry.festival.name} has no Hindi translation');
      }
    });

    test('returns the same English name for unsupported language codes', () {
      final diwali = allFestivals
          .firstWhere((e) => e.festival.name == 'Diwali')
          .festival;
      expect(diwali.nameFor('zz'), 'Diwali');
    });
  });
}

String _festivalTitle(String festival) => '🎉 $festival blessings';
String _festivalBody(String festival) => '$festival joy to you';
