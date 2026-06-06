/// Builds a compact, AI-friendly narrative of a user's kundli chart so that
/// downstream prompts (daily horoscope, chat, remedies, etc.) have real
/// personal context to draw from.
///
/// The output is a deterministic multi-line string. It contains:
///
/// * Birth date, time, place (when available)
/// * Lagna (ascendant) sign in human-readable form
/// * Moon sign and Sun sign in human-readable form
/// * Nakshatra + pada (when present and > 0)
/// * Detected doshas (omitted if the list is empty)
///
/// Raw rashi ids (1..12) are translated to English sign names; this string
/// is meant to be embedded directly into a system or user prompt.
class KundliContextBuilder {
  static const List<String> _rashiNames = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  /// Returns the rashi (zodiac sign) name for a 1-based rashi id, or
  /// `null` when the id is out of range.
  static String? rashiNameFor(int? rashi) {
    if (rashi == null || rashi < 1 || rashi > 12) return null;
    return _rashiNames[rashi - 1];
  }

  /// Builds the context string. Returns the empty string when the chart is
  /// missing or has no lagna/planets — callers can check `.isNotEmpty` to
  /// decide whether to inject the context into a prompt.
  static String build({
    required Map<String, dynamic>? chart,
    DateTime? birthDate,
    String? birthTime,
    String? birthPlace,
  }) {
    if (chart == null) return '';
    final lagna = chart['lagna'] as Map?;
    final planetsRaw = chart['planets'];
    if (lagna == null || planetsRaw is! List || planetsRaw.isEmpty) return '';

    final sb = StringBuffer();
    sb.writeln('User birth details:');

    final dateStr = _formatDate(birthDate);
    if (dateStr != null) sb.writeln('- Date: $dateStr');
    final time = birthTime?.trim() ?? '';
    if (time.isNotEmpty) sb.writeln('- Time: $time');
    final place = birthPlace?.trim() ?? '';
    if (place.isNotEmpty) sb.writeln('- Place: $place');

    final lagnaName = rashiNameFor(lagna['rashi'] as int?);
    if (lagnaName != null) sb.writeln('- Lagna (Ascendant): $lagnaName');

    String? moonName;
    String? sunName;
    for (final p in planetsRaw) {
      if (p is! Map) continue;
      final name = p['name'];
      if (name == 'Moon') {
        moonName = rashiNameFor(p['rashi'] as int?);
      } else if (name == 'Sun') {
        sunName = rashiNameFor(p['rashi'] as int?);
      }
    }
    if (moonName != null) sb.writeln('- Moon Sign: $moonName');
    if (sunName != null) sb.writeln('- Sun Sign: $sunName');

    final nakshatra = chart['nakshatra'] as int?;
    final pada = chart['pada'] as int?;
    if (nakshatra != null && nakshatra > 0 && pada != null && pada > 0) {
      sb.writeln('- Nakshatra: $nakshatra, Pada $pada');
    }

    final doshas = chart['doshas'];
    if (doshas is List && doshas.isNotEmpty) {
      sb.writeln('- Detected doshas: ${doshas.join(', ')}');
    }

    final out = sb.toString().trimRight();
    return out;
  }

  static String? _formatDate(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
