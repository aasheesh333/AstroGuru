import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astroguru/main.dart';
import 'package:astroguru/logic/language_provider.dart';
import 'package:astroguru/screens/splash_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set a large screen size (logical pixels)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0; // 1:1 ratio for max logical space

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({}); // Empty values -> !onboarding_seen

    // Build our app and trigger a frame, wrapping in Provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const AstroPrernaApp(),
      ),
    );

    // Verify that the splash screen shows up initially
    expect(find.byType(SplashScreen), findsOneWidget);

    // Fast forward time to let the splash screen timer finish (2 seconds)
    await tester.pump(const Duration(seconds: 3));

    // Allow animations to settle
    await tester.pumpAndSettle();

    // After Splash, it should go to OnboardingScreen (since prefs are empty)
    expect(find.byType(SplashScreen), findsNothing);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
