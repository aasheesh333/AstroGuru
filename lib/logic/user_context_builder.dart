import 'recent_mentions.dart';

/// Builds the full AI context block (identity + location + kundli +
/// recent mentions) that the AI Sage embeds in its system prompt.
///
/// All fields are optional; empty / null values are omitted so the
/// resulting string stays tight.
class UserContextBuilder {
  static String build({
    required String name,
    required String email,
    required String address,
    required String zodiac,
    required String kundliContext,
    required RecentMentions recent,
  }) {
    final sb = StringBuffer();
    sb.writeln('User profile:');
    if (name.trim().isNotEmpty) sb.writeln('- Name: ${name.trim()}');
    if (email.trim().isNotEmpty) sb.writeln('- Email: ${email.trim()}');
    if (address.trim().isNotEmpty) {
      sb.writeln('- Current Address: ${address.trim()}');
    }
    if (zodiac.trim().isNotEmpty) sb.writeln('- Zodiac: ${zodiac.trim()}');
    if (kundliContext.trim().isNotEmpty) {
      sb.writeln(kundliContext.trim());
    }

    if (!recent.isEmpty) {
      sb.writeln('');
      sb.writeln('Recent mentions in this conversation:');
      if (recent.place != null) sb.writeln('- Place: ${recent.place}');
      if (recent.date != null) sb.writeln('- Date: ${recent.date}');
      if (recent.time != null) sb.writeln('- Time: ${recent.time}');
    }

    return sb.toString().trimRight();
  }
}
