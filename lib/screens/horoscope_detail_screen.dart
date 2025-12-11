import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';

class HoroscopeDetailScreen extends StatefulWidget {
  final String signName;
  final IconData signIcon;
  final Map<String, dynamic>? data;

  const HoroscopeDetailScreen({
    super.key,
    required this.signName,
    required this.signIcon,
    this.data,
  });

  @override
  State<HoroscopeDetailScreen> createState() => _HoroscopeDetailScreenState();
}

class _HoroscopeDetailScreenState extends State<HoroscopeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cache for each tab
  Map<String, dynamic>? _dailyData;
  Map<String, dynamic>? _weeklyData;
  Map<String, dynamic>? _monthlyData;

  bool _isDailyLoading = false;
  bool _isWeeklyLoading = false;
  bool _isMonthlyLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize Daily Data (Passed or Fetch)
    if (widget.data != null) {
      _dailyData = widget.data;
    } else {
      _fetchDaily();
    }

    // Listen to tab changes to lazy load
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Tab changed
      } else {
        // Tab selection finalized
        if (_tabController.index == 1 && _weeklyData == null) _fetchWeekly();
        if (_tabController.index == 2 && _monthlyData == null) _fetchMonthly();
      }
    });
  }

  Future<void> _fetchDaily() async {
    setState(() => _isDailyLoading = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final cacheKey = 'horoscope_${lang}_${widget.signName}_daily_$dateKey';

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(cacheKey)) {
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          final data = jsonDecode(cachedJson);
          if (mounted) {
            setState(() {
              _dailyData = data;
              _isDailyLoading = false;
            });
          }
          return;
        }
      }

      final jsonStr = await AIService.getDailyHoroscope(widget.signName, now, lang);
      final data = jsonDecode(jsonStr);
      await prefs.setString(cacheKey, jsonStr);

      if (mounted) {
        setState(() {
          _dailyData = data;
          _isDailyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dailyData = _getErrorData();
          _isDailyLoading = false;
        });
      }
    }
  }

  Future<void> _fetchWeekly() async {
    if (_isWeeklyLoading) return;
    setState(() => _isWeeklyLoading = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    final now = DateTime.now();
    final weekKey = DateFormat('yyyy_w').format(now);
    final cacheKey = 'horoscope_${lang}_${widget.signName}_weekly_$weekKey';

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(cacheKey)) {
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          final data = jsonDecode(cachedJson);
          if (mounted) {
            setState(() {
              _weeklyData = data;
              _isWeeklyLoading = false;
            });
          }
          return;
        }
      }

      final jsonStr = await AIService.getWeeklyHoroscope(widget.signName, now, lang);
      final data = jsonDecode(jsonStr);
      await prefs.setString(cacheKey, jsonStr);

      if (mounted) {
        setState(() {
          _weeklyData = data;
          _isWeeklyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weeklyData = _getErrorData();
          _isWeeklyLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMonthly() async {
    if (_isMonthlyLoading) return;
    setState(() => _isMonthlyLoading = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
    final now = DateTime.now();
    final monthKey = DateFormat('yyyy_MM').format(now);
    final cacheKey = 'horoscope_${lang}_${widget.signName}_monthly_$monthKey';

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(cacheKey)) {
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          final data = jsonDecode(cachedJson);
          if (mounted) {
            setState(() {
              _monthlyData = data;
              _isMonthlyLoading = false;
            });
          }
          return;
        }
      }

      final jsonStr = await AIService.getMonthlyHoroscope(widget.signName, now, lang);
      final data = jsonDecode(jsonStr);
      await prefs.setString(cacheKey, jsonStr);

      if (mounted) {
        setState(() {
          _monthlyData = data;
          _isMonthlyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _monthlyData = _getErrorData();
          _isMonthlyLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getErrorData() {
    return {
      'summary': "Could not load forecast.",
      'love': "N/A",
      'career': "N/A",
      'health': "N/A",
      'lucky_color': "-",
      'lucky_number': "-"
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.signName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildForecastContent(_dailyData, _isDailyLoading, "Today's Forecast"),
              _buildForecastContent(_weeklyData, _isWeeklyLoading, "Weekly Forecast"),
              _buildForecastContent(_monthlyData, _isMonthlyLoading, "Monthly Forecast"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastContent(Map<String, dynamic>? data, bool isLoading, String title) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }

    if (data == null) {
      // This state might happen briefly before fetch starts or on hard error
      return const Center(child: Text("Loading...", style: TextStyle(color: Colors.white)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Icon with Glow (Reused)
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
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            data['summary'] ?? "Align with the stars.",
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
              _DetailCard(title: 'Love', icon: Icons.favorite, content: data['love'] ?? "Good", color: Colors.pinkAccent),
              _DetailCard(title: 'Career', icon: Icons.work, content: data['career'] ?? "Steady", color: Colors.blueAccent),
              _DetailCard(title: 'Health', icon: Icons.favorite_border, content: data['health'] ?? "Stable", color: Colors.greenAccent),
              _DetailCard(title: 'Luck', icon: Icons.auto_awesome, content: "Color: ${data['lucky_color'] ?? '-'}\nNum: ${data['lucky_number'] ?? '-'}", color: Colors.amberAccent),
            ],
          ),
        ],
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
