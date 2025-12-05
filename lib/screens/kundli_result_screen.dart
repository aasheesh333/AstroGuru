import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/astro_card.dart';

class KundliResultScreen extends StatefulWidget {
  const KundliResultScreen({super.key});

  @override
  State<KundliResultScreen> createState() => _KundliResultScreenState();
}

class _KundliResultScreenState extends State<KundliResultScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Your Kundli'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Planets'),
            Tab(text: 'Dasha'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChartTab(),
          _buildPlanetsTab(),
          _buildDashaTab(),
        ],
      ),
    );
  }

  Widget _buildChartTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Lagna Chart',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryGold, width: 2),
                color: AppColors.surfaceColor,
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: _KundliChartPainter(),
                  ),
                  // Dummy Planets
                  const Positioned(top: 20, left: 140, child: Text("Su", style: TextStyle(color: Colors.red))),
                  const Positioned(bottom: 20, left: 140, child: Text("Mo", style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const AstroCard(
              child: Text(
                'Ascendant is Leo. Sun is placed in the 1st House.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanetsTab() {
    final planets = [
      {'name': 'Sun', 'sign': 'Leo', 'degree': '12° 30\''},
      {'name': 'Moon', 'sign': 'Aries', 'degree': '05° 15\''},
      {'name': 'Mars', 'sign': 'Gemini', 'degree': '22° 10\''},
      {'name': 'Mercury', 'sign': 'Cancer', 'degree': '18° 45\''},
      {'name': 'Jupiter', 'sign': 'Pisces', 'degree': '09° 00\''},
      {'name': 'Venus', 'sign': 'Libra', 'degree': '14° 20\''},
      {'name': 'Saturn', 'sign': 'Capricorn', 'degree': '02° 50\''},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: planets.length,
      itemBuilder: (context, index) {
        final planet = planets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceColor,
              child: Text(
                planet['name']![0],
                style: const TextStyle(color: AppColors.primaryGold),
              ),
            ),
            title: Text(planet['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Sign: ${planet['sign']}"),
            trailing: Text(planet['degree']!, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        );
      },
    );
  }

  Widget _buildDashaTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
         AstroCard(
           child: ListTile(
             title: Text('Vimshottari Dasha'),
             subtitle: Text('Current: Jupiter - Saturn'),
             trailing: Text('Until 2026'),
           ),
         ),
         SizedBox(height: 16),
         ListTile(
           title: Text('Jupiter Mahadasha'),
           subtitle: Text('2018 - 2034'),
           trailing: Icon(Icons.arrow_forward_ios, size: 16),
         ),
         Divider(color: AppColors.textSecondary),
         ListTile(
           title: Text('Saturn Antardasha'),
           subtitle: Text('2024 - 2026'),
           trailing: Icon(Icons.arrow_forward_ios, size: 16),
         ),
      ],
    );
  }
}

class _KundliChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGold.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw Cross
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Draw Diamond
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
