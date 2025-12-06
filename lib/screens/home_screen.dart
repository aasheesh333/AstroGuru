import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/astro_card.dart';
import '../widgets/baba_avatar.dart';
import '../widgets/gradient_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AstroPrerna'),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: BabaAvatar(size: 32),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Namaste, User!',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'What do the stars have for you today?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Daily Horoscope Preview
            AstroCard(
              onTap: () {
                // Navigate to details
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Horoscope',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryGold),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(Icons.balance, color: AppColors.primaryGold, size: 32), // Libra icon placeholder
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Libra',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Today is a day of balance. Focus on your inner peace...',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ask AI Sage Button
            GradientButton(
              text: 'Ask AI Sage',
              onPressed: () {
                // Navigate to Chat
              },
            ),
            const SizedBox(height: 24),

            // Grid Actions
            Row(
              children: [
                Expanded(
                  child: AstroCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.accentTeal, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Generate Kundli',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AstroCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.favorite, color: Colors.pinkAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Love Match',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Daily Quote
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 gradient: AppColors.mainGradient,
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Row(
                 children: [
                   const Icon(Icons.format_quote, color: AppColors.primaryGold, size: 40),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text(
                       '"The stars incline, but do not bind."',
                       style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                         fontStyle: FontStyle.italic,
                       ),
                     ),
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }
}
