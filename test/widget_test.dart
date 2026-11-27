import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/core/widgets/app_toast.dart';
import 'package:nexora/main.dart';

void main() {
  testWidgets('bottom navigation shows English labels and changes pages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ToolsApp());

    expect(find.text('Home'), findsWidgets);
    expect(
      tester.getSize(find.byKey(const Key('main-bottom-navigation'))).height,
      lessThanOrEqualTo(56),
    );

    await tester.tap(find.byIcon(Icons.folder_open_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Files'), findsWidgets);
    expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
  });

  testWidgets('custom toast displays an error reason', (
    WidgetTester tester,
  ) async {
    late BuildContext toastContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            toastContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    AppToast.error(toastContext, 'Network is unavailable.');
    await tester.pump();

    expect(find.text('Network is unavailable.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
