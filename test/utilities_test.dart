import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Nexora/features/utilities/logic/calculator_engine.dart';
import 'package:Nexora/features/utilities/logic/unit_converter_engine.dart';
import 'package:Nexora/features/utilities/utilities_screen.dart';

void main() {
  group('CalculatorEngine', () {
    test('evaluates basic operations and precedence', () {
      expect(CalculatorEngine.evaluate('2+3×4'), 14);
      expect(CalculatorEngine.evaluate('(2+3)×4'), 20);
      expect(CalculatorEngine.evaluate('15÷3-2'), 3);
      expect(CalculatorEngine.evaluate('10%3'), 1);
      expect(CalculatorEngine.evaluate('-5+8'), 3);
      expect(CalculatorEngine.evaluate('0.1+0.2'), closeTo(0.3, 1e-9));
      expect(CalculatorEngine.formatResult(0.1 + 0.2), '0.3');
    });

    test('throws on division by zero and invalid syntax', () {
      expect(() => CalculatorEngine.evaluate('5÷0'), throwsUnsupportedError);
      expect(() => CalculatorEngine.evaluate('5+'), throwsFormatException);
      expect(() => CalculatorEngine.evaluate('(2+3'), throwsFormatException);
    });
  });

  group('UnitConverterEngine', () {
    test('converts length, weight, and data accurately', () {
      final lengthUnits = UnitConverterEngine.unitsByCategory[UnitCategory.length]!;
      final meter = lengthUnits.firstWhere((u) => u.id == 'm');
      final km = lengthUnits.firstWhere((u) => u.id == 'km');
      expect(
        UnitConverterEngine.convert(
          category: UnitCategory.length,
          value: 1500,
          from: meter,
          to: km,
        ),
        closeTo(1.5, 1e-9),
      );

      final dataUnits = UnitConverterEngine.unitsByCategory[UnitCategory.data]!;
      final gb = dataUnits.firstWhere((u) => u.id == 'gb');
      final mb = dataUnits.firstWhere((u) => u.id == 'mb');
      expect(
        UnitConverterEngine.convert(
          category: UnitCategory.data,
          value: 2,
          from: gb,
          to: mb,
        ),
        closeTo(2048, 1e-9),
      );
    });

    test('converts temperatures accurately', () {
      final tempUnits =
          UnitConverterEngine.unitsByCategory[UnitCategory.temperature]!;
      final c = tempUnits.firstWhere((u) => u.id == 'c');
      final f = tempUnits.firstWhere((u) => u.id == 'f');
      final k = tempUnits.firstWhere((u) => u.id == 'k');

      expect(
        UnitConverterEngine.convert(
          category: UnitCategory.temperature,
          value: 100,
          from: c,
          to: f,
        ),
        closeTo(212, 1e-9),
      );
      expect(
        UnitConverterEngine.convert(
          category: UnitCategory.temperature,
          value: 32,
          from: f,
          to: k,
        ),
        closeTo(273.15, 1e-9),
      );
    });
  });

  group('UtilitiesScreen widgets', () {
    testWidgets('calculator evaluates tapped expression', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesScreen()));

      await tester.tap(find.text('7'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('='));
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('timer and stopwatch tabs render and respond', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesScreen()));

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      expect(find.text('05:00'), findsOneWidget);
      await tester.tap(find.text('1m'));
      await tester.pump();
      expect(find.text('01:00'), findsOneWidget);

      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();
      expect(find.text('00:00.00'), findsOneWidget);
    });

    testWidgets('unit converter updates output on input change', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UtilitiesScreen()));

      await tester.tap(find.text('Converter'));
      await tester.pumpAndSettle();

      expect(find.text('0.001 km'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '2500');
      await tester.pump();
      expect(find.text('2.5 km'), findsOneWidget);
    });
  });
}
