import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppValidators {
  // Regex covering English + 12 Indian Scripts
  static final RegExp _allowedChars = RegExp(
    r"^[a-zA-Z\s\u0900-\u097F\u0980-\u09FF\u0A00-\u0A7F\u0A80-\u0AFF\u0B00-\u0B7F\u0B80-\u0BFF\u0C00-\u0C7F\u0C80-\u0CFF\u0D00-\u0D7F\u0600-\u06FF]+$"
  );

  static final RegExp _repeatingChars = RegExp(r"(.)\1{3,}"); // 4 or more repeated chars

  static final List<String> _blacklistedWords = [
    "men", "woman", "boy", "girl", "test", "demo", "admin", "achha", "hello", "name",
    "is", "the", "and", "or", "what", "where", "how", "asdjkwq", "hshshsh", "xyz", "abc"
  ];

  static final List<String> _indianCities = [
    // Top ~300 Indian Cities/Districts/States
    "Mumbai", "Delhi", "Bangalore", "Bengaluru", "Hyderabad", "Ahmedabad", "Chennai", "Kolkata", "Surat", "Pune",
    "Jaipur", "Lucknow", "Kanpur", "Nagpur", "Indore", "Thane", "Bhopal", "Visakhapatnam", "Pimpri-Chinchwad", "Patna",
    "Vadodara", "Ghaziabad", "Ludhiana", "Agra", "Nashik", "Faridabad", "Meerut", "Rajkot", "Kalyan-Dombivli", "Vasai-Virar",
    "Varanasi", "Srinagar", "Aurangabad", "Dhanbad", "Amritsar", "Navi Mumbai", "Allahabad", "Prayagraj", "Howrah", "Ranchi",
    "Gwalior", "Jabalpur", "Coimbatore", "Vijayawada", "Jodhpur", "Madurai", "Raipur", "Kota", "Guwahati", "Chandigarh",
    "Solapur", "Hubballi-Dharwad", "Mysore", "Mysuru", "Tiruchirappalli", "Bareilly", "Aligarh", "Tiruppur", "Gurgaon", "Gurugram",
    "Moradabad", "Jalandhar", "Bhubaneswar", "Salem", "Warangal", "Mira-Bhayandar", "Jalgaon", "Guntur", "Thiruvananthapuram",
    "Bhiwandi", "Saharanpur", "Gorakhpur", "Bikaner", "Amravati", "Noida", "Jamshedpur", "Bhilai", "Cuttack", "Firozabad",
    "Kochi", "Nellore", "Bhavnagar", "Dehradun", "Durgapur", "Asansol", "Rourkela", "Nanded", "Kolhapur", "Ajmer",
    "Akola", "Gulbarga", "Kalaburagi", "Jamnagar", "Ujjain", "Loni", "Siliguri", "Jhansi", "Ulhasnagar", "Jammu",
    "Sangli-Miraj & Kupwad", "Mangalore", "Mangaluru", "Erode", "Belgaum", "Belagavi", "Ambattur", "Tirunelveli", "Malegaon", "Gaya",
    "Jalna", "Udaipur", "Maheshtala", "Davanagere", "Kozhikode", "Kurnool", "Rajpur Sonarpur", "Rajahmundry", "Bokaro", "South Dumdum",
    "Bellary", "Ballari", "Patiala", "Gopalpur", "Agartala", "Bhagalpur", "Muzaffarnagar", "Bhatpara", "Panihati", "Latur",
    "Dhule", "Tirupati", "Rohtak", "Korba", "Bhilwara", "Berhampur", "Muzaffarpur", "Ahmednagar", "Mathura", "Kollam",
    "Avadi", "Kadapa", "Kamarhati", "Sambalpur", "Bilaspur", "Shahjahanpur", "Satara", "Bijapur", "Vijayapura", "Rampur",
    "Shivamogga", "Chandrapur", "Junagadh", "Thrissur", "Alwar", "Bardhaman", "Kulti", "Nizamabad", "Parbhani", "Tumkur",
    "Tumakuru", "Khammam", "Ozhukarai", "Bihar Sharif", "Panipat", "Darbhanga", "Bally", "Aizawl", "Dewas", "Ichalkaranji",
    "Karnal", "Bathinda", "Jalna", "Eluru", "Kirari Suleman Nagar", "Barasat", "Purnia", "Satna", "Mau", "Sonipat",
    "Farrukhabad", "Sagar", "Rourkela", "Durg", "Imphal", "Ratlam", "Hapur", "Arrah", "Karimnagar", "Anantapur",
    "Etawah", "Ambernath", "North Dumdum", "Bharatpur", "Begusarai", "New Delhi", "Gandhidham", "Baranagar", "Tiruvottiyur", "Pondicherry",
    "Sikar", "Thoothukudi", "Rewa", "Mirzapur", "Raichur", "Pali", "Ramagundam", "Haridwar", "Vijayanagaram", "Katihar",
    "Nagarcoil", "Sri Ganganagar", "Karawal Nagar", "Mango", "Thanjavur", "Bulandshahr", "Uluberia", "Murwara", "Sambhal", "Singrauli",
    "Nadiad", "Secunderabad", "Naihati", "Yamunanagar", "Bidhan Nagar", "Pallavaram", "Bidar", "Munger", "Panchkula", "Burhanpur",
    "Raurkela Industrial Township", "Kharagpur", "Dindigul", "Gandhinagar", "Hospet", "Nangloi Jat", "English Bazar", "Ongole", "Deoghar", "Chapra",
    "Haldia", "Khandwa", "Nandyal", "Chittoor", "Morena", "Amroha", "Anand", "Bhind", "Bhalswa Jahangir Pur", "Madhyamgram",
    "Bhiwani", "Navi Mumbai Panvel Raigad", "Baharampur", "Ambala", "Morvi", "Fatehpur", "Rae Bareli", "Khora", "Bhusawal", "Orai",
    "Bahraich", "Vellore", "Mahesana", "Sambalpur", "Raiganj", "Sirsa", "Danapur", "Serampore", "Sultan Pur Majra", "Guna",
    "Jaunpur", "Panvel", "Shivpuri", "Surendranagar Dudhrej", "Unnao", "Hugli and Chinsurah", "Alappuzha", "Kottayam", "Shimla", "Karaikudi",

    // Hindi Transliterations
    "दिल्ली", "मुंबई", "बंगलुरु", "अहमदाबाद", "हैदराबाद", "चेन्नई", "कोलकाता", "पुणे", "जयपुर", "लखनऊ",
    "कानपुर", "नागपुर", "इंदौर", "भोपाल", "पटना", "गाजियाबाद", "आगरा", "वाराणसी", "मेरठ", "प्रयागराज",

    // Gujarati
    "અમદાવાદ", "સુરત", "વડોદરા", "રાજકોટ", "ભાવનગર", "જામનગર", "ગાંધીનગર",

    // Marathi
    "मुंबई", "पुणे", "नागपूर", "ठाणे", "पिंपरी-चिंचवड", "नाशिक", "कल्याण-डोंबिवली", "वसई-विरार", "औरंगाबाद", "नवी मुंबई",

    // Bengali
    "কলকাতা", "হাওড়া", "দুর্গাপুর", "আসানসোল", "শিলিগুড়ি",

    // Tamil
    "சென்னை", "கோயம்புத்தூர்", "மதுரை", "திருச்சிராப்பள்ளி", "சேலம்",

    // Telugu
    "హైదరాబాద్", "విశాఖపట్నం", "విజయవాడ", "గుంటూరు", "వరంగల్",

    // Kannada
    "ಬೆಂಗಳೂರು", "ಮೈಸೂರು", "ಹುಬ್ಬಳ್ಳಿ-ಧಾರವಾಡ", "ಮಂಗಳೂರು", "ಬೆಳಗಾವಿ",

    // Malayalam
    "തിരുവനന്തപുരം", "കൊച്ചി", "കോഴിക്കോട്", "തൃശ്ശൂർ", "കൊല്ലം", "വയനാട്"
  ];

  static String? validateName(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) return l10n.errorNameRequired;
    String name = value.trim();

    // 1. Script Check & Symbols
    if (!_allowedChars.hasMatch(name)) {
      return l10n.errorNameInvalidChars;
    }

    // 2. Length Check
    if (name.length < 3) return l10n.errorNameTooShort;
    if (name.length > 100) return l10n.errorNameTooLong;

    // 3. Word Count
    if (name.split(RegExp(r'\s+')).length > 4) {
      return l10n.errorNameMaxWords;
    }

    // 4. Repeated Characters
    if (_repeatingChars.hasMatch(name)) {
      return l10n.errorNameRepeatedChars;
    }

    // 5. Blacklist
    if (_blacklistedWords.contains(name.toLowerCase())) {
      return l10n.errorNameFake;
    }

    return null;
  }

  static String? validateLocation(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) return l10n.errorLocationRequired;
    String place = value.trim();

    // 1. Script Check & Symbols
    if (!_allowedChars.hasMatch(place)) {
      return l10n.errorLocationInvalidChars;
    }

    // 2. Length Check
    if (place.length < 3) return l10n.errorLocationTooShort;
    if (place.length > 100) return l10n.errorLocationTooLong;

    // 3. Blacklist
    if (_blacklistedWords.contains(place.toLowerCase())) {
      return l10n.errorLocationFake;
    }

    // 4. Internal City List Match
    bool matchFound = false;
    String lowerPlace = place.toLowerCase();

    for (String city in _indianCities) {
      String lowerCity = city.toLowerCase();
      if (lowerPlace == lowerCity || lowerPlace.contains(lowerCity) || lowerCity.contains(lowerPlace)) {
        matchFound = true;
        break;
      }
    }

    if (!matchFound) {
      return l10n.errorLocationUnknown;
    }

    return null;
  }
}
