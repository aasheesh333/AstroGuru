import 'package:flutter/foundation.dart';

class AppValidators {
  // Regex covering English + 12 Indian Scripts (Devanagari, Bengali, Gurmukhi, Gujarati, Oriya, Tamil, Telugu, Kannada, Malayalam, Urdu/Arabic)
  // \u0900-\u097F : Devanagari (Hindi, Marathi)
  // \u0980-\u09FF : Bengali (Bengali, Assamese)
  // \u0A00-\u0A7F : Gurmukhi (Punjabi)
  // \u0A80-\u0AFF : Gujarati
  // \u0B00-\u0B7F : Oriya
  // \u0B80-\u0BFF : Tamil
  // \u0C00-\u0C7F : Telugu
  // \u0C80-\u0CFF : Kannada
  // \u0D00-\u0D7F : Malayalam
  // \u0600-\u06FF : Arabic (Urdu)
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

    // Hindi Transliterations (Examples)
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

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return "Name is required";
    String name = value.trim();

    // 1. Script Check & Symbols
    if (!_allowedChars.hasMatch(name)) {
      return "Use only letters (A-Z or Indian scripts). No numbers/symbols.";
    }

    // 2. Length Check
    if (name.length < 3) return "Name too short (min 3 chars).";
    if (name.length > 100) return "Name too long (max 100 chars).";

    // 3. Word Count
    if (name.split(RegExp(r'\s+')).length > 4) {
      return "Max 4 words allowed.";
    }

    // 4. Repeated Characters
    if (_repeatingChars.hasMatch(name)) {
      return "Invalid name format (repeated characters).";
    }

    // 5. Blacklist
    if (_blacklistedWords.contains(name.toLowerCase())) {
      return "Please enter a valid real name.";
    }

    return null;
  }

  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) return "Location is required";
    String place = value.trim();

    // 1. Script Check & Symbols (Reuse allowed chars as it's the same requirement)
    if (!_allowedChars.hasMatch(place)) {
      return "Use only letters (A-Z or Indian scripts). No numbers/symbols.";
    }

    // 2. Length Check
    if (place.length < 3) return "Location too short (min 3 chars).";
    if (place.length > 100) return "Location too long (max 100 chars).";

    // 3. Blacklist/Meaningless
    if (_blacklistedWords.contains(place.toLowerCase())) {
      return "Please enter a valid location.";
    }

    // 4. Internal City List Match (Partial or Full)
    // "If user input does NOT match or partially match any real city → mark invalid"
    // We check if the input *contains* a known city OR a known city *contains* the input (fuzzy)
    // Actually, user said: "If user input does NOT match or partially match any real city"
    // This implies: "Mumbai" is valid. "North Mumbai" is valid (contains Mumbai). "Mumb" might be valid (Mumbai contains Mumb).
    // But "Mumb" is too short maybe? No, logic handles length >= 3.
    // Let's go with: Input must contain a known city name (case-insensitive) OR be contained in one.
    // But "Delhi" matches "New Delhi". "Del" matches "Delhi".
    // "Test" shouldn't match.

    bool matchFound = false;
    String lowerPlace = place.toLowerCase();

    for (String city in _indianCities) {
      String lowerCity = city.toLowerCase();
      // Check for exact match, containment, or being contained
      if (lowerPlace == lowerCity || lowerPlace.contains(lowerCity) || lowerCity.contains(lowerPlace)) {
        matchFound = true;
        break;
      }
    }

    if (!matchFound) {
      return "Please enter a recognized Indian city/district.";
    }

    return null;
  }
}
