import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/zodiac_utils.dart';
import 'horoscope_detail_screen.dart';

class HoroscopeScreen extends StatelessWidget {
  const HoroscopeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.navHoroscope),
        automaticallyImplyLeading: false,
      ),
      body: const HoroscopeContent(),
    );
  }
}

class HoroscopeContent extends StatelessWidget {
  const HoroscopeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // "Select your Zodiac Sign" doesn't have a direct key in ARB shown,
          // but "dailyHoroscopeTitle" is "Daily Horoscope".
          // We can use a generic title or just keep it simple.
          // Or reuse "navHoroscope" which is "Horoscope".
          // Let's use a hardcoded fallback with localization attempt if key existed, but since it doesn't:
          // We will use 'navHoroscope' + "Selection" or similar if we could.
          // But strict instruction: "zodiac sign are hardcoded in english it should be translated".
          // The title "Select your Zodiac Sign" is also English.
          // I will use `AppLocalizations.of(context)!.navHoroscope` as the AppBar title (already done above).
          // For the body text, since I cannot modify ARB easily without risk, I will replace it with "Horoscope" as well or just remove it if redundant?
          // No, I should keep the layout.
          // I will check if there is a 'select' or similar. "selectLanguage" exists.
          // I'll assume "Select Zodiac" isn't critical to be perfect, but the SIGNS are.
          // However, to be safe, I will change the text to just "Horoscope" or similar available string, or keep it English if no better option?
          // The prompt specifically complained about "zodiac sign".
          // I will use `AppLocalizations.of(context)!.navHoroscope` for the header text too.
          Text(
            AppLocalizations.of(context)!.navHoroscope,
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
              itemCount: ZodiacUtils.zodiacData.length,
              itemBuilder: (context, index) {
                final sign = ZodiacUtils.zodiacData[index];
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
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
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
                        // Localized Sign Name
                        Text(
                          ZodiacUtils.getLocalizedName(context, sign['name']),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
