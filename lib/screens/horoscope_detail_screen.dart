import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/astro_card.dart';

class HoroscopeDetailScreen extends StatefulWidget {
  final String signName;
  final IconData signIcon;

  const HoroscopeDetailScreen({
    super.key,
    required this.signName,
    required this.signIcon,
  });

  @override
  State<HoroscopeDetailScreen> createState() => _HoroscopeDetailScreenState();
}

class _HoroscopeDetailScreenState extends State<HoroscopeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.signName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailView('Daily'),
          _buildDetailView('Weekly'),
          _buildDetailView('Monthly'),
        ],
      ),
    );
  }

  Widget _buildDetailView(String period) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceColor,
                border: Border.all(color: AppColors.primaryGold),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(widget.signIcon, size: 48, color: AppColors.primaryGold),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Your $period Forecast',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          Text(
            'Today brings a wave of creative energy. You might feel inspired to start a new project or reconnect with an old hobby. Trust your intuition.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),

          // Details Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: const [
              _DetailCard(title: 'Love', icon: Icons.favorite, value: 'High', color: Colors.pinkAccent),
              _DetailCard(title: 'Career', icon: Icons.work, value: 'Moderate', color: Colors.blueAccent),
              _DetailCard(title: 'Health', icon: Icons.favorite_border, value: 'Good', color: Colors.greenAccent),
              _DetailCard(title: 'Money', icon: Icons.attach_money, value: 'Stable', color: Colors.amberAccent),
            ],
          ),
          const SizedBox(height: 24),

          // Lucky Section
          AstroCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLuckyItem('Lucky Color', 'Gold', Icons.color_lens),
                _buildLuckyItem('Lucky Number', '7', Icons.format_list_numbered),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primaryGold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceColor.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
