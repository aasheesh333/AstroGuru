// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:astroguru/main.dart';
import 'package:astroguru/screens/splash_screen.dart';
import 'package:astroguru/logic/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const AstroPrernaApp(),
      ),
    );

    // Verify that the splash screen shows up initially
    expect(find.byType(SplashScreen), findsOneWidget);

    // Allow time for the splash screen timer to complete to avoid pending timer exception
    await tester.pump(const Duration(seconds: 3));
  });
}
