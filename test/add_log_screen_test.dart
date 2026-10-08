import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_app/screens/add_log_screen.dart';

void main() {
  testWidgets('manual fix accepts blank amount and reservoir volume',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    FixEntry? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecordFixCard(
              onCancel: () {},
              onSubmit: (entry) async {
                submitted = entry;
                return true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(1), '6.8');
    final actionDropdown = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(actionDropdown);
    await tester.tap(actionDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('pH Down').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Record fix'));
    await tester.tap(find.text('Record fix'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.amount, isNull);
    expect(submitted!.reservoirVolumeL, isNull);
  });
}
