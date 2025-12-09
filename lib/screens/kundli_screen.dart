import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/kundli_service.dart';
import '../logic/remedy_service.dart';
import '../logic/language_provider.dart';

class KundliScreen extends StatefulWidget {
  const KundliScreen({super.key});

  @override
  State<KundliScreen> createState() => _KundliScreenState();
}

class _KundliScreenState extends State<KundliScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  Map<String, dynamic>? chartData;
  String remedies = "";
  bool isLoading = false;

  void _calculate() async {
    setState(() => isLoading = true);

    final DateTime dt = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute,
    );

    // Hardcoded Lat/Lon for New Delhi for MVP
    final data = KundliService.calculateChart(dt, 28.6139, 77.2090);

    final lang = Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kundli")),
      body: Column(
        children: [
          ListTile(
            title: Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(1900), lastDate: DateTime.now());
              if (d != null) setState(() => selectedDate = d);
            },
          ),
          ListTile(
            title: Text("Time: ${selectedTime.format(context)}"),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: selectedTime);
              if (t != null) setState(() => selectedTime = t);
            },
          ),
          ElevatedButton(onPressed: isLoading ? null : _calculate, child: isLoading ? const CircularProgressIndicator() : const Text("Generate Kundli")),
          if (chartData != null) ...[
            Expanded(
              child: ListView(
                children: [
                  ListTile(title: Text("Lagna: ${chartData!['lagna']['rashi']} (${chartData!['lagna']['degree'].toStringAsFixed(2)}°)")),
                  ...(chartData!['planets'] as List).map((p) => ListTile(
                    title: Text("${p['name']}: ${p['rashi']} (${p['degree'].toStringAsFixed(2)}°) ${p['isRetrograde'] ? '(R)' : ''}"),
                  )).toList(),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Remedies & Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(remedies),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}
