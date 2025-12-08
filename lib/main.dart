import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'logic/language_provider.dart';
import 'logic/kundli_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/kundli_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  await dotenv.load(fileName: "assets/.env");

  // Initialize Services
  await KundliService.initialize();

  // AdMob
  MobileAds.instance.initialize();

  // OneSignal
  String oneSignalAppId = dotenv.env['APP_ONESIGNAL_APP_ID'] ?? '';
  if (oneSignalAppId.isNotEmpty) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const AstroPrernaApp(),
    ),
  );
}

class AstroPrernaApp extends StatelessWidget {
  const AstroPrernaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'AstroPrerna',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFF05060A),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0E1016), foregroundColor: Color(0xFFD4AF37)),
            brightness: Brightness.dark,
          ),
          locale: provider.locale,
          localizationsDelegates: const [
             GlobalMaterialLocalizations.delegate,
             GlobalWidgetsLocalizations.delegate,
             GlobalCupertinoLocalizations.delegate,
             AppLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/kundli': (context) => const KundliScreen(),
            '/chat': (context) => const ChatScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
