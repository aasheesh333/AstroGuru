import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../logic/language_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Daily Horoscope in One Tap',
      'desc': 'Get accurate daily predictions based on your zodiac sign.',
    },
    {
      'title': 'AI-Powered Astrology Chat',
      'desc': 'Ask our AI Sage anything about your future and life path.',
    },
    {
      'title': 'Generate Your Kundli Instantly',
      'desc': 'Detailed Kundli generation with Dasha and Remedies.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _currentPage = value),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 250,
                            width: 250,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForSlide(index),
                              size: 100,
                              color: AppColors.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            slide['title']!,
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide['desc']!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.primaryGold
                                : AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      text: _currentPage == _slides.length - 1 ? (AppLocalizations.of(context)?.getStarted ?? 'Get Started') : 'Next',
                      onPressed: () {
                        if (_currentPage == _slides.length - 1) {
                          _showLanguageDialog();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForSlide(int index) {
    switch (index) {
      case 0: return Icons.star_border;
      case 1: return Icons.chat_bubble_outline;
      case 2: return Icons.auto_awesome;
      default: return Icons.star;
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: Text(AppLocalizations.of(context)?.selectLanguage ?? 'Select Language', style: const TextStyle(color: AppColors.primaryGold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: LanguageProvider.supportedLanguages.length,
            itemBuilder: (context, index) {
              final lang = LanguageProvider.supportedLanguages[index];
              return ListTile(
                title: Text(lang['name'], style: const TextStyle(color: Colors.white)),
                subtitle: Text(lang['nativeName'], style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Provider.of<LanguageProvider>(context, listen: false)
                      .setLocale(Locale(lang['code']));
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
