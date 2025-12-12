import 'dart:math';

class LoveMatchLogic {
  static const Map<String, int> _numerologyMap = {
    'a': 1, 'j': 1, 's': 1,
    'b': 2, 'k': 2, 't': 2,
    'c': 3, 'l': 3, 'u': 3,
    'd': 4, 'm': 4, 'v': 4,
    'e': 5, 'n': 5, 'w': 5,
    'f': 6, 'o': 6, 'x': 6,
    'g': 7, 'p': 7, 'y': 7,
    'h': 8, 'q': 8, 'z': 8,
    'r': 9
  };

  static const Map<String, String> _signElements = {
    'Aries': 'Fire', 'Leo': 'Fire', 'Sagittarius': 'Fire',
    'Taurus': 'Earth', 'Virgo': 'Earth', 'Capricorn': 'Earth',
    'Gemini': 'Air', 'Libra': 'Air', 'Aquarius': 'Air',
    'Cancer': 'Water', 'Scorpio': 'Water', 'Pisces': 'Water'
  };

  static int calculate(String name1, String sign1, String name2, String sign2) {
    // 1. Numerology (40%)
    int num1 = _calculateNumerology(name1);
    int num2 = _calculateNumerology(name2);
    int diff = (num1 - num2).abs();

    double numScore;
    if (diff == 0) numScore = _randomRange(85, 95);
    else if (diff == 1) numScore = _randomRange(75, 90);
    else if (diff == 2) numScore = _randomRange(65, 80);
    else if (diff == 3) numScore = _randomRange(55, 70);
    else numScore = _randomRange(45, 60);

    // 2. Rashi Element (30%)
    String el1 = _signElements[sign1] ?? 'Fire';
    String el2 = _signElements[sign2] ?? 'Fire';
    double rashiScore = _getElementCompatibility(el1, el2);

    // 3. Nakshatra (20%) - Default 60 as data is missing
    double nakshatraScore = 60.0;

    // 4. Dosha (10%) - Random +3 to +7 as data is missing (assuming no major dosha known)
    double doshaAdj = _randomRange(3, 7);

    // Final Calculation
    double total = (numScore * 0.40) + (rashiScore * 0.30) + (nakshatraScore * 0.20) + doshaAdj;

    // Adjustments
    if (total < 40) total = _randomRange(40, 55);
    if (total > 95) total = _randomRange(92, 95);

    return total.round();
  }

  static int _calculateNumerology(String name) {
    int sum = 0;
    String cleaned = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    for (int i = 0; i < cleaned.length; i++) {
      sum += _numerologyMap[cleaned[i]] ?? 0;
    }

    while (sum > 9) {
      int temp = 0;
      while (sum > 0) {
        temp += sum % 10;
        sum ~/= 10;
      }
      sum = temp;
    }
    return sum == 0 ? 1 : sum; // Default to 1 if empty/invalid
  }

  static double _getElementCompatibility(String el1, String el2) {
    if (el1 == el2) return _randomRange(75, 90); // Same element

    // Compatible Groups
    // Fire + Air
    if ((el1 == 'Fire' && el2 == 'Air') || (el1 == 'Air' && el2 == 'Fire')) return _randomRange(75, 90);
    // Earth + Water
    if ((el1 == 'Earth' && el2 == 'Water') || (el1 == 'Water' && el2 == 'Earth')) return _randomRange(75, 90);

    // Opposites
    if ((el1 == 'Fire' && el2 == 'Water') || (el1 == 'Water' && el2 == 'Fire')) return _randomRange(40, 55);
    if ((el1 == 'Air' && el2 == 'Earth') || (el1 == 'Earth' && el2 == 'Air')) return _randomRange(40, 55); // Often considered incompatible

    // Neutral
    return _randomRange(55, 70);
  }

  static double _randomRange(double min, double max) {
    return min + Random().nextInt((max - min).toInt() + 1);
  }
}
