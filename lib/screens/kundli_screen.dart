import 'package:flutter/material.dart';
import '../logic/kundli_service.dart';

class KundliScreen extends StatefulWidget {
  const KundliScreen({super.key});

  @override
  State<KundliScreen> createState() => _KundliScreenState();
}

class _KundliScreenState extends State<KundliScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  Map<String, dynamic>? chartData;

  void _calculate() {
    final DateTime dt = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute,
    );
    // Hardcoded Lat/Lon for New Delhi for MVP
    setState(() {
      chartData = KundliService.calculateChart(dt, 28.6139, 77.2090);
    });
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
          ElevatedButton(onPressed: _calculate, child: const Text("Generate Kundli")),
          if (chartData != null) ...[
            Expanded(
              child: ListView(
                children: [
                  ListTile(title: Text("Lagna: ${chartData!['lagna']['rashi']} (${chartData!['lagna']['degree'].toStringAsFixed(2)}°)")),
                  ...(chartData!['planets'] as List).map((p) => ListTile(
                    title: Text("${p['name']}: ${p['rashi']} (${p['degree'].toStringAsFixed(2)}°) ${p['isRetrograde'] ? '(R)' : ''}"),
                  )).toList(),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}
