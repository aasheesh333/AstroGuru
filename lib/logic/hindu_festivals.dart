class HinduFestival {
  final String name;
  final int month;
  final int day;
  final int hour;
  final String title;
  final String body;

  const HinduFestival({
    required this.name,
    required this.month,
    required this.day,
    required this.hour,
    required this.title,
    required this.body,
  });

  DateTime dateIn(int year) => DateTime(year, month, day, hour);
}

class HinduFestivals {
  static const List<HinduFestival> _all = [
    HinduFestival(
      name: 'Republic Day',
      month: 1, day: 26, hour: 9,
      title: '🇮🇳 AstroPrerna Insight',
      body: 'Republic Day — salute the spirit of India and the Constitution that binds us.',
    ),
    HinduFestival(
      name: 'Maha Shivaratri',
      month: 2, day: 15, hour: 6,
      title: '🔱 AstroPrerna Insight',
      body: 'Maha Shivaratri — invoke the blessings of Lord Shiva for inner peace.',
    ),
    HinduFestival(
      name: 'Holi',
      month: 3, day: 4, hour: 10,
      title: '🎨 AstroPrerna Insight',
      body: 'Happy Holi — celebrate the colors of life, love and the triumph of good over evil!',
    ),
    HinduFestival(
      name: 'Chaitra Navratri',
      month: 3, day: 19, hour: 6,
      title: '🌸 AstroPrerna Insight',
      body: 'Chaitra Navratri begins — nine nights of devotion to Maa Durga.',
    ),
    HinduFestival(
      name: 'Ram Navami',
      month: 3, day: 26, hour: 10,
      title: '🙏 AstroPrerna Insight',
      body: 'Ram Navami — celebrate the birth of Lord Rama and the ideals he stood for.',
    ),
    HinduFestival(
      name: 'Janmashtami',
      month: 8, day: 15, hour: 6,
      title: '🪈 AstroPrerna Insight',
      body: 'Janmashtami — celebrate the birth of Lord Krishna with devotion and joy.',
    ),
    HinduFestival(
      name: 'Ganesh Chaturthi',
      month: 8, day: 27, hour: 10,
      title: '🐘 AstroPrerna Insight',
      body: 'Ganesh Chaturthi — welcome Bappa home for ten days of blessings!',
    ),
    HinduFestival(
      name: 'Sharad Navratri',
      month: 10, day: 11, hour: 6,
      title: '🪔 AstroPrerna Insight',
      body: 'Sharad Navratri begins — nine nights of devotion, dance and the Divine Mother.',
    ),
    HinduFestival(
      name: 'Dussehra',
      month: 10, day: 20, hour: 10,
      title: '🏹 AstroPrerna Insight',
      body: 'Vijayadashami — victory of good over evil, of light over darkness.',
    ),
    HinduFestival(
      name: 'Karva Chauth',
      month: 11, day: 1, hour: 9,
      title: '🌙 AstroPrerna Insight',
      body: 'Karva Chauth — a sacred fast for the bond of love and lifelong partnership.',
    ),
    HinduFestival(
      name: 'Diwali',
      month: 11, day: 8, hour: 19,
      title: '🪔 AstroPrerna Insight',
      body: 'Happy Diwali! May the lamp of knowledge and prosperity light your path.',
    ),
    HinduFestival(
      name: 'Govardhan Puja',
      month: 11, day: 9, hour: 10,
      title: '🪔 AstroPrerna Insight',
      body: 'Govardhan Puja — honor Lord Krishna for lifting the mountain and protecting nature.',
    ),
    HinduFestival(
      name: 'Bhai Dooj',
      month: 11, day: 10, hour: 10,
      title: '🤝 AstroPrerna Insight',
      body: 'Bhai Dooj — celebrate the unbreakable bond between siblings.',
    ),
    HinduFestival(
      name: 'Chhath Puja',
      month: 11, day: 18, hour: 6,
      title: '🌅 AstroPrerna Insight',
      body: 'Chhath Puja — offer arghya to Surya Dev and Chhathi Maiya for wellbeing.',
    ),
    HinduFestival(
      name: 'Guru Nanak Jayanti',
      month: 11, day: 24, hour: 6,
      title: '🙏 AstroPrerna Insight',
      body: 'Guru Nanak Jayanti — celebrate the birth of Guru Nanak Dev Ji and his message of equality.',
    ),
    HinduFestival(
      name: 'Christmas',
      month: 12, day: 25, hour: 9,
      title: '🎄 AstroPrerna Insight',
      body: 'Merry Christmas — peace, love and goodwill to all.',
    ),
    HinduFestival(
      name: 'Makar Sankranti',
      month: 1, day: 14, hour: 10,
      title: '🪁 AstroPrerna Insight',
      body: 'Makar Sankranti — celebrate the harvest and the sun\'s journey northward.',
    ),
    HinduFestival(
      name: 'Maha Shivaratri 2027',
      month: 2, day: 6, hour: 6,
      title: '🔱 AstroPrerna Insight',
      body: 'Maha Shivaratri — invoke the blessings of Lord Shiva for inner peace.',
    ),
    HinduFestival(
      name: 'Holi 2027',
      month: 3, day: 22, hour: 10,
      title: '🎨 AstroPrerna Insight',
      body: 'Happy Holi — splash the colors of love, joy and the triumph of good!',
    ),
    HinduFestival(
      name: 'Chaitra Navratri 2027',
      month: 4, day: 7, hour: 6,
      title: '🌸 AstroPrerna Insight',
      body: 'Chaitra Navratri begins — nine nights of devotion to Maa Durga.',
    ),
    HinduFestival(
      name: 'Ram Navami 2027',
      month: 4, day: 15, hour: 10,
      title: '🙏 AstroPrerna Insight',
      body: 'Ram Navami — celebrate the birth of Lord Rama and the ideals he stood for.',
    ),
    HinduFestival(
      name: 'Janmashtami 2027',
      month: 8, day: 4, hour: 6,
      title: '🪈 AstroPrerna Insight',
      body: 'Janmashtami — celebrate the birth of Lord Krishna with devotion and joy.',
    ),
    HinduFestival(
      name: 'Ganesh Chaturthi 2027',
      month: 8, day: 16, hour: 10,
      title: '🐘 AstroPrerna Insight',
      body: 'Ganesh Chaturthi — welcome Bappa home for ten days of blessings!',
    ),
    HinduFestival(
      name: 'Sharad Navratri 2027',
      month: 9, day: 30, hour: 6,
      title: '🪔 AstroPrerna Insight',
      body: 'Sharad Navratri begins — nine nights of devotion, dance and the Divine Mother.',
    ),
    HinduFestival(
      name: 'Dussehra 2027',
      month: 10, day: 9, hour: 10,
      title: '🏹 AstroPrerna Insight',
      body: 'Vijayadashami — victory of good over evil, of light over darkness.',
    ),
    HinduFestival(
      name: 'Karva Chauth 2027',
      month: 10, day: 21, hour: 9,
      title: '🌙 AstroPrerna Insight',
      body: 'Karva Chauth — a sacred fast for the bond of love and lifelong partnership.',
    ),
    HinduFestival(
      name: 'Diwali 2027',
      month: 10, day: 28, hour: 19,
      title: '🪔 AstroPrerna Insight',
      body: 'Happy Diwali! May the lamp of knowledge and prosperity light your path.',
    ),
    HinduFestival(
      name: 'Govardhan Puja 2027',
      month: 10, day: 29, hour: 10,
      title: '🪔 AstroPrerna Insight',
      body: 'Govardhan Puja — honor Lord Krishna for lifting the mountain and protecting nature.',
    ),
    HinduFestival(
      name: 'Bhai Dooj 2027',
      month: 10, day: 30, hour: 10,
      title: '🤝 AstroPrerna Insight',
      body: 'Bhai Dooj — celebrate the unbreakable bond between siblings.',
    ),
    HinduFestival(
      name: 'Chhath Puja 2027',
      month: 11, day: 7, hour: 6,
      title: '🌅 AstroPrerna Insight',
      body: 'Chhath Puja — offer arghya to Surya Dev and Chhathi Maiya for wellbeing.',
    ),
    HinduFestival(
      name: 'Guru Nanak Jayanti 2027',
      month: 11, day: 13, hour: 6,
      title: '🙏 AstroPrerna Insight',
      body: 'Guru Nanak Jayanti — celebrate the birth of Guru Nanak Dev Ji and his message of equality.',
    ),
  ];

  static List<({HinduFestival festival, DateTime date})> upcomingFrom(
    DateTime from, {
    int days = 14,
  }) {
    final result = <({HinduFestival festival, DateTime date})>[];
    for (final f in _all) {
      for (int y in [from.year, from.year + 1]) {
        final d = f.dateIn(y);
        if (!d.isBefore(from) && d.isBefore(from.add(Duration(days: days)))) {
          result.add((festival: f, date: d));
        }
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}
