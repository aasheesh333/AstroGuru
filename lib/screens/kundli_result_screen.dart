import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/astro_card.dart';
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

    // Generate a unique ID based on input to cache the AI result
    // Using a simple composed string to avoid 'crypto' import if not strictly needed,
    // but MD5 is better for file system safety. Assuming clean chars for prefs key is fine.
    // Format: "Name_Day-Month-Year_Hour-Minute_Place"
    final String uniqueId = "${widget.name}_${d.day}-${d.month}-${d.year}_${t.hour}-${t.minute}_${widget.place}".replaceAll(RegExp(r'\s+'), '');

    final rem = await RemedyService.getRemedies(
      List<String>.from(data['doshas']),
      data['summary'],
      lang,
      birthDetailsKey: uniqueId, // Pass the key for caching
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

  String _getRashiName(int id) {
    const names = [
      'Aries (Mesh)', 'Taurus (Vrishabha)', 'Gemini (Mithuna)', 'Cancer (Karka)',
      'Leo (Simha)', 'Virgo (Kanya)', 'Libra (Tula)', 'Scorpio (Vrishchika)',
      'Sagittarius (Dhanu)', 'Capricorn (Makara)', 'Aquarius (Kumbha)', 'Pisces (Meena)'
    ];
    if (id < 1 || id > 12) return 'Unknown';
    return names[id - 1];
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

    String ascName = _getRashiName(lagna['rashi']);
    String sunName = _getRashiName(sun['rashi']);
    String moonName = _getRashiName(moon['rashi']);

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
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontFamily: 'Inter'),
                    children: [
                      const TextSpan(text: "Your Ascendant (Lagna) is in "),
                      TextSpan(text: ascName, style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                      const TextSpan(text: ".\nThe Sun is positioned in "),
                      TextSpan(text: sunName, style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                      const TextSpan(text: ", and the Moon is in "),
                      TextSpan(text: moonName, style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                      const TextSpan(text: "."),
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
           _buildFormattedRemedies(remedies),
        ],
      ),
    );
  }

  Widget _buildFormattedRemedies(String text) {
    List<Widget> children = [];
    List<String> lines = text.split('\n');

    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('###')) {
        // Title
        String title = trimmed.replaceAll('#', '').trim();
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- **') || trimmed.startsWith('**')) {
        // Bold Key with Value or just Bold
        // Format: "- **Key**: Value" or "**Key**: Value"
        // Remove markdown chars
        String content = trimmed;
        if (content.startsWith('- ')) content = content.substring(2);

        List<String> parts = content.split('**:');
        if (parts.length >= 2) {
            String key = parts[0].replaceAll('*', '').trim();
            // Rejoin the rest just in case
            String value = parts.sublist(1).join('**:').trim();
             children.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 16, fontFamily: 'Inter'),
                    children: [
                      TextSpan(text: "• $key: ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                      TextSpan(text: value),
                    ],
                  ),
                ),
              ),
            );
        } else {
            // Just bold text maybe?
             children.add(Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Text(
                  content.replaceAll('*', ''),
                  style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.bold)
                ),
             ));
        }
      } else if (trimmed.startsWith('- ')) {
         // Bullet point
         children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: AppColors.primaryGold, fontSize: 16)),
                Expanded(
                  child: Text(
                    trimmed.substring(2).replaceAll('*', '').replaceAll('#', ''),
                    style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15, fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Regular text
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              trimmed.replaceAll('*', '').replaceAll('#', ''), // Cleanup
              style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15, fontFamily: 'Inter'),
            ),
          ),
        );
      }
    }
    // Add bottom padding
    children.add(const SizedBox(height: 40));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
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
