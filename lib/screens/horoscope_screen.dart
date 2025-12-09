import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'horoscope_detail_screen.dart';

class HoroscopeScreen extends StatelessWidget {
  const HoroscopeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horoscope'),
        automaticallyImplyLeading: false,
      ),
      body: const HoroscopeContent(),
    );
  }
}

class HoroscopeContent extends StatelessWidget {
  const HoroscopeContent({super.key});

  final List<Map<String, dynamic>> _zodiacSigns = const [
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Select your Zodiac Sign',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _zodiacSigns.length,
              itemBuilder: (context, index) {
                final sign = _zodiacSigns[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HoroscopeDetailScreen(
                          signName: sign['name'],
                          signIcon: sign['icon'],
                          // data is optional now, so it will fetch automatically
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sign['icon'],
                          size: 32,
                          color: AppColors.primaryGold,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          sign['name'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sign['date'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
