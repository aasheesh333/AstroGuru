import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ZodiacUtils {
  static const List<Map<String, dynamic>> zodiacData = [
    {'name': 'Aries', 'icon': Icons.whatshot, 'date': 'Mar 21 - Apr 19'},
    {'name': 'Taurus', 'icon': Icons.filter_vintage, 'date': 'Apr 20 - May 20'},
    {'name': 'Gemini', 'icon': Icons.people, 'date': 'May 21 - Jun 20'},
    {'name': 'Cancer', 'icon': Icons.nightlight_round, 'date': 'Jun 21 - Jul 22'},
    {'name': 'Leo', 'icon': Icons.wb_sunny, 'date': 'Jul 23 - Aug 22'},
    {'name': 'Virgo', 'icon': Icons.spa, 'date': 'Aug 23 - Sep 22'},
    {'name': 'Libra', 'icon': Icons.balance, 'date': 'Sep 23 - Oct 22'},
    {'name': 'Scorpio', 'icon': Icons.bug_report, 'date': 'Oct 23 - Nov 21'},
    {'name': 'Sagittarius', 'icon': Icons.arrow_outward, 'date': 'Nov 22 - Dec 21'},
    {'name': 'Capricorn', 'icon': Icons.landscape, 'date': 'Dec 22 - Jan 19'},
    {'name': 'Aquarius', 'icon': Icons.waves, 'date': 'Jan 20 - Feb 18'},
    {'name': 'Pisces', 'icon': Icons.phishing, 'date': 'Feb 19 - Mar 20'},
  ];

  static IconData getIcon(String signName) {
    final sign = zodiacData.firstWhere(
      (element) => element['name'].toString().toLowerCase() == signName.toLowerCase(),
      orElse: () => zodiacData[0], // Default to Aries
    );
    return sign['icon'] as IconData;
  }

  // Comprehensive Localization Map for 13 Languages
  static const Map<String, Map<String, String>> _localizedZodiacs = {
    // Hindi
    'hi': {
      'aries': 'मेष', 'taurus': 'वृषभ', 'gemini': 'मिथुन', 'cancer': 'कर्क',
      'leo': 'सिंह', 'virgo': 'कन्या', 'libra': 'तुला', 'scorpio': 'वृश्चिक',
      'sagittarius': 'धनु', 'capricorn': 'मकर', 'aquarius': 'कुंभ', 'pisces': 'मीन'
    },
    // Bengali
    'bn': {
      'aries': 'মেষ', 'taurus': 'বৃষ', 'gemini': 'মিথুন', 'cancer': 'কর্কট',
      'leo': 'সিংহ', 'virgo': 'কন্যা', 'libra': 'তুলা', 'scorpio': 'বৃশ্চিক',
      'sagittarius': 'ধনু', 'capricorn': 'মকর', 'aquarius': 'কুম্ভ', 'pisces': 'মীন'
    },
    // Marathi
    'mr': {
      'aries': 'मेष', 'taurus': 'वृषभ', 'gemini': 'मिथुन', 'cancer': 'कर्क',
      'leo': 'सिंह', 'virgo': 'कन्या', 'libra': 'तूळ', 'scorpio': 'वृश्चिक',
      'sagittarius': 'धनु', 'capricorn': 'मकर', 'aquarius': 'कुंभ', 'pisces': 'मीन'
    },
    // Tamil
    'ta': {
      'aries': 'மேஷம்', 'taurus': 'ரிஷபம்', 'gemini': 'மிதுனம்', 'cancer': 'கடகம்',
      'leo': 'சிம்மம்', 'virgo': 'கன்னி', 'libra': 'துலாம்', 'scorpio': 'விருச்சிகம்',
      'sagittarius': 'தனுசு', 'capricorn': 'மகரம்', 'aquarius': 'கும்பம்', 'pisces': 'மீனம்'
    },
    // Telugu
    'te': {
      'aries': 'మేషం', 'taurus': 'వృషభం', 'gemini': 'మిథునం', 'cancer': 'కర్కాటకం',
      'leo': 'సింహం', 'virgo': 'కన్య', 'libra': 'తులా', 'scorpio': 'వృశ్చికం',
      'sagittarius': 'ధనుస్సు', 'capricorn': 'మకరం', 'aquarius': 'కుంభం', 'pisces': 'మీనం'
    },
    // Gujarati
    'gu': {
      'aries': 'મેષ', 'taurus': 'વૃષભ', 'gemini': 'મિથુન', 'cancer': 'કર્ક',
      'leo': 'સિંહ', 'virgo': 'કન્યા', 'libra': 'તુલા', 'scorpio': 'વૃશ્ચિક',
      'sagittarius': 'ધનુ', 'capricorn': 'મકર', 'aquarius': 'કુંભ', 'pisces': 'મીન'
    },
    // Punjabi
    'pa': {
      'aries': 'ਮੇਖ', 'taurus': 'ਵ੍ਰਿਖ', 'gemini': 'ਮਿਥੁਨ', 'cancer': 'ਕਰਕ',
      'leo': 'ਸਿੰਘ', 'virgo': 'ਕੰਨਿਆ', 'libra': 'ਤੁਲਾ', 'scorpio': 'ਵ੍ਰਿਸ਼ਚਿਕ',
      'sagittarius': 'ਧਨੁ', 'capricorn': 'ਮਕਰ', 'aquarius': 'ਕੁੰਭ', 'pisces': 'ਮੀਨ'
    },
    // Kannada
    'kn': {
      'aries': 'ಮೇಷ', 'taurus': 'ವೃಷಭ', 'gemini': 'ಮಿಥುನ', 'cancer': 'ಕರ್ಕಾಟಕ',
      'leo': 'ಸಿಂಹ', 'virgo': 'ಕನ್ಯಾ', 'libra': 'ತುಲಾ', 'scorpio': 'ವೃಶ್ಚಿಕ',
      'sagittarius': 'ಧನು', 'capricorn': 'ಮಕರ', 'aquarius': 'ಕುಂಭ', 'pisces': 'ಮೀನ'
    },
    // Malayalam
    'ml': {
      'aries': 'മേടം', 'taurus': 'ഇടവം', 'gemini': 'മിഥുനം', 'cancer': 'കർക്കിടകം',
      'leo': 'ചിങ്ങം', 'virgo': 'കന്നി', 'libra': 'തുലാം', 'scorpio': 'വൃശ്ചികം',
      'sagittarius': 'ധനു', 'capricorn': 'മകരം', 'aquarius': 'കുംഭം', 'pisces': 'മീനം'
    },
    // Odia
    'or': {
      'aries': 'ମେଷ', 'taurus': 'ବୃଷ', 'gemini': 'ମିଥୁନ', 'cancer': 'କର୍କଟ',
      'leo': 'ସିଂହ', 'virgo': 'କନ୍ୟା', 'libra': 'ତୁଳା', 'scorpio': 'ବିଛା',
      'sagittarius': 'ଧନୁ', 'capricorn': 'ମକର', 'aquarius': 'କୁମ୍ଭ', 'pisces': 'ମୀନ'
    },
    // Assamese
    'as': {
      'aries': 'মেষ', 'taurus': 'বৃষ', 'gemini': 'মিথুন', 'cancer': 'কৰ্কট',
      'leo': 'সিংহ', 'virgo': 'কন্যা', 'libra': 'তুলা', 'scorpio': 'বৃশ্চিক',
      'sagittarius': 'ধনু', 'capricorn': 'মকৰ', 'aquarius': 'কুম্ভ', 'pisces': 'মীন'
    },
    // Urdu
    'ur': {
      'aries': 'حمل', 'taurus': 'ثور', 'gemini': 'جوزا', 'cancer': 'سرطان',
      'leo': 'اسد', 'virgo': 'سنبلہ', 'libra': 'میزان', 'scorpio': 'عقرب',
      'sagittarius': 'قوس', 'capricorn': 'جدی', 'aquarius': 'دلو', 'pisces': 'حوت'
    },
  };

  // Helper to get localized name
  static String getLocalizedName(BuildContext context, String signName) {
    // 1. Try AppLocalizations (if keys existed, currently they don't, but keeping the pattern is good)
    // final loc = AppLocalizations.of(context);
    // ...

    // 2. Use Static Map based on Language Code
    final langCode = Localizations.localeOf(context).languageCode;

    if (_localizedZodiacs.containsKey(langCode)) {
      final normalizedSign = signName.toLowerCase();
      final map = _localizedZodiacs[langCode]!;
      if (map.containsKey(normalizedSign)) {
        return map[normalizedSign]!;
      }
    }

    // 3. Fallback to English (Original Name)
    return signName;
  }
}
