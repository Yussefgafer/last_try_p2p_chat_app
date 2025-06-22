// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:p2p_chat/main.dart';

void main() {
  testWidgets('P2P Chat app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const P2PChatApp());

    // Verify that the splash screen is shown
    expect(find.text('P2P Chat'), findsOneWidget);

    // Wait for splash screen animation (shorter timeout)
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // The app should either show login screen or home screen
    // Let's just verify the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
