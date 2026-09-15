import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherapp/main.dart';

void main() {
  testWidgets('Weather home renders and switches temperature units', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Mostly sunny'), findsOneWidget);
    expect(find.text('18°'), findsWidgets);
    await tester.tap(find.text('°F'));
    await tester.pumpAndSettle();
    expect(find.text('64°'), findsWidgets);
  });

  testWidgets('City selection updates the weather at mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('San Francisco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chicago').last);
    await tester.pumpAndSettle();
    expect(find.text('22°'), findsWidgets);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
  });
}
