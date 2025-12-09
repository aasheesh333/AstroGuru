import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                      text: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                      onPressed: () async {
                        if (_currentPage == _slides.length - 1) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('onboarding_seen', true);
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          }
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
}
