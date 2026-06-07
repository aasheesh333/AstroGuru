import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astroguru/logic/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserSession chat language', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getChatLanguage returns null when unset', () async {
      final lang = await UserSession.getChatLanguage();
      expect(lang, isNull);
    });

    test('setChatLanguage persists the value', () async {
      await UserSession.setChatLanguage('ta');
      final lang = await UserSession.getChatLanguage();
      expect(lang, 'ta');
    });

    test('setChatLanguage overwrites a previous value', () async {
      await UserSession.setChatLanguage('hi');
      await UserSession.setChatLanguage('en');
      final lang = await UserSession.getChatLanguage();
      expect(lang, 'en');
    });

    test('setChatLanguage accepts a null value to clear it', () async {
      await UserSession.setChatLanguage('ta');
      await UserSession.setChatLanguage(null);
      final lang = await UserSession.getChatLanguage();
      expect(lang, isNull);
    });
  });
}
