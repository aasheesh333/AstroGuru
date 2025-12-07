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

    return {
      'lagna': lagna,
      'planets': planets,
      'jd': jd,
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
    var mars = chart['planets'].firstWhere((p) => p['name'] == 'Mars');
    int marsRashi = mars['rashi'];
    int marsHouse = (marsRashi - lagnaRashi + 1 + 12) % 12;
    if (marsHouse == 0) marsHouse = 12;

    if ([1, 2, 4, 7, 8, 12].contains(marsHouse)) {
      doshas.add("Mangal Dosh");
    }
    return doshas;
  }
}
