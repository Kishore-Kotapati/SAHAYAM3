import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:five_m_stress_relief/main.dart';

void main() {
  testWidgets('App loads login screen and missions', (WidgetTester tester) async {
    // Load the app
    await tester.pumpWidget(const MyApp());

    // Verify login screen UI
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Navigate to mission screen
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Check missions exist
    expect(find.textContaining('Mission'), findsWidgets);

    // Tick one mission checkbox
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    // Ensure state changed
    final Checkbox firstBox = tester.widget(find.byType(Checkbox).first);
    expect(firstBox.value, true);
  });
}
