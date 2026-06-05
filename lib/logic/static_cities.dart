/// Bundled static lookup of major Indian cities and towns with their
/// geographic coordinates. Used as an offline geocoding replacement for
/// the Kundli place-of-birth input.
///
/// All coordinates are decimal degrees (WGS84).
class StaticCities {
  // Default fallback (New Delhi) used when no match is found.
  static const double _defaultLat = 28.6139;
  static const double _defaultLon = 77.2090;

  /// Returns (lat, lon) for the best match of [place] (case-insensitive,
  /// whitespace-tolerant), or the New Delhi default if no match is found.
  static (double, double) lookup(String place) {
    if (place.trim().isEmpty) return (_defaultLat, _defaultLon);

    final String normalized = _normalize(place);
    final List<String> tokens = normalized.split(' ').where((t) => t.isNotEmpty).toList();

    // 1) Exact match.
    for (final entry in _cities) {
      if (_normalize(entry.name) == normalized) {
        return (entry.lat, entry.lon);
      }
    }

    // 2) All tokens present in the city name.
    for (final entry in _cities) {
      final String cityNorm = _normalize(entry.name);
      if (tokens.every((t) => cityNorm.contains(t))) {
        return (entry.lat, entry.lon);
      }
    }

    // 3) Any token of the city matches any token of the input.
    for (final entry in _cities) {
      final String cityNorm = _normalize(entry.name);
      if (tokens.any((t) => cityNorm.contains(t)) && tokens.first.length >= 4) {
        return (entry.lat, entry.lon);
      }
    }

    return (_defaultLat, _defaultLon);
  }

  /// Returns the canonical (English) name of the best match, or null.
  static String? lookupName(String place) {
    if (place.trim().isEmpty) return null;
    final String normalized = _normalize(place);
    final List<String> tokens = normalized.split(' ').where((t) => t.isNotEmpty).toList();

    for (final entry in _cities) {
      if (_normalize(entry.name) == normalized) return entry.name;
    }
    for (final entry in _cities) {
      final String cityNorm = _normalize(entry.name);
      if (tokens.every((t) => cityNorm.contains(t))) return entry.name;
    }
    for (final entry in _cities) {
      final String cityNorm = _normalize(entry.name);
      if (tokens.any((t) => cityNorm.contains(t)) && tokens.first.length >= 4) {
        return entry.name;
      }
    }
    return null;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _City {
  final String name;
  final double lat;
  final double lon;
  const _City(this.name, this.lat, this.lon);
}

const List<_City> _cities = [
  // State Capitals & Major Metros
  _City('Mumbai', 19.0760, 72.8777),
  _City('Delhi', 28.6139, 77.2090),
  _City('New Delhi', 28.6139, 77.2090),
  _City('Bangalore', 12.9716, 77.5946),
  _City('Bengaluru', 12.9716, 77.5946),
  _City('Hyderabad', 17.3850, 78.4867),
  _City('Ahmedabad', 23.0225, 72.5714),
  _City('Chennai', 13.0827, 80.2707),
  _City('Kolkata', 22.5726, 88.3639),
  _City('Surat', 21.1702, 72.8311),
  _City('Pune', 18.5204, 73.8567),
  _City('Jaipur', 26.9124, 75.7873),
  _City('Lucknow', 26.8467, 80.9462),
  _City('Kanpur', 26.4499, 80.3319),
  _City('Nagpur', 21.1458, 79.0882),
  _City('Indore', 22.7196, 75.8577),
  _City('Thane', 19.2183, 72.9781),
  _City('Bhopal', 23.2599, 77.4126),
  _City('Visakhapatnam', 17.6868, 83.2185),
  _City('Pimpri-Chinchwad', 18.6298, 73.7997),
  _City('Patna', 25.5941, 85.1376),
  _City('Vadodara', 22.3072, 73.1812),
  _City('Ghaziabad', 28.6692, 77.4538),
  _City('Ludhiana', 30.9010, 75.8573),
  _City('Agra', 27.1767, 78.0081),
  _City('Nashik', 19.9975, 73.7898),
  _City('Faridabad', 28.4089, 77.3178),
  _City('Meerut', 28.9845, 77.7064),
  _City('Rajkot', 22.3039, 70.8022),
  _City('Kalyan-Dombivli', 19.2437, 73.1355),
  _City('Vasai-Virar', 19.3919, 72.8397),
  _City('Varanasi', 25.3176, 82.9739),
  _City('Srinagar', 34.0837, 74.7973),
  _City('Aurangabad', 19.8762, 75.3433),
  _City('Dhanbad', 23.7957, 86.4304),
  _City('Amritsar', 31.6340, 74.8723),
  _City('Navi Mumbai', 19.0330, 73.0297),
  _City('Allahabad', 25.4358, 81.8463),
  _City('Prayagraj', 25.4358, 81.8463),
  _City('Howrah', 22.5958, 88.2636),
  _City('Ranchi', 23.3441, 85.3096),
  _City('Gwalior', 26.2183, 78.1828),
  _City('Jabalpur', 23.1815, 79.9864),
  _City('Coimbatore', 11.0168, 76.9558),
  _City('Vijayawada', 16.5062, 80.6480),
  _City('Jodhpur', 26.2389, 73.0243),
  _City('Madurai', 9.9252, 78.1198),
  _City('Raipur', 21.2514, 81.6296),
  _City('Kota', 25.2138, 75.8648),
  _City('Guwahati', 26.1445, 91.7362),
  _City('Chandigarh', 30.7333, 76.7794),
  _City('Solapur', 17.6599, 75.9064),
  _City('Hubballi-Dharwad', 15.3647, 75.1240),
  _City('Mysore', 12.2958, 76.6394),
  _City('Mysuru', 12.2958, 76.6394),
  _City('Tiruchirappalli', 10.7905, 78.7047),
  _City('Bareilly', 28.3670, 79.4304),
  _City('Aligarh', 27.8974, 78.0880),
  _City('Tiruppur', 11.1085, 77.3411),
  _City('Gurgaon', 28.4595, 77.0266),
  _City('Gurugram', 28.4595, 77.0266),
  _City('Moradabad', 28.8386, 78.7733),
  _City('Jalandhar', 31.3260, 75.5762),
  _City('Bhubaneswar', 20.2961, 85.8245),
  _City('Salem', 11.6643, 78.1460),
  _City('Warangal', 17.9689, 79.5941),
  _City('Mira-Bhayandar', 19.2952, 72.8544),
  _City('Jalgaon', 21.0077, 75.5626),
  _City('Guntur', 16.3067, 80.4365),
  _City('Thiruvananthapuram', 8.5241, 76.9366),
  _City('Bhiwandi', 19.2813, 73.0483),
  _City('Saharanpur', 29.9680, 77.5510),
  _City('Gorakhpur', 26.7606, 83.3732),
  _City('Bikaner', 28.0229, 73.3119),
  _City('Amravati', 20.9333, 77.7550),
  _City('Noida', 28.5355, 77.3910),
  _City('Jamshedpur', 22.8046, 86.2029),
  _City('Bhilai', 21.1938, 81.3506),
  _City('Cuttack', 20.4625, 85.8830),
  _City('Firozabad', 27.1591, 78.3957),
  _City('Kochi', 9.9312, 76.2673),
  _City('Nellore', 14.4426, 79.9865),
  _City('Bhavnagar', 21.7645, 72.1519),
  _City('Dehradun', 30.3165, 78.0322),
  _City('Durgapur', 23.5204, 87.3119),
  _City('Asansol', 23.6739, 86.9524),
  _City('Rourkela', 22.2604, 84.8536),
  _City('Nanded', 19.1383, 77.3210),
  _City('Kolhapur', 16.7050, 74.2433),
  _City('Ajmer', 26.4499, 74.6399),
  _City('Akola', 20.7002, 77.0082),
  _City('Gulbarga', 17.3297, 76.8343),
  _City('Kalaburagi', 17.3297, 76.8343),
  _City('Jamnagar', 22.4707, 70.0577),
  _City('Ujjain', 23.1793, 75.7849),
  _City('Siliguri', 26.7271, 88.3953),
  _City('Jhansi', 25.4484, 78.5685),
  _City('Jammu', 32.7266, 74.8570),
  _City('Mangalore', 12.9141, 74.8560),
  _City('Mangaluru', 12.9141, 74.8560),
  _City('Erode', 11.3410, 77.7172),
  _City('Belgaum', 15.8497, 74.4977),
  _City('Belagavi', 15.8497, 74.4977),
  _City('Tirunelveli', 8.7139, 77.7567),
  _City('Gaya', 24.7954, 85.0000),
  _City('Udaipur', 24.5854, 73.7125),
  _City('Davanagere', 14.4644, 75.9218),
  _City('Kozhikode', 11.2588, 75.7804),
  _City('Kurnool', 15.8281, 78.0373),
  _City('Rajahmundry', 17.0005, 81.8040),
  _City('Bokaro', 23.6693, 86.1511),
  _City('Patiala', 30.3398, 76.3869),
  _City('Bhagalpur', 25.2425, 86.9842),
  _City('Muzaffarnagar', 29.4727, 77.7085),
  _City('Latur', 18.4088, 76.5604),
  _City('Rohtak', 28.8955, 76.6066),
  _City('Korba', 22.3595, 82.7501),
  _City('Bhilwara', 25.3407, 74.6263),
  _City('Muzaffarpur', 26.1209, 85.3647),
  _City('Ahmednagar', 19.0948, 74.7480),
  _City('Mathura', 27.4924, 77.6737),
  _City('Kollam', 8.8932, 76.6141),
  _City('Kadapa', 14.4674, 78.8241),
  _City('Sambalpur', 21.4669, 83.9812),
  _City('Bilaspur', 22.0796, 82.1409),
  _City('Shahjahanpur', 27.8806, 79.9080),
  _City('Satara', 17.6805, 74.0183),
  _City('Rampur', 28.7895, 79.0250),
  _City('Junagadh', 21.5222, 70.4579),
  _City('Thrissur', 10.5276, 76.2144),
  _City('Alwar', 27.5530, 76.6346),
  _City('Nizamabad', 18.6725, 78.0941),
  _City('Parbhani', 19.2704, 76.7600),
  _City('Tumkur', 13.3392, 77.0999),
  _City('Tumakuru', 13.3392, 77.0999),
  _City('Khammam', 17.2473, 80.1514),
  _City('Panipat', 29.3909, 76.9635),
  _City('Darbhanga', 26.1542, 85.8918),
  _City('Aizawl', 23.7271, 92.7176),
  _City('Dewas', 22.9623, 76.0508),
  _City('Karnal', 29.6857, 76.9905),
  _City('Bathinda', 30.2110, 74.9455),
  _City('Eluru', 16.7107, 81.0952),
  _City('Purnia', 25.7771, 87.4753),
  _City('Satna', 24.6005, 80.8322),
  _City('Sonipat', 28.9931, 77.0151),
  _City('Farrukhabad', 27.3826, 79.5946),
  _City('Sagar', 23.8388, 78.7378),
  _City('Durg', 21.1900, 81.2849),
  _City('Imphal', 24.8170, 93.9368),
  _City('Ratlam', 23.3342, 75.0376),
  _City('Hapur', 28.7306, 77.7809),
  _City('Arrah', 25.5560, 84.6627),
  _City('Karimnagar', 18.4386, 79.1288),
  _City('Anantapur', 14.6819, 77.6006),
  _City('Etawah', 26.7855, 79.0150),
  _City('Bharatpur', 27.2170, 77.4905),
  _City('Begusarai', 25.4182, 86.1272),
  _City('Gandhidham', 23.0759, 70.1342),
  _City('Tiruvottiyur', 13.1643, 80.3006),
  _City('Pondicherry', 11.9139, 79.8145),
  _City('Puducherry', 11.9139, 79.8145),
  _City('Sikar', 27.6094, 75.1399),
  _City('Thoothukudi', 8.7642, 78.1348),
  _City('Rewa', 24.5373, 81.3042),
  _City('Mirzapur', 25.1460, 82.5687),
  _City('Raichur', 16.2120, 77.3439),
  _City('Pali', 25.7728, 73.3239),
  _City('Haridwar', 29.9457, 78.1642),
  _City('Vijayanagaram', 18.1124, 83.4053),
  _City('Katihar', 25.5335, 87.5837),
  _City('Nagercoil', 8.1790, 77.4294),
  _City('Sri Ganganagar', 29.9038, 73.8772),
  _City('Thanjavur', 10.7867, 79.1378),
  _City('Bulandshahr', 28.4069, 77.8498),
  _City('Nadiad', 22.6916, 72.8634),
  _City('Secunderabad', 17.4399, 78.4983),
  _City('Naihati', 22.8940, 88.4226),
  _City('Yamunanagar', 30.1290, 77.2964),
  _City('Bidar', 17.9104, 77.5197),
  _City('Panchkula', 30.6916, 76.8547),
  _City('Burhanpur', 21.3000, 76.1300),
  _City('Kharagpur', 22.3460, 87.2320),
  _City('Dindigul', 10.3673, 77.9803),
  _City('Gandhinagar', 23.2156, 72.6369),
  _City('Hospet', 15.2689, 76.3909),
  _City('Ongole', 15.5057, 80.0499),
  _City('Deoghar', 24.4824, 86.7000),
  _City('Haldia', 22.0667, 88.0698),
  _City('Khandwa', 21.8246, 76.3526),
  _City('Nandyal', 15.4786, 78.4831),
  _City('Chittoor', 13.2172, 79.1003),
  _City('Morena', 26.4970, 78.0000),
  _City('Amroha', 28.9044, 78.4673),
  _City('Anand', 22.5645, 72.9289),
  _City('Bhind', 26.5645, 78.7880),
  _City('Bhiwani', 28.7990, 76.1335),
  _City('Ambala', 30.3753, 76.7821),
  _City('Fatehpur', 25.9300, 80.8100),
  _City('Rae Bareli', 26.2170, 81.2333),
  _City('Vellore', 12.9165, 79.1325),
  _City('Mahesana', 23.5880, 72.3693),
  _City('Sirsa', 29.5321, 75.0318),
  _City('Danapur', 25.6360, 85.0458),
  _City('Serampore', 22.7505, 88.3415),
  _City('Guna', 24.6475, 77.3117),
  _City('Jaunpur', 25.7500, 82.6833),
  _City('Panvel', 18.9894, 73.1175),
  _City('Shivpuri', 25.4232, 77.6588),
  _City('Unnao', 26.5470, 80.4878),
  _City('Alappuzha', 9.4981, 76.3388),
  _City('Kottayam', 9.5916, 76.5222),
  _City('Shimla', 31.1048, 77.1734),
  _City('Itarsi', 22.6144, 77.7622),
  _City('Bhusawal', 21.0455, 75.8011),
  _City('Orai', 25.9900, 79.4500),
  _City('Bahraich', 27.5740, 81.5940),
  _City('Vellore', 12.9165, 79.1325),
  _City('Mahesana', 23.5880, 72.3693),
  _City('Surendranagar', 22.7200, 71.6500),
  _City('Hugli', 22.9000, 88.4000),
  _City('Chinsurah', 22.8997, 88.3983),

  // Union Territories
  _City('Port Blair', 11.6234, 92.7265),
  _City('Visakhapatnam', 17.6868, 83.2185),
  _City('Panaji', 15.4989, 73.8278),
  _City('Margao', 15.2742, 73.9586),
  _City('Vasco da Gama', 15.3958, 73.8156),
  _City('Diu', 20.7144, 70.9874),
  _City('Daman', 20.3974, 72.8328),
  _City('Silvassa', 20.2765, 72.9962),
  _City('Kavaratti', 10.5593, 72.6358),
  _City('Leh', 34.1526, 77.5771),
  _City('Kargil', 34.5539, 76.1349),
  _City('Itanagar', 27.0844, 93.6053),
  _City('Naharlagun', 27.1044, 93.6953),
  _City('Gangtok', 27.3389, 88.6065),
  _City('Shillong', 25.5788, 91.8933),
  _City('Kohima', 25.6586, 94.1053),
  _City('Dimapur', 25.9063, 93.7276),

  // Foreign / International cities (for NRIs)
  _City('Dubai', 25.2048, 55.2708),
  _City('Abu Dhabi', 24.4539, 54.3773),
  _City('Sharjah', 25.3463, 55.4209),
  _City('Doha', 25.2854, 51.5310),
  _City('Riyadh', 24.7136, 46.6753),
  _City('Jeddah', 21.4858, 39.1925),
  _City('Muscat', 23.5859, 58.4059),
  _City('Kuwait City', 29.3759, 47.9774),
  _City('Manama', 26.2285, 50.5860),
  _City('Singapore', 1.3521, 103.8198),
  _City('Hong Kong', 22.3193, 114.1694),
  _City('Kuala Lumpur', 3.1390, 101.6869),
  _City('Bangkok', 13.7563, 100.5018),
  _City('Colombo', 6.9271, 79.8612),
  _City('Kathmandu', 27.7172, 85.3240),
  _City('Dhaka', 23.8103, 90.4125),
  _City('Karachi', 24.8607, 67.0011),
  _City('Lahore', 31.5204, 74.3587),
  _City('Islamabad', 33.6844, 73.0479),
  _City('Colombo', 6.9271, 79.8612),
  _City('New York', 40.7128, -74.0060),
  _City('Los Angeles', 34.0522, -118.2437),
  _City('Chicago', 41.8781, -87.6298),
  _City('Toronto', 43.6532, -79.3832),
  _City('Vancouver', 49.2827, -123.1207),
  _City('San Francisco', 37.7749, -122.4194),
  _City('London', 51.5074, -0.1278),
  _City('Sydney', -33.8688, 151.2093),
  _City('Melbourne', -37.8136, 144.9631),
];
