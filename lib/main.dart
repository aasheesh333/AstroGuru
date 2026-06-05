import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'dart:io';

import 'config/app_config.dart';
import 'logic/language_provider.dart';
import 'logic/user_provider.dart';
import 'logic/kundli_service.dart';
import 'logic/key_manager.dart'; // Import KeyManager
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/kundli_input_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env (--dart-define first, then dotenv fallback for local dev)
  await AppConfig.load();

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

  // Install a global error handler so uncaught errors are at least logged
  // (visible in `adb logcat`). Crashlytics integration is intentionally
  // deferred to a future release; for now we use developer.log and the
  // default red-screen in debug.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log('Uncaught Flutter error: ${details.exceptionAsString()}',
        name: 'AstroPrerna');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    developer.log('Uncaught platform error: $error', name: 'AstroPrerna');
    return true;
  };

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

  // Fire-and-forget: log the install / open event. Wrapped so a logging
  // failure never blocks startup. We use developer.log here instead of
  // FirebaseAnalytics so we don't need the analytics package (and the
  // dependency conflict it introduced with firebase_storage). A future
  // release can re-add analytics once firebase_core / firebase_storage
  // major versions are aligned.
  () async {
    developer.log('app_open: ${Platform.operatingSystem}', name: 'AstroPrerna');
  }();
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
            scaffoldBackgroundColor: const AppColors.scaffoldBackgroundColor,
            appBarTheme: const AppBarTheme(backgroundColor: AppColors.surfaceColor, foregroundColor: AppColors.deepGold),
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
