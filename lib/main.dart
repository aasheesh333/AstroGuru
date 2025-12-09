import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'dart:io';

import 'logic/language_provider.dart';
import 'logic/kundli_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/kundli_input_screen.dart'; // Import Input Screen
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    developer.log("Error loading .env file: $e");
  }

  // Initialize Firebase
  try {
    if (Platform.isAndroid) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBwE74YsLUWHPW7VqXceFgAUtiACYG6rXw',
          appId: '1:10129614422:android:14fe96393d410dd465fdf7',
          messagingSenderId: '10129614422',
          projectId: 'astroprerna-7ee7c',
          storageBucket: 'astroprerna-7ee7c.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    developer.log("Error initializing Firebase: $e");
  }

  // Initialize Services
  try {
    await KundliService.initialize();
  } catch (e) {
    developer.log("Error initializing KundliService: $e");
  }

  // AdMob
  try {
    MobileAds.instance.initialize();
  } catch (e) {
    developer.log("Error initializing AdMob: $e");
  }

  // OneSignal
  try {
    String oneSignalAppId = dotenv.env['APP_ONESIGNAL_APP_ID'] ?? '';
    if (oneSignalAppId.isNotEmpty) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);
    }
  } catch (e) {
    developer.log("Error initializing OneSignal: $e");
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
             // AppLocalizations.delegate, // Generated delegate
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            // Add others
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const MainScreen(),
            '/kundli': (context) => const KundliInputScreen(), // Changed to Input Screen
            '/chat': (context) => const ChatScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
