import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'dart:io';

import 'logic/language_provider.dart';
import 'logic/user_provider.dart';
import 'logic/kundli_service.dart';
import 'logic/key_manager.dart'; // Import KeyManager
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'screens/splash_screen.dart';
import 'screens/kundli_input_screen.dart';
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

  // Initialize AI Key Manager
  try {
    await KeyManager().init();
  } catch (e) {
    developer.log("Error initializing KeyManager: $e");
  }

  // AdMob
  try {
    await AdService().initialize();
  } catch (e) {
    developer.log("Error initializing AdMob: $e");
  }

  // Notification Service (Handles OneSignal + Local)
  try {
    await NotificationService().init();
  } catch (e) {
    developer.log("Error initializing NotificationService: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
             AppLocalizations.delegate,
             GlobalMaterialLocalizations.delegate,
             GlobalWidgetsLocalizations.delegate,
             GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('bn'),
            Locale('mr'),
            Locale('ta'),
            Locale('te'),
            Locale('gu'),
            Locale('pa'),
            Locale('kn'),
            Locale('ml'),
            Locale('or'),
            Locale('as'),
            Locale('ur'),
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const MainScreen(),
            '/kundli': (context) => const KundliInputScreen(),
            '/chat': (context) => const ChatScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
