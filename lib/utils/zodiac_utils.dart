import 'package:flutter/material.dart';

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
}
