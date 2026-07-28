import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/logic/hindu_festivals.dart';

void main() {
  group('HinduFestivals', () {
    test('upcomingFrom returns festivals within window, sorted ascending', () {
      final now = DateTime(2026, 6, 1, 0, 0);
      final upcoming = HinduFestivals.upcomingFrom(now, days: 90);

      expect(upcoming, isNotEmpty);
      for (int i = 1; i < upcoming.length; i++) {
        expect(
          upcoming[i].date.isAfter(upcoming[i - 1].date),
          isTrue,
          reason: 'festivals must be sorted ascending by date',
        );
      }
      for (final entry in upcoming) {
        expect(entry.date.isAfter(now), isTrue);
        expect(entry.date.isBefore(now.add(const Duration(days: 91))), isTrue);
      }
    });

    test('upcomingFrom excludes past festivals', () {
      final now = DateTime(2026, 6, 15, 0, 0);
      final upcoming = HinduFestivals.upcomingFrom(now, days: 1);
      for (final entry in upcoming) {
        expect(entry.date.isAfter(now), isTrue);
      }
    });

    test('upcomingFrom spans into next year when window crosses Dec 31', () {
      final now = DateTime(2026, 12, 20, 0, 0);
      final upcoming = HinduFestivals.upcomingFrom(now, days: 30);
      final has2027 = upcoming.any((e) => e.date.year == 2027);
      expect(has2027, isTrue);
    });

    test('every festival has a non-empty title and body', () {
      for (final entry in HinduFestivals.upcomingFrom(
        DateTime(2026, 1, 1),
        days: 365 * 2,
      )) {
        expect(entry.festival.name, isNotEmpty);
        expect(entry.festival.title, isNotEmpty);
        expect(entry.festival.body, isNotEmpty);
        expect(entry.festival.hour, inInclusiveRange(0, 23));
        expect(entry.festival.month, inInclusiveRange(1, 12));
        expect(entry.festival.day, inInclusiveRange(1, 31));
      }
    });

    test('nameFor returns translated name for supported languages', () {
      // Pick Diwali which should have translations for all major languages.
      final allFestivals = HinduFestivals.upcomingFrom(
        DateTime(2026, 1, 1),
        days: 365 * 2,
      );
      final diwali = allFestivals.firstWhere(
        (e) => e.festival.name == 'Diwali',
      ).festival;
      expect(diwali.nameFor('en'), 'Diwali');
      expect(diwali.nameFor('hi'), isNot('Diwali'));
      expect(diwali.nameFor('hi'), isNotEmpty);
      expect(diwali.nameFor('ta'), isNotEmpty);
      expect(diwali.nameFor('bn'), isNotEmpty);
      expect(diwali.nameFor('ur'), isNotEmpty);
    });

    test('nameFor falls back to English for unknown language', () {
      final allFestivals = HinduFestivals.upcomingFrom(
        DateTime(2026, 1, 1),
        days: 365 * 2,
      );
      final diwali = allFestivals.firstWhere(
        (e) => e.festival.name == 'Diwali',
      ).festival;
      expect(diwali.nameFor('fr'), 'Diwali');
      expect(diwali.nameFor(''), 'Diwali');
    });

    test('every festival entry has a localizedName map', () {
      final allFestivals = HinduFestivals.upcomingFrom(
        DateTime(2026, 1, 1),
        days: 365 * 2,
      );
      final seenNames = <String>{};
      for (final entry in allFestivals) {
        // Only check each unique festival name once (skip 2027 variants
        // that share the same base entry).
        if (seenNames.contains(entry.festival.name)) continue;
        seenNames.add(entry.festival.name);
        expect(entry.festival.localizedName, isNotEmpty,
            reason: '${entry.festival.name} is missing localizedName translations');
      }
    });

    test('2026 and 2027 each contain Diwali, Holi, and Janmashtami', () {
      final twoYear = HinduFestivals.upcomingFrom(
        DateTime(2026, 1, 1),
        days: 365 * 2,
      );
      for (final year in [2026, 2027]) {
        final names = twoYear
            .where((e) => e.date.year == year)
            .map((e) => e.festival.name)
            .toList();
        expect(
          names.any((n) => n.toLowerCase().contains('diwali')),
          isTrue,
          reason: 'Diwali missing for $year',
        );
        expect(
          names.any((n) => n.toLowerCase().contains('holi')),
          isTrue,
          reason: 'Holi missing for $year',
        );
        expect(
          names.any((n) => n.toLowerCase().contains('janmashtami')),
          isTrue,
          reason: 'Janmashtami missing for $year',
        );
      }
    });
  });
}
