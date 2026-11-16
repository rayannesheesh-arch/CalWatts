// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/screens/auth_screen.dart';

void main() {
  testWidgets('Unauthenticated users are prompted to sign in', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome to CalWatt'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
