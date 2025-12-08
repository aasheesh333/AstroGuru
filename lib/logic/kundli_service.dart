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

    // Set Ayanamsa to Lahiri (Vedic standard)
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI, SiderealModeFlag.SE_SIDBIT_NONE, 0);

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
      final CoordinatesWithSpeed coords = Sweph.swe_calc_ut(jd, pid, SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL);
      String name = _getPlanetName(pid);

      double longitude = coords.longitude;
      double speed = coords.speedInLongitude;
      bool isRetro = speed < 0;

      // Nakshatra calculation (0-360 mapped to 27 stars)
      // 360 / 27 = 13.333 degrees per Nakshatra
      int nakshatraIndex = (longitude / 13.333333).floor();
      int pada = ((longitude % 13.333333) / 3.333333).floor() + 1;

      planets.add({
        'name': name,
        'longitude': longitude,
        'speed': speed,
        'isRetrograde': isRetro,
        'rashi': (longitude / 30).floor() + 1,
        'degree': longitude % 30,
        'nakshatra': _getNakshatraName(nakshatraIndex + 1), // 1-based index
        'nakshatra_pada': pada,
      });
    }

    // Ketu is opposite Rahu
    final rahu = planets.firstWhere((p) => p['name'] == 'Rahu');
    double ketuLong = (rahu['longitude'] + 180) % 360;
    int ketuNakshatraIndex = (ketuLong / 13.333333).floor();
    int ketuPada = ((ketuLong % 13.333333) / 3.333333).floor() + 1;

    planets.add({
      'name': 'Ketu',
      'longitude': ketuLong,
      'speed': rahu['speed'],
      'isRetrograde': rahu['isRetrograde'],
      'rashi': (ketuLong / 30).floor() + 1,
      'degree': ketuLong % 30,
      'nakshatra': _getNakshatraName(ketuNakshatraIndex + 1),
      'nakshatra_pada': ketuPada,
    });

    // Lagna (Ascendant)
    // Hsys.P corresponds to Placidus
    final HouseCuspData houses = Sweph.swe_houses(jd, lat, lon, Hsys.P);
    double lagnaLong = houses.ascmc[0];
    int lagnaNakshatraIndex = (lagnaLong / 13.333333).floor();
    int lagnaPada = ((lagnaLong % 13.333333) / 3.333333).floor() + 1;

    Map<String, dynamic> lagna = {
      'longitude': lagnaLong,
      'rashi': (lagnaLong / 30).floor() + 1,
      'degree': lagnaLong % 30,
      'nakshatra': _getNakshatraName(lagnaNakshatraIndex + 1),
      'nakshatra_pada': lagnaPada,
    };

    // Calculate Dasha (Vimsottari)
    var moon = planets.firstWhere((p) => p['name'] == 'Moon');
    Map<String, dynamic> dasha = _calculateVimsottariDasha(moon['longitude'], dateTime);

    // Simplified Shadbala (Strength)
    for (var planet in planets) {
      planet['strength'] = _calculateSimplifiedStrength(planet);
    }

    return {
      'lagna': lagna,
      'planets': planets,
      'jd': jd,
      'dasha': dasha,
      'doshas': checkDoshas({'lagna': lagna, 'planets': planets}),
    };
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
    var planets = chart['planets'] as List<Map<String, dynamic>>;

    // 1. Mangal Dosh
    var mars = planets.firstWhere((p) => p['name'] == 'Mars');
    int marsRashi = mars['rashi'];
    int marsHouse = (marsRashi - lagnaRashi + 1 + 12) % 12;
    if (marsHouse == 0) marsHouse = 12;

    if ([1, 2, 4, 7, 8, 12].contains(marsHouse)) {
      doshas.add("Mangal Dosh");
    }

    // 2. Kaalsarp Yoga (All planets between Rahu and Ketu)
    var rahu = planets.firstWhere((p) => p['name'] == 'Rahu');
    var ketu = planets.firstWhere((p) => p['name'] == 'Ketu');

    double rL = rahu['longitude'];
    double kL = ketu['longitude'];

    // Normalize to 0-360
    bool isBetween(double val, double start, double end) {
      if (start < end) {
        return val > start && val < end;
      } else {
        return val > start || val < end;
      }
    }

    bool allOneSide = true;
    bool allOtherSide = true;

    for (var p in planets) {
      if (p['name'] == 'Rahu' || p['name'] == 'Ketu') continue;
      double L = p['longitude'];

      // Arc 1: Rahu to Ketu (Direct)
      if (!isBetween(L, rL, kL)) allOneSide = false;

      // Arc 2: Ketu to Rahu (Direct)
      if (!isBetween(L, kL, rL)) allOtherSide = false;
    }

    if (allOneSide || allOtherSide) {
      doshas.add("Kaalsarp Yoga");
    }

    // 3. Pitra Dosh (Sun/Moon with Rahu/Ketu or Saturn/Sun)
    var sun = planets.firstWhere((p) => p['name'] == 'Sun');
    int sunRashi = sun['rashi'];
    int rahuRashi = rahu['rashi'];
    if (sunRashi == rahuRashi || sunRashi == ketu['rashi']) {
      doshas.add("Pitra Dosh");
    }

    // 4. Grahan Yoga (Sun/Moon + Rahu/Ketu)
    var moon = planets.firstWhere((p) => p['name'] == 'Moon');
    int moonRashi = moon['rashi'];
    if (moonRashi == rahuRashi || moonRashi == ketu['rashi']) {
        doshas.add("Grahan Yoga");
    }

    // 5. Guru Chandal (Jupiter + Rahu)
    var jupiter = planets.firstWhere((p) => p['name'] == 'Jupiter');
    if (jupiter['rashi'] == rahuRashi) {
        doshas.add("Guru Chandal Yoga");
    }

    // 6. Vish Yoga (Saturn + Moon)
    var saturn = planets.firstWhere((p) => p['name'] == 'Saturn');
    if (saturn['rashi'] == moon['rashi']) {
        doshas.add("Vish Yoga");
    }

    // 7. Kemdrum Yoga (No planet on either side of Moon, excluding Sun/Rahu/Ketu)
    int moonH = moonRashi; // Using Rashi as simplified House index relative to Aries for this check
    // Actually we need positions relative to Moon.
    // Check 2nd and 12th from Moon
    bool hasPlanetIn2nd = false;
    bool hasPlanetIn12th = false;

    int secondFromMoon = (moonRashi % 12) + 1;
    int twelfthFromMoon = (moonRashi - 2 + 12) % 12 + 1;

    for (var p in planets) {
      if (['Sun', 'Moon', 'Rahu', 'Ketu'].contains(p['name'])) continue;
      if (p['rashi'] == secondFromMoon) hasPlanetIn2nd = true;
      if (p['rashi'] == twelfthFromMoon) hasPlanetIn12th = true;
    }

    // Also check aspect (Kendras from Moon) - strict Kemdrum is cancelled if planets in Kendra.
    // Simplified: Just 2nd/12th empty = Kemdrum.
    if (!hasPlanetIn2nd && !hasPlanetIn12th) {
      doshas.add("Kemdrum Yoga");
    }

    return doshas;
  }

  static String _getNakshatraName(int index) {
    const stars = [
      "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
      "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni",
      "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha", "Mula",
      "Purva Ashadha", "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
      "Purva Bhadrapada", "Uttara Bhadrapada", "Revati"
    ];
    if (index >= 1 && index <= 27) return stars[index - 1];
    return "Unknown";
  }

  static Map<String, dynamic> _calculateVimsottariDasha(double moonLong, DateTime birthDate) {
    // 120 years cycle
    // Moon longitude -> Nakshatra -> Lord
    // Calculation of balance of Dasha at birth

    // Nakshatra span = 13 deg 20 min = 13.3333 deg
    double degreesIntoCycle = moonLong % 120; // 9 nakshatras * 13.33 = 120 deg
    // Actually Vimsottari lords sequence repeats every 120 deg (9 nakshatras)

    double distFromStart = moonLong % 13.333333;
    double percentElapsed = distFromStart / 13.333333;
    double percentRemaining = 1.0 - percentElapsed;

    // Lords sequence for 27 nakshatras (Ketu, Venus, Sun, Moon, Mars, Rahu, Jupiter, Saturn, Mercury)
    int nakIndex = (moonLong / 13.333333).floor();
    int lordIndex = nakIndex % 9;

    List<Map<String, dynamic>> dashaLords = [
      {'name': 'Ketu', 'years': 7},
      {'name': 'Venus', 'years': 20},
      {'name': 'Sun', 'years': 6},
      {'name': 'Moon', 'years': 10},
      {'name': 'Mars', 'years': 7},
      {'name': 'Rahu', 'years': 18},
      {'name': 'Jupiter', 'years': 16},
      {'name': 'Saturn', 'years': 19},
      {'name': 'Mercury', 'years': 17},
    ];

    var currentLord = dashaLords[lordIndex];
    double balanceYears = currentLord['years'] * percentRemaining;

    DateTime currentDashaEndDate = birthDate.add(Duration(days: (balanceYears * 365.25).round()));

    // Find CURRENT running Dasha
    DateTime now = DateTime.now();
    String runningDasha = currentLord['name'];
    DateTime dashaEnd = currentDashaEndDate;

    // Iterate forward if balance is past
    int iter = 0;
    while (dashaEnd.isBefore(now) && iter < 15) { // Safety limit
        lordIndex = (lordIndex + 1) % 9;
        currentLord = dashaLords[lordIndex];
        dashaEnd = dashaEnd.add(Duration(days: (currentLord['years'] * 365.25).round()));
        runningDasha = currentLord['name'];
        iter++;
    }

    return {
      'birth_dasha': dashaLords[nakIndex % 9]['name'],
      'balance_years': balanceYears,
      'current_mahadasha': runningDasha,
      'current_mahadasha_end': dashaEnd,
    };
  }

  static double _calculateSimplifiedStrength(Map<String, dynamic> planet) {
    // Return a value between 0 and 100
    // Simplified logic: Exaltation points
    // Sun Aries(1), Moon Taurus(2), Mars Capricorn(10), Mercury Virgo(6), Jupiter Cancer(4), Venus Pisces(12), Saturn Libra(7)
    // Rahu/Ketu ignored for standard shadbala usually but we give dummy

    String name = planet['name'];
    int rashi = planet['rashi'];

    Map<String, int> exaltation = {
        'Sun': 1, 'Moon': 2, 'Mars': 10, 'Mercury': 6, 'Jupiter': 4, 'Venus': 12, 'Saturn': 7
    };
    Map<String, int> debilitation = {
        'Sun': 7, 'Moon': 8, 'Mars': 4, 'Mercury': 12, 'Jupiter': 10, 'Venus': 6, 'Saturn': 1
    };

    if (exaltation.containsKey(name)) {
        if (rashi == exaltation[name]) return 100.0; // Exalted
        if (rashi == debilitation[name]) return 20.0; // Debilitated
    }

    return 60.0; // Average
  }
}
