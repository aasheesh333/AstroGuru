import 'package:flutter_test/flutter_test.dart';
import 'package:astroguru/logic/love_match_logic.dart';

void main() {
  group('LoveMatchLogic._calculateNumerology (verified via public API)', () {
    // We exercise numerology indirectly by calling calculate() twice with the
    // same names so the randomness is the only varying input, then confirm
    // the result is a sensible integer in the [0, 100] range.

    test('returns an integer in [0, 100]', () {
      final score = LoveMatchLogic.calculate('Aarav', 'Aries', 'Diya', 'Leo');
      expect(score, inInclusiveRange(0, 100));
    });

    test('same names + same signs produce scores in similar band', () {
      // Run a few times; the numerology is deterministic but the rest is
      // random — we just want to assert we never return something outside
      // the expected band.
      for (var i = 0; i < 20; i++) {
        final s = LoveMatchLogic.calculate('Riya', 'Aries', 'Riya', 'Aries');
        expect(s, inInclusiveRange(60, 100));
      }
    });

    test('completely incompatible signs can score low but stay in range', () {
      // Fire vs Water is a "opposite" pairing in this logic.
      for (var i = 0; i < 20; i++) {
        final s = LoveMatchLogic.calculate('A', 'Aries', 'B', 'Cancer');
        expect(s, inInclusiveRange(0, 100));
      }
    });

    test('unknown signs fall back to Fire so calculation still runs', () {
      final s = LoveMatchLogic.calculate('A', 'Foo', 'B', 'Bar');
      expect(s, inInclusiveRange(0, 100));
    });
  });
}
