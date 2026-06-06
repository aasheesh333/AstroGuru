import 'recent_mentions.dart';

/// Builds the full AI context block (identity + kundli + recent mentions)
/// that the AI Sage embeds in its system prompt.
///
/// All fields are optional; empty / null values are omitted so the
/// resulting string stays tight. Location comes from `RecentMentions`
/// (i.e. the chat), not from a profile field.
class UserContextBuilder {
  static String build({
    required String name,
    required String email,
    required String zodiac,
    required String kundliContext,
    required String gender,
    required String profession,
    required String maritalStatus,
    required RecentMentions recent,
  }) {
    final sb = StringBuffer();
    sb.writeln('User profile:');
    if (name.trim().isNotEmpty) sb.writeln('- Name: ${name.trim()}');
    if (email.trim().isNotEmpty) sb.writeln('- Email: ${email.trim()}');
    if (gender.trim().isNotEmpty) sb.writeln('- Gender: ${_humanize(gender)}');
    if (profession.trim().isNotEmpty) sb.writeln('- Profession: ${profession.trim()}');
    if (maritalStatus.trim().isNotEmpty) sb.writeln('- Marital Status: ${_humanize(maritalStatus)}');
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

  /// Translates enum keys ("male", "in_relationship") to display strings.
  static String _humanize(String key) {
    switch (key) {
      case 'male': return 'Male';
      case 'female': return 'Female';
      case 'other': return 'Other';
      case 'prefer_not_to_say': return 'Prefer not to say';
      case 'single': return 'Single';
      case 'married': return 'Married';
      case 'in_relationship': return 'In a relationship';
      case 'divorced': return 'Divorced';
      case 'widowed': return 'Widowed';
      default: return key;
    }
  }
}
