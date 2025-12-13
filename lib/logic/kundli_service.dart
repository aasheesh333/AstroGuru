import 'package:sweph/sweph.dart';

class KundliService {

  static Future<void> initialize() async {
    // Moshier mode is default if no files provided.
    // sweph requires initialization.
    await Sweph.init(epheAssets: []);
  }

  static Map<String, dynamic> calculateChart(DateTime dateTime, double lat, double lon) {
    // Julian Day
    final double jd = Sweph.swe_julday(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour + dateTime.minute / 60.0,
      CalendarType.SE_GREG_CAL,
    );

    // Calculate Planets
    final List<HeavenlyBody> planetIds = [
      HeavenlyBody.SE_SUN,
      HeavenlyBody.SE_MOON,
      HeavenlyBody.SE_MARS,
      HeavenlyBody.SE_MERCURY,
      HeavenlyBody.SE_JUPITER,
      HeavenlyBody.SE_VENUS,
      HeavenlyBody.SE_SATURN,
      HeavenlyBody.SE_TRUE_NODE, // Rahu
    ];

    List<Map<String, dynamic>> planets = [];

    for (HeavenlyBody pid in planetIds) {
      // swe_calc_ut returns CoordinatesWithSpeed in this version
      final CoordinatesWithSpeed coords = Sweph.swe_calc_ut(jd, pid, SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL);
      String name = _getPlanetName(pid);

      double longitude = coords.longitude;
      double speed = coords.speedInLongitude;
      bool isRetro = speed < 0;

      planets.add({
        'name': name,
        'longitude': longitude,
        'speed': speed,
        'isRetrograde': isRetro,
        'rashi': (longitude / 30).floor() + 1,
        'degree': longitude % 30,
      });
    }

    // Ketu is opposite Rahu
    final rahu = planets.firstWhere((p) => p['name'] == 'Rahu');
    double ketuLong = (rahu['longitude'] + 180) % 360;
    planets.add({
      'name': 'Ketu',
      'longitude': ketuLong,
      'speed': rahu['speed'],
      'isRetrograde': rahu['isRetrograde'],
      'rashi': (ketuLong / 30).floor() + 1,
      'degree': ketuLong % 30,
    });

    // Lagna (Ascendant)
    // Hsys.P corresponds to Placidus
    final HouseCuspData houses = Sweph.swe_houses(jd, lat, lon, Hsys.P);
    double lagnaLong = houses.ascmc[0];

    Map<String, dynamic> lagna = {
      'longitude': lagnaLong,
      'rashi': (lagnaLong / 30).floor() + 1,
      'degree': lagnaLong % 30,
    };

    // Calculate Nakshatra
    final moon = planets.firstWhere((p) => p['name'] == 'Moon');
    double moonLong = moon['longitude'];
    int nakshatra = (moonLong * 27 / 360).floor() + 1;
    int pada = ((moonLong * 27 / 360 - (nakshatra - 1)) * 4).floor() + 1;

    // Check Doshas
    Map<String, dynamic> chart = {
      'lagna': lagna,
      'planets': planets,
      'jd': jd,
      'nakshatra': nakshatra,
      'pada': pada,
    };

    chart['doshas'] = checkDoshas(chart);
    chart['summary'] = _generateSummary(chart);

    return chart;
  }

  static String getSunSign(DateTime date) {
    int day = date.day;
    int month = date.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Aries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Taurus";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gemini";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Cancer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leo";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgo";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricorn";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquarius";
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return "Pisces";
    return "Aries";
  }

  static String _generateSummary(Map<String, dynamic> chart) {
    StringBuffer sb = StringBuffer();
    sb.write("Lagna: ${chart['lagna']['rashi']}, ");
    sb.write("Moon: ${(chart['planets'] as List).firstWhere((p) => p['name'] == 'Moon')['rashi']}, ");
    sb.write("Sun: ${(chart['planets'] as List).firstWhere((p) => p['name'] == 'Sun')['rashi']}, ");
    sb.write("Doshas: ${(chart['doshas'] as List).join(', ')}");
    return sb.toString();
  }

  static String _getPlanetName(HeavenlyBody id) {
    switch (id) {
      case HeavenlyBody.SE_SUN: return 'Sun';
      case HeavenlyBody.SE_MOON: return 'Moon';
      case HeavenlyBody.SE_MARS: return 'Mars';
      case HeavenlyBody.SE_MERCURY: return 'Mercury';
      case HeavenlyBody.SE_JUPITER: return 'Jupiter';
      case HeavenlyBody.SE_VENUS: return 'Venus';
      case HeavenlyBody.SE_SATURN: return 'Saturn';
      case HeavenlyBody.SE_TRUE_NODE: return 'Rahu';
      default: return 'Unknown';
    }
  }

  static List<String> checkDoshas(Map<String, dynamic> chart) {
    List<String> doshas = [];
    int lagnaRashi = chart['lagna']['rashi'];
    var planets = chart['planets'] as List;

    // Helper to get house number (1-12) for a planet relative to Lagna
    int getHouse(double planetLong) {
      int planetRashi = (planetLong / 30).floor() + 1;
      int house = (planetRashi - lagnaRashi + 1 + 12) % 12;
      return house == 0 ? 12 : house;
    }

    // Mangal Dosh (Mars in 1, 2, 4, 7, 8, 12)
    var mars = planets.firstWhere((p) => p['name'] == 'Mars');
    int marsHouse = getHouse(mars['longitude']);
    if ([1, 2, 4, 7, 8, 12].contains(marsHouse)) {
      doshas.add("Mangal Dosh");
    }

    // Kaal Sarp Dosh (All planets between Rahu and Ketu)
    // Simplified logic: Check if all major planets are on one side of Rahu/Ketu axis
    var rahu = planets.firstWhere((p) => p['name'] == 'Rahu');
    var ketu = planets.firstWhere((p) => p['name'] == 'Ketu');

    // Normalize angles to 0-360 relative to Rahu
    double normalize(double angle) => (angle + 360) % 360;
    double rahuLong = rahu['longitude'];
    double ketuLong = ketu['longitude'];

    // Check if all planets are in the arc from Rahu to Ketu (approx 180 deg)
    // or Ketu to Rahu.
    bool allBetweenRahuKetu = true;
    bool allBetweenKetuRahu = true;

    for (var p in planets) {
      if (p['name'] == 'Rahu' || p['name'] == 'Ketu') continue;
      double pl = p['longitude'];

      // Check arc Rahu -> Ketu (counter-clockwise)
      // If Rahu=30, Ketu=210. Planet=100 (inside). Planet=300 (outside).
      // Logic: (p - rahu) % 360 < (ketu - rahu) % 360
      if (normalize(pl - rahuLong) > normalize(ketuLong - rahuLong)) {
        allBetweenRahuKetu = false;
      }

      // Check arc Ketu -> Rahu
      if (normalize(pl - ketuLong) > normalize(rahuLong - ketuLong)) {
        allBetweenKetuRahu = false;
      }
    }

    if (allBetweenRahuKetu || allBetweenKetuRahu) {
      doshas.add("Kaal Sarp Dosh");
    }

    // Guru Chandal Dosh (Jupiter + Rahu conjunct)
    var jupiter = planets.firstWhere((p) => p['name'] == 'Jupiter');
    if ((jupiter['longitude'] - rahu['longitude']).abs() < 10 ||
        (360 - (jupiter['longitude'] - rahu['longitude']).abs()) < 10) {
      doshas.add("Guru Chandal Dosh");
    }

    // Grahan Dosh (Sun/Moon + Rahu/Ketu)
    var sun = planets.firstWhere((p) => p['name'] == 'Sun');
    var moon = planets.firstWhere((p) => p['name'] == 'Moon');

    bool sunConjRahu = (sun['longitude'] - rahu['longitude']).abs() < 10;
    bool sunConjKetu = (sun['longitude'] - ketu['longitude']).abs() < 10;
    if (sunConjRahu || sunConjKetu) doshas.add("Surya Grahan Dosh");

    bool moonConjRahu = (moon['longitude'] - rahu['longitude']).abs() < 10;
    bool moonConjKetu = (moon['longitude'] - ketu['longitude']).abs() < 10;
    if (moonConjRahu || moonConjKetu) doshas.add("Chandra Grahan Dosh");

    // Pitra Dosh (Sun conjunct Rahu/Ketu OR Sun in 9th house with malefic)
    // Simplified: Sun + Rahu/Ketu (same as Grahan) usually contributes,
    // but classically Pitra Dosh is distinct.
    // Let's use: Sun in 9th house afflicted or Sun+Rahu.
    // For MVP/simplified: If Surya Grahan Dosh exists, add Pitra Dosh as they are related.
    // Or stricter: Sun + Saturn or Sun in 9th.
    int sunHouse = getHouse(sun['longitude']);
    if (sunHouse == 9 || sunConjRahu || sunConjKetu) {
       doshas.add("Pitra Dosh");
    }

    // Kemdrum Dosh (No planets in 2nd and 12th from Moon)
    // Sun, Rahu, Ketu are excluded from cancellation.
    int moonHouse = getHouse(moon['longitude']); // Relative to Lagna
    // We need relative to Moon. 2nd from Moon, 12th from Moon.
    // 2nd from Moon: (MoonRashi + 1)
    // 12th from Moon: (MoonRashi - 1)
    int moonRashi = moon['rashi'];

    bool planetIn2nd = false;
    bool planetIn12th = false;

    for (var p in planets) {
      if (['Sun', 'Rahu', 'Ketu', 'Moon'].contains(p['name'])) continue;

      int pRashi = p['rashi'];
      // 2nd from Moon: (MoonRashi + 1 - 1)%12 + 1 => just (MoonRashi % 12) + 1
      int secondFromMoon = (moonRashi % 12) + 1;
      // 12th from Moon: (MoonRashi - 2 + 12)%12 + 1 => (MoonRashi + 10) % 12 + 1
      int twelfthFromMoon = ((moonRashi + 10) % 12) + 1;

      if (pRashi == secondFromMoon) planetIn2nd = true;
      if (pRashi == twelfthFromMoon) planetIn12th = true;
    }

    // Kemdrum exists if NO planet in 2nd AND NO planet in 12th
    // (Simplest definition, ignoring aspects/kendra)
    if (!planetIn2nd && !planetIn12th) {
      doshas.add("Kemdrum Dosh");
    }

    return doshas;
  }
}
