import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astroguru/main.dart';
import 'package:astroguru/logic/language_provider.dart';
import 'package:astroguru/screens/splash_screen.dart';

void main() {
  testWidgets('App smoke test shows splash then routes away', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const AstroPrernaApp(),
      ),
    );

    // Splash is the first widget on first frame.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the async _checkLanguage complete; no artificial delay any more.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    // Splash should have routed to language selection (no language picked yet).
    expect(find.byType(SplashScreen), findsNothing);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
