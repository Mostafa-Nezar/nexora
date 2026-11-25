import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tools/main.dart';

void main() {
  testWidgets('bottom navigation shows English labels and changes pages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ToolsApp());

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Scanner'), findsWidgets);
    expect(find.text('Device'), findsWidgets);
    expect(find.text('Files'), findsWidgets);

    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
  });
}
