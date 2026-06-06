/// Scans user messages for date / time / place mentions and returns the
/// most recent of each. Used to enrich the AI Sage prompt with facts the
/// user has stated mid-conversation (e.g. "I live in Mumbai" sticks for
/// the rest of the chat).
class RecentMentions {
  final String? place;
  final String? date;
  final String? time;

  const RecentMentions({this.place, this.date, this.time});

  bool get isEmpty => place == null && date == null && time == null;

  /// Scans every user message in [history] (not just the latest few), so
  /// once the user mentions a place it stays in context for the rest of
  /// the conversation. [history] entries must have `role` and `content`
  /// keys. Keeps the last user mention of each kind.
  static RecentMentions extract(List<Map<String, String>> history) {
    String? place;
    String? date;
    String? time;

    for (final m in history) {
      if (m['role'] != 'user') continue;
      final text = m['content'] ?? '';
      final p = _matchPlace(text);
      if (p != null) place = p;
      final d = _matchDate(text);
      if (d != null) date = d;
      final t = _matchTime(text);
      if (t != null) time = t;
    }

    return RecentMentions(place: place, date: date, time: time);
  }

  // --- regex helpers -----------------------------------------------------

  static final _placeRe = RegExp(
    r'\b(?:in|at|from|to)\s+([A-Z][A-Za-z]+(?:\s[A-Z][A-Za-z]+){0,3})',
  );

  static final _dateRe = RegExp(
    r'\b(\d{1,2}(?:\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*'
    r'(?:\s+\d{2,4})?))'
    r'|\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*'
    r'\s+\d{1,2}(?:,?\s+\d{4})?)',
    caseSensitive: false,
  );

  static final _timeRe = RegExp(
    r'\b(\d{1,2}(?::\d{2})?\s*(?:am|pm|AM|PM))'
    r'|\b(\d{1,2}:\d{2})',
  );

  static String? _matchPlace(String text) {
    final m = _placeRe.firstMatch(text);
    if (m == null) return null;
    return m.group(1);
  }

  static String? _matchDate(String text) {
    final m = _dateRe.firstMatch(text);
    if (m == null) return null;
    return m.group(1) ?? m.group(2);
  }

  static String? _matchTime(String text) {
    final m = _timeRe.firstMatch(text);
    if (m == null) return null;
    return m.group(1) ?? m.group(2);
  }
}
