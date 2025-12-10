import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AstroTextParser extends StatelessWidget {
  final String text;

  const AstroTextParser({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Split text into lines, removing carriage returns just in case
    final List<String> lines = text.replaceAll('\r', '').split('\n');
    final List<Widget> widgets = [];

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8)); // Spacing for empty lines
        continue;
      }

      if (line.startsWith('###')) {
        // Heading
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: _buildRichText(
              line.substring(3).trim(), // Remove ###
              fontSize: 18,
              isHeading: true,
            ),
          ),
        );
      } else if (line.startsWith('* ') || line.startsWith('- ')) {
        // List Item
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4.0, right: 8.0),
                  child: Icon(
                    Icons.star, // Mystical bullet point
                    size: 14,
                    color: AppColors.primaryGold,
                  ),
                ),
                Expanded(
                  child: _buildRichText(
                    line.substring(1).trim(), // Remove * or -
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Normal Paragraph
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildRichText(line),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String text, {double fontSize = 14, bool isHeading = false}) {
    // Split by double asterisks for bolding
    final List<String> parts = text.split('**');
    final List<InlineSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      final String part = parts[i];
      if (part.isEmpty) continue;

      if (i % 2 == 1) {
        // Odd indices are the text *inside* the **markers** -> BOLD & GOLD
        spans.add(
          TextSpan(
            text: part,
            style: TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              height: 1.5,
            ),
          ),
        );
      } else {
        // Even indices are normal text
        spans.add(
          TextSpan(
            text: part,
            style: TextStyle(
              // Headings are already Gold in my design?
              // The user said: "Title ko bada ho... text aesa lage real baba ne remedies likhi hai"
              // If it's a heading (###), let's make the whole thing Gold-ish or White?
              // Usually Headings are fully highlighted.
              // But if I use AppColors.primaryGold for the whole heading, the bold parts inside might blend in.
              // Let's make Heading base color Gold, and bold parts Deep Gold or White?
              // Actually, simplified: Headings -> Gold. Body -> White/Grey.
              // Bold inside Body -> Gold.
              color: isHeading ? AppColors.primaryGold : AppColors.textSecondary,
              fontWeight: isHeading ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              height: 1.5,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
