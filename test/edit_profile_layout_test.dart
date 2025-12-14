import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:astroguru/screens/edit_profile_screen.dart';
import 'package:astroguru/logic/user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Mock UserProvider to avoid Firebase dependencies
class MockUserProvider extends UserProvider {
  @override
  String get name => "Test User";
  @override
  String get email => "test@example.com";
  @override
  String get dob => "2000-01-01";
  @override
  String? get profileImageBase64 => null;

  @override
  Future<void> loadUserData() async {} // No-op
}

void main() {
  testWidgets('EditProfileScreen layout verification', (WidgetTester tester) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(create: (_) => MockUserProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const EditProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Widgets exist
    expect(find.text('Edit Profile'), findsOneWidget); // AppBar title

    // Find Fields by Label
    final nameFieldFinder = find.widgetWithText(TextFormField, 'Name');
    final dobFieldFinder = find.widgetWithText(TextFormField, 'Date of Birth');
    final emailFieldFinder = find.widgetWithText(TextFormField, 'Email Address');

    expect(nameFieldFinder, findsOneWidget);
    expect(dobFieldFinder, findsOneWidget);
    expect(emailFieldFinder, findsOneWidget);

    // Get Positions
    final namePos = tester.getCenter(nameFieldFinder);
    final dobPos = tester.getCenter(dobFieldFinder);
    final emailPos = tester.getCenter(emailFieldFinder);

    // Verify Order (Vertical)
    // Y increases downwards
    expect(namePos.dy, lessThan(dobPos.dy), reason: "Name should be above DOB");
    expect(dobPos.dy, lessThan(emailPos.dy), reason: "DOB should be above Email");

    // Verify Email is ReadOnly via underlying TextField
    final textFieldFinder = find.descendant(
      of: emailFieldFinder,
      matching: find.byType(TextField),
    );
    final textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.enabled, isFalse);
    expect(textField.readOnly, isTrue);

    // Verify Forgot Password Button exists
    final forgotPasswordFinder = find.text('Forgot Password?');
    expect(forgotPasswordFinder, findsOneWidget);

    // Verify Position (Below Email)
    final forgotPos = tester.getCenter(forgotPasswordFinder);
    expect(emailPos.dy, lessThan(forgotPos.dy), reason: "Forgot Password should be below Email");

    // Clean up
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
