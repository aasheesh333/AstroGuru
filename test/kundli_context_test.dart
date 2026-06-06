import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/logic/kundli_context.dart';

void main() {
  group('KundliContextBuilder', () {
    test('returns empty string for null chart', () {
      final out = KundliContextBuilder.build(chart: null);
      expect(out, '');
    });

    test('returns empty string when chart has no lagna or planets', () {
      final out = KundliContextBuilder.build(chart: {'empty': true});
      expect(out, '');
    });

    test('produces a narrative that names Lagna and Moon sign, not raw ids', () {
      final chart = {
        'lagna': {'rashi': 4}, // Cancer
        'planets': [
          {'name': 'Sun', 'rashi': 5, 'longitude': 152.0},
          {'name': 'Moon', 'rashi': 8, 'longitude': 240.0}, // Scorpio
          {'name': 'Mars', 'rashi': 7, 'longitude': 210.0},
          {'name': 'Mercury', 'rashi': 5, 'longitude': 160.0},
          {'name': 'Jupiter', 'rashi': 9, 'longitude': 270.0},
          {'name': 'Venus', 'rashi': 6, 'longitude': 180.0},
          {'name': 'Saturn', 'rashi': 11, 'longitude': 330.0},
          {'name': 'Rahu', 'rashi': 10, 'longitude': 300.0},
          {'name': 'Ketu', 'rashi': 4, 'longitude': 120.0},
        ],
        'nakshatra': 17,
        'pada': 3,
        'doshas': ['Mangal Dosh'],
      };
      final out = KundliContextBuilder.build(chart: chart);

      expect(out, contains('Cancer'),
          reason: 'must include Lagna sign name, not raw rashi id');
      expect(out, contains('Scorpio'),
          reason: 'must include Moon sign name, not raw rashi id');
      expect(out, contains('Leo'),
          reason: 'Sun sign name should appear');
      expect(out, isNot(contains('Lagna: 4')),
          reason: 'must not include raw rashi numeric ids');
      expect(out, isNot(contains('Moon: 8')));
      expect(out, contains('Mangal Dosh'),
          reason: 'doshas should be listed when present');
    });

    test('omits the doshas line when doshas list is empty', () {
      final chart = {
        'lagna': {'rashi': 1},
        'planets': [
          {'name': 'Sun', 'rashi': 1, 'longitude': 10.0},
          {'name': 'Moon', 'rashi': 1, 'longitude': 20.0},
        ],
        'doshas': <String>[],
      };
      final out = KundliContextBuilder.build(chart: chart);
      expect(out, contains('Aries'));
      expect(out, isNot(contains('Doshas:')));
    });

    test('handles missing nakshatra and pada gracefully', () {
      final chart = {
        'lagna': {'rashi': 1},
        'planets': [
          {'name': 'Sun', 'rashi': 1, 'longitude': 10.0},
          {'name': 'Moon', 'rashi': 1, 'longitude': 20.0},
        ],
        'doshas': <String>[],
      };
      final out = KundliContextBuilder.build(chart: chart);
      expect(out, isNotNull);
      expect(out, contains('Aries'));
    });

    test('omits the nakshatra line when nakshatra value is missing or zero', () {
      final chart = {
        'lagna': {'rashi': 1},
        'planets': [
          {'name': 'Sun', 'rashi': 1, 'longitude': 10.0},
          {'name': 'Moon', 'rashi': 1, 'longitude': 20.0},
        ],
        'nakshatra': 0,
        'pada': 0,
        'doshas': <String>[],
      };
      final out = KundliContextBuilder.build(chart: chart);
      expect(out, isNot(contains('Nakshatra:')));
    });

    test('accepts a birth date/time/place prefix and formats it', () {
      final chart = {
        'lagna': {'rashi': 1},
        'planets': [
          {'name': 'Sun', 'rashi': 1, 'longitude': 10.0},
          {'name': 'Moon', 'rashi': 1, 'longitude': 20.0},
        ],
        'doshas': <String>[],
      };
      final out = KundliContextBuilder.build(
        chart: chart,
        birthDate: DateTime(1995, 8, 12),
        birthTime: '14:30',
        birthPlace: 'New Delhi',
      );
      expect(out, contains('1995-08-12'));
      expect(out, contains('14:30'));
      expect(out, contains('New Delhi'));
    });

    test('omits the birth-time line when birthTime is empty', () {
      final chart = {
        'lagna': {'rashi': 1},
        'planets': [
          {'name': 'Sun', 'rashi': 1, 'longitude': 10.0},
          {'name': 'Moon', 'rashi': 1, 'longitude': 20.0},
        ],
        'doshas': <String>[],
      };
      final out = KundliContextBuilder.build(
        chart: chart,
        birthDate: DateTime(1995, 8, 12),
        birthTime: '',
        birthPlace: 'New Delhi',
      );
      expect(out, contains('1995-08-12'));
      expect(out, isNot(contains('Time:')));
    });
  });
}
