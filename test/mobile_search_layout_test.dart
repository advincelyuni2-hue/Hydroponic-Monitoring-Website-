import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/widgets/header_search.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('mobile search fits above keyboard at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
        home: Scaffold(body: Builder(builder: (context) => TextButton(
          onPressed: () => showMobileSearchSheet(context),
          child: const Text('Open search'),
        ))),
      ));
      await tester.tap(find.text('Open search'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'dashboard');
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'no-match-' * 20);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
