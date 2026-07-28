class HinduFestival {
  final String name;
  final int month;
  final int day;
  final int hour;
  final String title;
  final String body;
  final Map<String, String> localizedName;

  const HinduFestival({
    required this.name,
    required this.month,
    required this.day,
    required this.hour,
    required this.title,
    required this.body,
    this.localizedName = const {},
  });

  DateTime dateIn(int year) => DateTime(year, month, day, hour);

  /// Returns the festival name translated into the given ISO 639-1 language
  /// code. Falls back to the English `name` when no translation exists.
  String nameFor(String languageCode) {
    if (languageCode.isEmpty) return name;
    return localizedName[languageCode] ?? name;
  }
}

class HinduFestivals {
  static const List<HinduFestival> _all = [
    HinduFestival(
      name: 'Republic Day',
      month: 1, day: 26, hour: 9,
      title: '🇮🇳 AstroPrerna Insight',
      body: 'Republic Day — salute the spirit of India and the Constitution that binds us.',
      localizedName: const {'hi': 'गणतंत्र दिवस', 'bn': 'প্রজাতন্ত্র দিবস', 'mr': 'गणतंत्र दिवस', 'ta': 'குடியரசு தினம்', 'te': 'గణతంత్ర దినోత్సవం', 'gu': 'ગણતંત્ર દિવસ', 'pa': 'ਗਣਤੰਤਰ ਦਿਵਸ', 'kn': 'ಗಣರಾಜ್ಯೋತ್ಸವ', 'ml': 'റിപ്പബ്ലിക് ദിനം', 'or': 'ଗଣତନ୍ତ୍ର ଦିବସ', 'as': 'গণতন্ত্ৰ দিৱস', 'ur': 'یوم جمہوریہ'},
    ),
    HinduFestival(
      name: 'Maha Shivaratri',
      month: 2, day: 15, hour: 6,
      title: '🔱 AstroPrerna Insight',
      body: 'Maha Shivaratri — invoke the blessings of Lord Shiva for inner peace.',
      localizedName: const {'hi': 'महाशिवरात्रि', 'bn': 'মহাশিবরাত্রি', 'mr': 'महाशिवरात्र', 'ta': 'மகா சிவராத்திரி', 'te': 'మహా శివరాత్రి', 'gu': 'મહાશિવરાત્રિ', 'pa': 'ਮਹਾਸ਼ਿਵਰਾਤਰੀ', 'kn': 'ಮಹಾ ಶಿವರಾತ್ರಿ', 'ml': 'മഹാശിവരാത്രി', 'or': 'ମହାଶିବରାତ୍ରି', 'as': 'মহাশিৱৰাত্ৰি', 'ur': 'مہا شیوراتری'},
    ),
    HinduFestival(
      name: 'Holi',
      month: 3, day: 4, hour: 10,
      title: '🎨 AstroPrerna Insight',
      body: 'Happy Holi — celebrate the colors of life, love and the triumph of good over evil!',
      localizedName: const {'hi': 'होली', 'bn': 'হোলি', 'mr': 'होळी', 'ta': 'ஹோலி', 'te': 'హోళీ', 'gu': 'હોળી', 'pa': 'ਹੋਲੀ', 'kn': 'ಹೋಳಿ', 'ml': 'ഹോളി', 'or': 'ହୋଳି', 'as': 'হোলী', 'ur': 'ہولی'},
    ),
    HinduFestival(
      name: 'Chaitra Navratri',
      month: 3, day: 19, hour: 6,
      title: '🌸 AstroPrerna Insight',
      body: 'Chaitra Navratri begins — nine nights of devotion to Maa Durga.',
      localizedName: const {'hi': 'चैत्र नवरात्रि', 'bn': 'চৈত্র নবরাত্রি', 'mr': 'चैत्र नवरात्र', 'ta': 'சைத்ர நவராத்திரி', 'te': 'చైత్ర నవరాత్రి', 'gu': 'ચૈત્ર નવરાત્રિ', 'pa': 'ਚੇਤ ਨਵਰਾਤਰੇ', 'kn': 'ಚೈತ್ರ ನವರಾತ್ರಿ', 'ml': 'ചൈത്ര നവരാത്രി', 'or': 'ଚୈତ୍ର ନବରାତ୍ର', 'as': 'চৈত্ৰ নৱৰাত্ৰি', 'ur': 'چیترا نورت'},
    ),
    HinduFestival(
      name: 'Ram Navami',
      month: 3, day: 26, hour: 10,
      title: '🙏 AstroPrerna Insight',
      body: 'Ram Navami — celebrate the birth of Lord Rama and the ideals he stood for.',
      localizedName: const {'hi': 'राम नवमी', 'bn': 'রাম নবমী', 'mr': 'राम नवमी', 'ta': 'ராம நவமி', 'te': 'రామ నవమి', 'gu': 'રામ નવમી', 'pa': 'ਰਾਮ ਨਵਮੀ', 'kn': 'ರಾಮ ನವಮಿ', 'ml': 'രാമ നവമി', 'or': 'ରାମ ନବମୀ', 'as': 'ৰাম নৱমী', 'ur': 'رام نوم'},
    ),
    HinduFestival(
      name: 'Janmashtami',
      month: 8, day: 15, hour: 6,
      title: '🪈 AstroPrerna Insight',
      body: 'Janmashtami — celebrate the birth of Lord Krishna with devotion and joy.',
      localizedName: const {'hi': 'जन्माष्टमी', 'bn': 'জন্মাষ্টমী', 'mr': 'जन्माष्टमी', 'ta': 'ஜென்மாஷ்டமி', 'te': 'జన్మాష్టమి', 'gu': 'જન્માષ્ટમી', 'pa': 'ਜਨਮਾਸ਼ਟਮੀ', 'kn': 'ಜನ್ಮಾಷ್ಟಮಿ', 'ml': 'ജന്മാഷ്ടമി', 'or': 'ଜନ୍ମାଷ୍ଟମୀ', 'as': 'জন্মাষ্টমী', 'ur': 'جنم اشٹمی'},
    ),
    HinduFestival(
      name: 'Ganesh Chaturthi',
      month: 8, day: 27, hour: 10,
      title: '🐘 AstroPrerna Insight',
      body: 'Ganesh Chaturthi — welcome Bappa home for ten days of blessings!',
      localizedName: const {'hi': 'गणेश चतुर्थी', 'bn': 'গণেশ চতুর্থী', 'mr': 'गणेश चतुर्थी', 'ta': 'விநாயகர் சதுர்த்தி', 'te': 'వినాయక చవితి', 'gu': 'ગણેશ ચતુર્થી', 'pa': 'ਗਣੇਸ਼ ਚਤੁਰਥੀ', 'kn': 'ಗಣೇಶ ಚತುರ್ಥಿ', 'ml': 'ഗണപതി ചതുർത്ഥി', 'or': 'ଗଣେଶ ଚତୁର୍ଥୀ', 'as': 'গণেশ চতুৰ্থী', 'ur': 'گنیش چترتھی'},
    ),
    HinduFestival(
      name: 'Sharad Navratri',
      month: 10, day: 11, hour: 6,
      title: '🪔 AstroPrerna Insight',
      body: 'Sharad Navratri begins — nine nights of devotion, dance and the Divine Mother.',
      localizedName: const {'hi': 'शारदीय नवरात्रि', 'bn': 'শারদীয়া নবরাত্রি', 'mr': 'शारद नवरात्र', 'ta': 'சரத் நவராத்திரி', 'te': 'శరద్ నవరాత్రి', 'gu': 'શારદ નવરાત્રિ', 'pa': 'ਸ਼ਾਰਦ ਨਵਰਾਤਰੇ', 'kn': 'ಶರದ್ ನವರಾತ್ರಿ', 'ml': 'ശരദ് നവരാത്രി', 'or': 'ଶାରଦ ନବରାତ୍ର', 'as': 'শাৰদীয় নৱৰাত্ৰি', 'ur': 'شرد نورت'},
    ),
    HinduFestival(
      name: 'Dussehra',
      month: 10, day: 20, hour: 10,
      title: '🏹 AstroPrerna Insight',
      body: 'Vijayadashami — victory of good over evil, of light over darkness.',
      localizedName: const {'hi': 'दशहरा', 'bn': 'দশেরা', 'mr': 'दसरा', 'ta': 'விஜயதசமி', 'te': 'దసరా', 'gu': 'દસેરા', 'pa': 'ਦਸਹਿਰਾ', 'kn': 'ದಸರಾ', 'ml': 'ദസറ', 'or': 'ଦଶହରା', 'as': 'দশেৰা', 'ur': 'دسہرہ'},
    ),
    HinduFestival(
      name: 'Karva Chauth',
      month: 11, day: 1, hour: 9,
      title: '🌙 AstroPrerna Insight',
      body: 'Karva Chauth — a sacred fast for the bond of love and lifelong partnership.',
      localizedName: const {'hi': 'करवा चौथ', 'bn': 'করওয়া চৌথ', 'mr': 'करवा चौथ', 'ta': 'கர்வா சௌத்', 'te': 'కర్వా చౌత్', 'gu': 'કરવા ચોથ', 'pa': 'ਕਰਵਾ ਚੌਥ', 'kn': 'ಕರ್ವಾ ಚೌತ್', 'ml': 'കർവ ചൗത്ത്', 'or': 'କରୱା ଚାଉଥ୍', 'as': 'কৰৱা চৌথ', 'ur': 'کروا چوتھ'},
    ),
    HinduFestival(
      name: 'Diwali',
      month: 11, day: 8, hour: 19,
      title: '🪔 AstroPrerna Insight',
      body: 'Happy Diwali! May the lamp of knowledge and prosperity light your path.',
      localizedName: const {'hi': 'दिवाली', 'bn': 'দিওয়ালি', 'mr': 'दिवाळी', 'ta': 'தீபாவளி', 'te': 'దీపావళి', 'gu': 'દિવાળી', 'pa': 'ਦਿਵਾਲੀ', 'kn': 'ದೀಪಾವಳಿ', 'ml': 'ദീപാവലി', 'or': 'ଦିପାବଳି', 'as': 'দেৱালী', 'ur': 'دیوالی'},
    ),
    HinduFestival(
      name: 'Govardhan Puja',
      month: 11, day: 9, hour: 10,
      title: '🪔 AstroPrerna Insight',
      body: 'Govardhan Puja — honor Lord Krishna for lifting the mountain and protecting nature.',
      localizedName: const {'hi': 'गोवर्धन पूजा', 'bn': 'গোবর্ধন পূজা', 'mr': 'गोवर्धन पूजा', 'ta': 'கோவர்தன பூஜை', 'te': 'గోవర్ధన పూజ', 'gu': 'ગોવર્ધન પૂજા', 'pa': 'ਗੋਵਰਧਨ ਪੂਜਾ', 'kn': 'ಗೋವರ್ಧನ ಪೂಜೆ', 'ml': 'ഗോവർദ്ധൻ പൂജ', 'or': 'ଗୋବର୍ଦ୍ଧନ ପୂଜା', 'as': 'গোৱৰ্ধন পূজা', 'ur': 'گووردھن پوجا'},
    ),
    HinduFestival(
      name: 'Bhai Dooj',
      month: 11, day: 10, hour: 10,
      title: '🤝 AstroPrerna Insight',
      body: 'Bhai Dooj — celebrate the unbreakable bond between siblings.',
      localizedName: const {'hi': 'भाई दूज', 'bn': 'ভাই ফোঁটা', 'mr': 'भाऊ बीज', 'ta': 'பாய் தூஜ்', 'te': 'భాయి దూజ్', 'gu': 'ભાઈ બીજ', 'pa': 'ਭਰਾਈ ਦੂਜ', 'kn': 'ಭಾಯಿ ದೂಜ್', 'ml': 'ഭായി ദൂജ്', 'or': 'ଭାଇ ଦୂଜ', 'as': 'ভাই ফোঁটা', 'ur': 'بھائی دوج'},
    ),
    HinduFestival(
      name: 'Chhath Puja',
      month: 11, day: 18, hour: 6,
      title: '🌅 AstroPrerna Insight',
      body: 'Chhath Puja — offer arghya to Surya Dev and Chhathi Maiya for wellbeing.',
      localizedName: const {'hi': 'छठ पूजा', 'bn': 'ছঠ পূজা', 'mr': 'छठ पूजा', 'ta': 'சாத் பூஜை', 'te': 'ఛత్ పూజ', 'gu': 'છઠ પૂજા', 'pa': 'ਛੇਠ ਪੂਜਾ', 'kn': 'ಛತ್ ಪೂಜೆ', 'ml': 'ഛത് പൂജ', 'or': 'ଛଠ ପୂଜା', 'as': 'ছঠ পূজা', 'ur': 'چھٹھ پوجا'},
    ),
    HinduFestival(
      name: 'Guru Nanak Jayanti',
      month: 11, day: 24, hour: 6,
      title: '🙏 AstroPrerna Insight',
      body: 'Guru Nanak Jayanti — celebrate the birth of Guru Nanak Dev Ji and his message of equality.',
      localizedName: const {'hi': 'गुरु नानक जयंती', 'bn': 'গুরু নানক জয়ন্তী', 'mr': 'गुरु नानक जयंती', 'ta': 'குரு நானக் ஜெயந்தி', 'te': 'గురు నానక్ జయంతి', 'gu': 'ગુરુ નાનક જયંતી', 'pa': 'ਗੁਰੂ ਨਾਨਕ ਜਨਮ ਦਿਨ', 'kn': 'ಗುರು ನಾನಕ್ ಜಯಂತಿ', 'ml': 'ഗുരു നാനക് ജയന്തി', 'or': 'ଗୁରୁ ନାନକ ଜୟନ୍ତୀ', 'as': 'গুৰু নানক জয়ন্তী', 'ur': 'گرو نانک جینتی'},
    ),
    HinduFestival(
      name: 'Christmas',
      month: 12, day: 25, hour: 9,
      title: '🎄 AstroPrerna Insight',
      body: 'Merry Christmas — peace, love and goodwill to all.',
      localizedName: const {'hi': 'क्रिसमस', 'bn': 'বড়দিন', 'mr': 'ख्रिस्तमस', 'ta': 'கிறிஸ்துமஸ்', 'te': 'క్రిస్మస్', 'gu': 'ક્રિસમસ', 'pa': 'ਕ੍ਰਿਸਮਸ', 'kn': 'ಕ್ರಿಸ್ಮಸ್', 'ml': 'ക്രിസ്മസ്', 'or': 'ଖ୍ରୀଷ୍ଟମାସ', 'as': 'খ্ৰিষ্টমাস', 'ur': 'کرسمس'},
    ),
    HinduFestival(
      name: 'Makar Sankranti',
      month: 1, day: 14, hour: 10,
      title: '🪁 AstroPrerna Insight',
      body: 'Makar Sankranti — celebrate the harvest and the sun\'s journey northward.',
      localizedName: const {'hi': 'मकर संक्रांति', 'bn': 'মকর সংক্রান্তি', 'mr': 'मकर संक्रांत', 'ta': 'தைப் பொங்கல்', 'te': 'మకర సంక్రాంతి', 'gu': 'મકર સંક્રાંતિ', 'pa': 'ਮਕਰ ਸੰਕ੍ਰਾਂਤੀ', 'kn': 'ಮಕರ ಸಂಕ್ರಾಂತಿ', 'ml': 'മകര സംക്രാന്തി', 'or': 'ମକର ସଂକ୍ରାନ୍ତି', 'as': 'মকৰ সংক্ৰান্তি', 'ur': 'مکر سنکرانتی'},
    ),
    HinduFestival(
      name: 'Maha Shivaratri 2027',
      month: 2, day: 6, hour: 6,
      title: '🔱 AstroPrerna Insight',
      body: 'Maha Shivaratri — invoke the blessings of Lord Shiva for inner peace.',
      localizedName: const {'hi': 'महाशिवरात्रि', 'bn': 'মহাশিবরাত্রি', 'mr': 'महाशिवरात्र', 'ta': 'மகா சிவராத்திரி', 'te': 'మహా శివరాత్రి', 'gu': 'મહાશિવરાત્રિ', 'pa': 'ਮਹਾਸ਼ਿਵਰਾਤਰੀ', 'kn': 'ಮಹಾ ಶಿವರಾತ್ರಿ', 'ml': 'മഹാശിവരാത്രി', 'or': 'ମହାଶିବରାତ୍ରି', 'as': 'মহাশিৱৰাত্ৰি', 'ur': 'مہا شیوراتری'},
    ),
    HinduFestival(
      name: 'Holi 2027',
      month: 3, day: 22, hour: 10,
      title: '🎨 AstroPrerna Insight',
      body: 'Happy Holi — splash the colors of love, joy and the triumph of good!',
      localizedName: const {'hi': 'होली', 'bn': 'হোলি', 'mr': 'होळी', 'ta': 'ஹோலி', 'te': 'హోళీ', 'gu': 'હોળી', 'pa': 'ਹੋਲੀ', 'kn': 'ಹೋಳಿ', 'ml': 'ഹോളി', 'or': 'ହୋଳି', 'as': 'হোলী', 'ur': 'ہولی'},
    ),
    HinduFestival(
      name: 'Chaitra Navratri 2027',
      month: 4, day: 7, hour: 6,
      title: '🌸 AstroPrerna Insight',
      body: 'Chaitra Navratri begins — nine nights of devotion to Maa Durga.',
      localizedName: const {'hi': 'चैत्र नवरात्रि', 'bn': 'চৈত্র নবরাত্রি', 'mr': 'चैत्र नवरात्र', 'ta': 'சைத்ர நவராத்திரி', 'te': 'చైత్ర నవరాత్రి', 'gu': 'ચૈત્ર નવરાત્રિ', 'pa': 'ਚੇਤ ਨਵਰਾਤਰੇ', 'kn': 'ಚೈತ್ರ ನವರಾತ್ರಿ', 'ml': 'ചൈത്ര നവരാത്രി', 'or': 'ଚୈତ୍ର ନବରାତ୍ର', 'as': 'চৈত্ৰ নৱৰাত্ৰি', 'ur': 'چیترا نورت'},
    ),
    HinduFestival(
      name: 'Ram Navami 2027',
      month: 4, day: 15, hour: 10,
      title: '🙏 AstroPrerna Insight',
      body: 'Ram Navami — celebrate the birth of Lord Rama and the ideals he stood for.',
      localizedName: const {'hi': 'राम नवमी', 'bn': 'রাম নবমী', 'mr': 'राम नवमी', 'ta': 'ராம நவமி', 'te': 'రామ నవమి', 'gu': 'રામ નવમી', 'pa': 'ਰਾਮ ਨਵਮੀ', 'kn': 'ರಾಮ ನವಮಿ', 'ml': 'രാമ നവമി', 'or': 'ରାମ ନବମୀ', 'as': 'ৰাম নৱমী', 'ur': 'رام نوم'},
    ),
    HinduFestival(
      name: 'Janmashtami 2027',
      month: 8, day: 4, hour: 6,
      title: '🪈 AstroPrerna Insight',
      body: 'Janmashtami — celebrate the birth of Lord Krishna with devotion and joy.',
      localizedName: const {'hi': 'जन्माष्टमी', 'bn': 'জন্মাষ্টমী', 'mr': 'जन्माष्टमी', 'ta': 'ஜென்மாஷ்டமி', 'te': 'జన్మాష్టమి', 'gu': 'જન્માષ્ટમી', 'pa': 'ਜਨਮਾਸ਼ਟਮੀ', 'kn': 'ಜನ್ಮಾಷ್ಟಮಿ', 'ml': 'ജന്മാഷ്ടമി', 'or': 'ଜନ୍ମାଷ୍ଟମୀ', 'as': 'জন্মাষ্টমী', 'ur': 'جنم اشٹمی'},
    ),
    HinduFestival(
      name: 'Ganesh Chaturthi 2027',
      month: 8, day: 16, hour: 10,
      title: '🐘 AstroPrerna Insight',
      body: 'Ganesh Chaturthi — welcome Bappa home for ten days of blessings!',
      localizedName: const {'hi': 'गणेश चतुर्थी', 'bn': 'গণেশ চতুর্থী', 'mr': 'गणेश चतुर्थी', 'ta': 'விநாயகர் சதுர்த்தி', 'te': 'వినాయక చవితి', 'gu': 'ગણેશ ચતુર્થી', 'pa': 'ਗਣੇਸ਼ ਚਤੁਰਥੀ', 'kn': 'ಗಣೇಶ ಚತುರ್ಥಿ', 'ml': 'ഗണപതി ചതുർത്ഥി', 'or': 'ଗଣେଶ ଚତୁର୍ଥୀ', 'as': 'গণেশ চতুৰ্থী', 'ur': 'گنیش چترتھی'},
    ),
    HinduFestival(
      name: 'Sharad Navratri 2027',
      month: 9, day: 30, hour: 6,
      title: '🪔 AstroPrerna Insight',
      body: 'Sharad Navratri begins — nine nights of devotion, dance and the Divine Mother.',
      localizedName: const {'hi': 'शारदीय नवरात्रि', 'bn': 'শারদীয়া নবরাত্রি', 'mr': 'शारद नवरात्र', 'ta': 'சரத் நவராத்திரி', 'te': 'శరద్ నవరాత్రి', 'gu': 'શારદ નવરાત્રિ', 'pa': 'ਸ਼ਾਰਦ ਨਵਰਾਤਰੇ', 'kn': 'ಶರದ್ ನವರಾತ್ರಿ', 'ml': 'ശരദ് നവരാത്രി', 'or': 'ଶାରଦ ନବରାତ୍ର', 'as': 'শাৰদীয় নৱৰাত্ৰি', 'ur': 'شرد نورت'},
    ),
    HinduFestival(
      name: 'Dussehra 2027',
      month: 10, day: 9, hour: 10,
      title: '🏹 AstroPrerna Insight',
      body: 'Vijayadashami — victory of good over evil, of light over darkness.',
      localizedName: const {'hi': 'दशहरा', 'bn': 'দশেরা', 'mr': 'दसरा', 'ta': 'விஜயதசமி', 'te': 'దసరా', 'gu': 'દસેરા', 'pa': 'ਦਸਹਿਰਾ', 'kn': 'ದಸರಾ', 'ml': 'ദസറ', 'or': 'ଦଶହରା', 'as': 'দশেৰা', 'ur': 'دسہرہ'},
    ),
    HinduFestival(
      name: 'Karva Chauth 2027',
      month: 10, day: 21, hour: 9,
      title: '🌙 AstroPrerna Insight',
      body: 'Karva Chauth — a sacred fast for the bond of love and lifelong partnership.',
      localizedName: const {'hi': 'करवा चौथ', 'bn': 'করওয়া চৌথ', 'mr': 'करवा चौथ', 'ta': 'கர்வா சௌத்', 'te': 'కర్వా చౌత్', 'gu': 'કરવા ચોથ', 'pa': 'ਕਰਵਾ ਚੌਥ', 'kn': 'ಕರ್ವಾ ಚೌತ್', 'ml': 'കർവ ചൗത്ത്', 'or': 'କରୱା ଚାଉଥ୍', 'as': 'কৰৱা চৌথ', 'ur': 'کروا چوتھ'},
    ),
    HinduFestival(
      name: 'Diwali 2027',
      month: 10, day: 28, hour: 19,
      title: '🪔 AstroPrerna Insight',
      body: 'Happy Diwali! May the lamp of knowledge and prosperity light your path.',
      localizedName: const {'hi': 'दिवाली', 'bn': 'দিওয়ালি', 'mr': 'दिवाळी', 'ta': 'தீபாவளி', 'te': 'దీపావళి', 'gu': 'દિવાળી', 'pa': 'ਦਿਵਾਲੀ', 'kn': 'ದೀಪಾವಳಿ', 'ml': 'ദീപാവലി', 'or': 'ଦିପାବଳି', 'as': 'দেৱালী', 'ur': 'دیوالی'},
    ),
    HinduFestival(
      name: 'Govardhan Puja 2027',
      month: 10, day: 29, hour: 10,
      title: '🪔 AstroPrerna Insight',
      body: 'Govardhan Puja — honor Lord Krishna for lifting the mountain and protecting nature.',
      localizedName: const {'hi': 'गोवर्धन पूजा', 'bn': 'গোবর্ধন পূজা', 'mr': 'गोवर्धन पूजा', 'ta': 'கோவர்தன பூஜை', 'te': 'గోవర్ధన పూజ', 'gu': 'ગોવર્ધન પૂજા', 'pa': 'ਗੋਵਰਧਨ ਪੂਜਾ', 'kn': 'ಗೋವರ್ಧನ ಪೂಜೆ', 'ml': 'ഗോവർദ്ധൻ പൂജ', 'or': 'ଗୋବର୍ଦ୍ଧନ ପୂଜା', 'as': 'গোৱৰ্ধন পূজা', 'ur': 'گووردھن پوجا'},
    ),
    HinduFestival(
      name: 'Bhai Dooj 2027',
      month: 10, day: 30, hour: 10,
      title: '🤝 AstroPrerna Insight',
      body: 'Bhai Dooj — celebrate the unbreakable bond between siblings.',
      localizedName: const {'hi': 'भाई दूज', 'bn': 'ভাই ফোঁটা', 'mr': 'भाऊ बीज', 'ta': 'பாய் தூஜ்', 'te': 'భాయి దూజ్', 'gu': 'ભાઈ બીજ', 'pa': 'ਭਰਾਈ ਦੂਜ', 'kn': 'ಭಾಯಿ ದೂಜ್', 'ml': 'ഭായി ദൂജ്', 'or': 'ଭାଇ ଦୂଜ', 'as': 'ভাই ফোঁটা', 'ur': 'بھائی دوج'},
    ),
    HinduFestival(
      name: 'Chhath Puja 2027',
      month: 11, day: 7, hour: 6,
      title: '🌅 AstroPrerna Insight',
      body: 'Chhath Puja — offer arghya to Surya Dev and Chhathi Maiya for wellbeing.',
      localizedName: const {'hi': 'छठ पूजा', 'bn': 'ছঠ পূজা', 'mr': 'छठ पूजा', 'ta': 'சாத் பூஜை', 'te': 'ఛత్ పూజ', 'gu': 'છઠ પૂજા', 'pa': 'ਛੇਠ ਪੂਜਾ', 'kn': 'ಛತ್ ಪೂಜೆ', 'ml': 'ഛത് പൂജ', 'or': 'ଛଠ ପୂଜା', 'as': 'ছঠ পূজা', 'ur': 'چھٹھ پوجا'},
    ),
    HinduFestival(
      name: 'Guru Nanak Jayanti 2027',
      month: 11, day: 13, hour: 6,
      title: '🙏 AstroPrerna Insight',
      body: 'Guru Nanak Jayanti — celebrate the birth of Guru Nanak Dev Ji and his message of equality.',
      localizedName: const {'hi': 'गुरु नानक जयंती', 'bn': 'গুরু নানক জয়ন্তী', 'mr': 'गुरु नानक जयंती', 'ta': 'குரு நானக் ஜெயந்தி', 'te': 'గురు నానక్ జయంతి', 'gu': 'ગુરુ નાનક જયંતી', 'pa': 'ਗੁਰੂ ਨਾਨਕ ਜਨਮ ਦਿਨ', 'kn': 'ಗುರು ನಾನಕ್ ಜಯಂತಿ', 'ml': 'ഗുരു നാനക് ജയന്തി', 'or': 'ଗୁରୁ ନାନକ ଜୟନ୍ତୀ', 'as': 'গুৰু নানক জয়ন্তী', 'ur': 'گرو نانک جینتی'},
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
