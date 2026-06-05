import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/logic/static_cities.dart';

void main() {
  group('StaticCities.lookup', () {
    test('returns default (New Delhi) for empty input', () {
      final result = StaticCities.lookup('');
      expect(result.$1, closeTo(28.6139, 0.0001));
      expect(result.$2, closeTo(77.2090, 0.0001));
    });

    test('returns default (New Delhi) for unknown place', () {
      final result = StaticCities.lookup('Atlantis Middle Earth');
      expect(result.$1, closeTo(28.6139, 0.0001));
      expect(result.$2, closeTo(77.2090, 0.0001));
    });

    test('exact match: Mumbai', () {
      final result = StaticCities.lookup('Mumbai');
      expect(result.$1, closeTo(19.0760, 0.5));
      expect(result.$2, closeTo(72.8777, 0.5));
    });

    test('case-insensitive match: MUMBAI', () {
      final result = StaticCities.lookup('MUMBAI');
      expect(result.$1, closeTo(19.0760, 0.5));
    });

    test('whitespace tolerant: "  Mumbai  "', () {
      final result = StaticCities.lookup('  Mumbai  ');
      expect(result.$1, closeTo(19.0760, 0.5));
    });

    test('all-tokens match: "New Delhi"', () {
      final result = StaticCities.lookup('New Delhi');
      expect(result.$1, closeTo(28.6139, 0.0001));
      expect(result.$2, closeTo(77.2090, 0.0001));
    });

    test('Hindi script match: दिल्ली', () {
      final result = StaticCities.lookup('दिल्ली');
      expect(result.$1, closeTo(28.6139, 0.0001));
      expect(result.$2, closeTo(77.2090, 0.0001));
    });
  });

  group('StaticCities.lookupName', () {
    test('returns canonical English name for an exact match', () {
      expect(StaticCities.lookupName('Mumbai'), 'Mumbai');
    });

    test('returns null for unknown place', () {
      expect(StaticCities.lookupName('Atlantis'), isNull);
    });

    test('returns canonical name for case-insensitive input', () {
      expect(StaticCities.lookupName('mumbai'), 'Mumbai');
    });

    test('returns null for empty input', () {
      expect(StaticCities.lookupName(''), isNull);
      expect(StaticCities.lookupName('   '), isNull);
    });
  });
}
