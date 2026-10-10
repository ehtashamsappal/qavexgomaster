// Smoke test for Qavex Go Master: the app boots through the loading
// state into the splash screen, then navigates home.
//
// NOTE: run with `flutter test`. (`dart test` cannot compile Flutter
// framework code, so this file is excluded from plain `dart test` runs.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qavexgomaster/main.dart';
import 'package:qavexgomaster/screens/home_screen.dart';
import 'package:qavexgomaster/screens/splash_screen.dart';

void main() {
  testWidgets('app boots to splash, then home', (WidgetTester tester) async {
    await tester.pumpWidget(const QavexGoMasterApp());

    // While the profile loads we show the boot indicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Splash screen appears after boot.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('QAVEX GO MASTER'), findsOneWidget);

    // Splash navigates to home on its own.
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Play Go'), findsOneWidget);
  });
}
