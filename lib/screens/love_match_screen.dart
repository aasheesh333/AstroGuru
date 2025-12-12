import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/language_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../utils/validators.dart';
import '../logic/love_match_logic.dart';

class LoveMatchScreen extends StatefulWidget {
  const LoveMatchScreen({super.key});

  @override
  State<LoveMatchScreen> createState() => _LoveMatchScreenState();
}

class _LoveMatchScreenState extends State<LoveMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name1Controller = TextEditingController();
  final TextEditingController _name2Controller = TextEditingController();
  String _sign1 = "Aries";
  String _sign2 = "Aries";
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  final List<String> _zodiacSigns = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
  ];

  void _analyze() async {
    if (!_formKey.currentState!.validate()) {
       return;
    }

    final name1 = _name1Controller.text.trim();
    final name2 = _name2Controller.text.trim();

    setState(() => _isLoading = true);

    try {
      final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;

      // Calculate local score
      final int matchScore = LoveMatchLogic.calculate(name1, _sign1, name2, _sign2);

      // Generate a simple cache key
      final cacheKey = "love_match_${lang}_${name1.toLowerCase()}_${_sign1}_${name2.toLowerCase()}_${_sign2}";
      final prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey(cacheKey)) {
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          final data = jsonDecode(cachedJson);
          // Only use cache if the score roughly matches (or just trust cache)
          if (mounted) {
            setState(() {
              _result = data;
              _isLoading = false;
            });
          }
          return;
        }
      }

      final response = await AIService.getLoveMatch(
        name1,
        _sign1,
        name2,
        _sign2,
        lang,
        forcedScore: matchScore,
      );

      final data = jsonDecode(response);
      // Ensure the displayed score matches our calculation if AI didn't respect it perfectly (fallback)
      data['score'] = matchScore;

      await prefs.setString(cacheKey, jsonEncode(data));

      if (mounted) {
        setState(() {
          _result = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analysis failed. Please try again.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Love Compatibility"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_result == null) ...[
                  _buildInputCard("You", _name1Controller, (val) => setState(() => _sign1 = val), _sign1),
                  const SizedBox(height: 24),
                  const Icon(Icons.favorite, color: Colors.pinkAccent, size: 40),
                  const SizedBox(height: 24),
                  _buildInputCard("Partner", _name2Controller, (val) => setState(() => _sign2 = val), _sign2),
                  const SizedBox(height: 40),
                  GradientButton(
                    text: "Analyze Match",
                    isLoading: _isLoading,
                    onPressed: _analyze,
                  ),
                ] else
                  _buildResultView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(String title, TextEditingController controller, Function(String) onSignChanged, String currentSign) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            validator: AppValidators.validateName,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter Name",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              errorStyle: const TextStyle(color: Colors.redAccent),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentSign,
                isExpanded: true,
                dropdownColor: AppColors.surfaceColor,
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGold),
                items: _zodiacSigns.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) onSignChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    int score = _result!['score'] ?? 0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceColor,
            border: Border.all(color: score > 80 ? Colors.green : (score > 50 ? AppColors.primaryGold : Colors.red), width: 4),
            boxShadow: [
              BoxShadow(
                color: (score > 80 ? Colors.green : (score > 50 ? AppColors.primaryGold : Colors.red)).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ]
          ),
          child: Column(
            children: [
              Text("$score%", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text("Match", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _result!['summary'] ?? "",
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.primaryGold, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _result!['detailed_analysis'] ?? "",
            style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 16),
          ),
        ),
        const SizedBox(height: 32),
        GradientButton(
          text: "Analyze Another",
          onPressed: () => setState(() {
            _result = null;
            _name1Controller.clear();
            _name2Controller.clear();
          }),
        )
      ],
    );
  }
}
