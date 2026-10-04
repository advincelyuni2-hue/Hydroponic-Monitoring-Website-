// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

<<<<<<< HEAD
=======
import 'package:flutter/material.dart';
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
import 'package:flutter_test/flutter_test.dart';

import 'package:monitoring_app/main.dart';

void main() {
<<<<<<< HEAD
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
        await tester.pumpWidget(const MyApp());

        expect(find.text('Login your account'), findsOneWidget);
        expect(find.text('Your email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
=======
  testWidgets('shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Login your account'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Log In'), findsOneWidget);
>>>>>>> 2ca2dfb6b5f8a9d94bea8570e02d6c83c2f281df
  });
}
