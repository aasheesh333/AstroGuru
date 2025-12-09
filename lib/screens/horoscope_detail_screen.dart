import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';

class HoroscopeDetailScreen extends StatefulWidget {
  final String signName;
  final IconData signIcon;
  final Map<String, dynamic>? data; // Made optional

  const HoroscopeDetailScreen({
    super.key,
    required this.signName,
    required this.signIcon,
    this.data,
  });

  @override
  State<HoroscopeDetailScreen> createState() => _HoroscopeDetailScreenState();
}

class _HoroscopeDetailScreenState extends State<HoroscopeDetailScreen> {
  late Map<String, dynamic> _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _data = widget.data!;
    } else {
      _data = {};
      _fetchData();
    }
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    try {
      final jsonStr = await AIService.getDailyHoroscope(widget.signName, DateTime.now(), lang);
      final data = jsonDecode(jsonStr);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _data = {
            'summary': "Could not load forecast.",
            'love': "N/A",
            'career': "N/A",
            'health': "N/A",
            'lucky_color': "-",
            'lucky_number': "-"
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.signName), backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.signName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
               Expanded(
                 child: SingleChildScrollView(
                   padding: const EdgeInsets.all(16),
                   child: Column(
                     children: [
                       // Header Icon with Glow
                       Container(
                         padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           color: AppColors.surfaceColor.withOpacity(0.5),
                           border: Border.all(color: AppColors.primaryGold, width: 2),
                           boxShadow: [
                             BoxShadow(
                               color: AppColors.primaryGold.withOpacity(0.3),
                               blurRadius: 30,
                               spreadRadius: 5,
                             ),
                           ],
                         ),
                         child: Icon(widget.signIcon, size: 60, color: AppColors.primaryGold),
                       ),
                       const SizedBox(height: 30),

                       // Summary Section
                       Text(
                         "Today's Forecast",
                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 12),
                       Text(
                         _data['summary'] ?? "Align with the stars today.",
                         textAlign: TextAlign.center,
                         style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                           height: 1.6,
                           color: Colors.white.withOpacity(0.9)
                         ),
                       ),
                       const SizedBox(height: 30),

                       // Metrics Grid
                       GridView.count(
                         shrinkWrap: true,
                         physics: const NeverScrollableScrollPhysics(),
                         crossAxisCount: 2,
                         crossAxisSpacing: 16,
                         mainAxisSpacing: 16,
                         childAspectRatio: 1.3,
                         children: [
                           _DetailCard(title: 'Love', icon: Icons.favorite, content: _data['love'] ?? "Good", color: Colors.pinkAccent),
                           _DetailCard(title: 'Career', icon: Icons.work, content: _data['career'] ?? "Steady", color: Colors.blueAccent),
                           _DetailCard(title: 'Health', icon: Icons.favorite_border, content: _data['health'] ?? "Stable", color: Colors.greenAccent),
                           _DetailCard(title: 'Luck', icon: Icons.auto_awesome, content: "Color: ${_data['lucky_color'] ?? '-'}\nNum: ${_data['lucky_number'] ?? '-'}", color: Colors.amberAccent),
                         ],
                       ),
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
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _DetailCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0E1016),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primaryGold, width: 1),
            ),
            title: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: AppColors.primaryGold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: AppColors.primaryGold)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const Spacer(),
            Text(
              content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
