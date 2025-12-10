import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/astro_card.dart';
import '../widgets/astro_text_parser.dart';
import '../logic/kundli_service.dart';
import '../logic/remedy_service.dart';
import '../logic/language_provider.dart';

class KundliResultScreen extends StatefulWidget {
  final String name;
  final DateTime? date; // Changed to nullable
  final TimeOfDay? time; // Changed to nullable
  final String place;

  const KundliResultScreen({
    super.key,
    this.name = "User", // Default for testing if pushed without args
    this.date,
    this.time,
    this.place = "Unknown"
  });

  @override
  State<KundliResultScreen> createState() => _KundliResultScreenState();
}

class _KundliResultScreenState extends State<KundliResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? chartData;
  String remedies = "Loading remedies...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateChart();
  }

  void _calculateChart() async {
    // Handle defaults inside method
    final d = widget.date ?? DateTime.now();
    final t = widget.time ?? TimeOfDay.now();

    // Combine Date and Time
    final DateTime dt = DateTime(
      d.year, d.month, d.day,
      t.hour, t.minute,
    );

    // Lat/Lon logic would go here (Geocoding).
    // For MVP, using default New Delhi coordinates as placeholder or mock.
    // In a real app, we'd use a Geocoding package to convert widget.place to lat/lon.
    double lat = 28.6139;
    double lon = 77.2090;

    final data = KundliService.calculateChart(dt, lat, lon);

    // Fetch Remedies
    String lang = "en";
    if (mounted) {
       lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    }

    final rem = await RemedyService.getRemedies(
      List<String>.from(data['doshas']),
      data['summary'],
      lang
    );

    if (mounted) {
      setState(() {
        chartData = data;
        remedies = rem;
        isLoading = false;
      });
    }
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
        title: Text('${widget.name}\'s Kundli'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Planets'),
            Tab(text: 'Remedies'), // Changed Dasha to Remedies for better utility
          ],
        ),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildChartTab(),
              _buildPlanetsTab(),
              _buildRemediesTab(),
            ],
          ),
    );
  }

  Widget _buildChartTab() {
    if (chartData == null) return const Center(child: Text("Error loading chart"));

    final lagna = chartData!['lagna'];
    final planets = chartData!['planets'] as List;
    final sun = planets.firstWhere((p) => p['name'] == 'Sun');
    final moon = planets.firstWhere((p) => p['name'] == 'Moon');

    return Center(
      child: SingleChildScrollView(
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
                    // Simplified: Just showing Text of Ascendant
                    Center(child: Text("Asc: ${lagna['rashi']}", style: const TextStyle(color: AppColors.primaryGold, fontSize: 24))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AstroCard(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: 'Inter' // Assuming generic sans-serif available
                    ),
                    children: [
                      // Ascendant Line
                      const TextSpan(
                        text: 'Ascendant (Lagna)',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' is in '),
                      TextSpan(
                        text: 'Rashi ${lagna['rashi']}',
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: '.\n'),

                      // Sun Line
                      const TextSpan(
                        text: 'Sun',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' is in '),
                      TextSpan(
                        text: 'Rashi ${sun['rashi']}',
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: '.\n'),

                      // Moon Line
                      const TextSpan(
                        text: 'Moon',
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' is in '),
                      TextSpan(
                        text: 'Rashi ${moon['rashi']}',
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanetsTab() {
    if (chartData == null) return const SizedBox();
    final planets = chartData!['planets'] as List;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: planets.length,
      itemBuilder: (context, index) {
        final planet = planets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.surfaceColor,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.scaffoldBackgroundColor, // Replaced background with scaffoldBackgroundColor
              child: Text(
                planet['name'][0],
                style: const TextStyle(color: AppColors.primaryGold),
              ),
            ),
            title: Text(planet['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text("Rashi: ${planet['rashi']}  |  ${planet['isRetrograde'] ? 'Retrograde' : 'Direct'}", style: const TextStyle(color: Colors.grey)),
            trailing: Text("${planet['degree'].toStringAsFixed(2)}°", style: const TextStyle(color: AppColors.textSecondary)),
          ),
        );
      },
    );
  }

  Widget _buildRemediesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const AstroCard(
             child: ListTile(
               leading: Icon(Icons.healing, color: AppColors.primaryGold),
               title: Text('Dosha Analysis & Remedies', style: TextStyle(color: Colors.white)),
               subtitle: Text('Based on your chart positions.', style: TextStyle(color: Colors.grey)),
             ),
           ),
           const SizedBox(height: 16),
           AstroTextParser(text: remedies),
        ],
      ),
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
