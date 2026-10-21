import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/widgets/parameter_config_card.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('configuration fits a narrow phone at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var saves = 0;
      var reverts = 0;
      await tester.pumpWidget(MaterialApp(home: MediaQuery(
        data: MediaQueryData(size: const Size(320, 1000),
          textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ParameterConfigCard(
            phRange: const RangeValues(5.5, 6.5),
            ecRange: const RangeValues(1.2, 1.8),
            onPhChanged: (_) {}, onEcChanged: (_) {},
            onSave: () => saves++, onRevert: () => reverts++,
          ),
        )),
      )));
      expect(tester.takeException(), isNull);
      final save = find.widgetWithText(ElevatedButton, 'Save configuration');
      final revert = find.widgetWithText(OutlinedButton, 'Revert');
      await tester.ensureVisible(save);
      expect(tester.getCenter(save).dy, tester.getCenter(revert).dy);
      expect(tester.getRect(save).right, lessThan(tester.getRect(revert).left));
      await tester.tap(save);
      await tester.tap(revert);
      expect(saves, 1);
      expect(reverts, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
