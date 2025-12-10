import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

      // Handle Markdown Headings (#, ##, ###)
      if (line.startsWith('#')) {
        // Count hashes to determine level (though we might style them similarly)
        int hashCount = 0;
        while (hashCount < line.length && line[hashCount] == '#') {
          hashCount++;
        }

        String cleanLine = line.substring(hashCount).trim();

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              cleanLine,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('* ') || line.startsWith('- ')) {
        // List Item with Star Icon
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

  Widget _buildRichText(String text, {double fontSize = 14}) {
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
            style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.normal,
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
