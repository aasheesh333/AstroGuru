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
