import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gilgal_telugu_worship/screens/splash_screen.dart';
import 'package:gilgal_telugu_worship/theme/app_theme.dart';

void main() {
  testWidgets('Splash screen renders loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: const SplashScreen(),
      ),
    );

    expect(find.text('Gilgal Worship'), findsOneWidget);
    expect(find.text('Loading…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
