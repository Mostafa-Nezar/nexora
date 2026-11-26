import 'dart:math' as math;

enum UnitCategory {
  length('Length'),
  weight('Weight'),
  temperature('Temp'),
  data('Data'),
  time('Time'),
  speed('Speed');

  final String label;
  const UnitCategory(this.label);
}

class UnitDefinition {
  final String id;
  final String name;
  final String symbol;
  final double toBaseFactor;

  const UnitDefinition({
    required this.id,
    required this.name,
    required this.symbol,
    required this.toBaseFactor,
  });
}

class UnitConverterEngine {
  const UnitConverterEngine._();

  static const Map<UnitCategory, List<UnitDefinition>> unitsByCategory = {
    UnitCategory.length: [
      UnitDefinition(id: 'm', name: 'Meter', symbol: 'm', toBaseFactor: 1.0),
      UnitDefinition(id: 'km', name: 'Kilometer', symbol: 'km', toBaseFactor: 1000.0),
      UnitDefinition(id: 'cm', name: 'Centimeter', symbol: 'cm', toBaseFactor: 0.01),
      UnitDefinition(id: 'mm', name: 'Millimeter', symbol: 'mm', toBaseFactor: 0.001),
      UnitDefinition(id: 'mi', name: 'Mile', symbol: 'mi', toBaseFactor: 1609.344),
      UnitDefinition(id: 'yd', name: 'Yard', symbol: 'yd', toBaseFactor: 0.9144),
      UnitDefinition(id: 'ft', name: 'Foot', symbol: 'ft', toBaseFactor: 0.3048),
      UnitDefinition(id: 'in', name: 'Inch', symbol: 'in', toBaseFactor: 0.0254),
    ],
    UnitCategory.weight: [
      UnitDefinition(id: 'kg', name: 'Kilogram', symbol: 'kg', toBaseFactor: 1.0),
      UnitDefinition(id: 'g', name: 'Gram', symbol: 'g', toBaseFactor: 0.001),
      UnitDefinition(id: 'mg', name: 'Milligram', symbol: 'mg', toBaseFactor: 0.000001),
      UnitDefinition(id: 't', name: 'Metric Ton', symbol: 't', toBaseFactor: 1000.0),
      UnitDefinition(id: 'lb', name: 'Pound', symbol: 'lb', toBaseFactor: 0.45359237),
      UnitDefinition(id: 'oz', name: 'Ounce', symbol: 'oz', toBaseFactor: 0.028349523125),
    ],
    UnitCategory.temperature: [
      UnitDefinition(id: 'c', name: 'Celsius', symbol: '°C', toBaseFactor: 1.0),
      UnitDefinition(id: 'f', name: 'Fahrenheit', symbol: '°F', toBaseFactor: 1.0),
      UnitDefinition(id: 'k', name: 'Kelvin', symbol: 'K', toBaseFactor: 1.0),
    ],
    UnitCategory.data: [
      UnitDefinition(id: 'b', name: 'Byte', symbol: 'B', toBaseFactor: 1.0),
      UnitDefinition(id: 'kb', name: 'Kilobyte', symbol: 'KB', toBaseFactor: 1024.0),
      UnitDefinition(id: 'mb', name: 'Megabyte', symbol: 'MB', toBaseFactor: 1048576.0),
      UnitDefinition(id: 'gb', name: 'Gigabyte', symbol: 'GB', toBaseFactor: 1073741824.0),
      UnitDefinition(id: 'tb', name: 'Terabyte', symbol: 'TB', toBaseFactor: 1099511627776.0),
    ],
    UnitCategory.time: [
      UnitDefinition(id: 's', name: 'Second', symbol: 's', toBaseFactor: 1.0),
      UnitDefinition(id: 'min', name: 'Minute', symbol: 'min', toBaseFactor: 60.0),
      UnitDefinition(id: 'h', name: 'Hour', symbol: 'h', toBaseFactor: 3600.0),
      UnitDefinition(id: 'd', name: 'Day', symbol: 'd', toBaseFactor: 86400.0),
      UnitDefinition(id: 'wk', name: 'Week', symbol: 'wk', toBaseFactor: 604800.0),
    ],
    UnitCategory.speed: [
      UnitDefinition(id: 'mps', name: 'Meters / sec', symbol: 'm/s', toBaseFactor: 1.0),
      UnitDefinition(id: 'kmh', name: 'Kilometers / hr', symbol: 'km/h', toBaseFactor: 1.0 / 3.6),
      UnitDefinition(id: 'mph', name: 'Miles / hr', symbol: 'mph', toBaseFactor: 0.44704),
      UnitDefinition(id: 'kn', name: 'Knot', symbol: 'kn', toBaseFactor: 0.514444),
    ],
  };

  static double convert({
    required UnitCategory category,
    required double value,
    required UnitDefinition from,
    required UnitDefinition to,
  }) {
    if (from.id == to.id) return value;

    if (category == UnitCategory.temperature) {
      final celsius = switch (from.id) {
        'c' => value,
        'f' => (value - 32.0) * 5.0 / 9.0,
        'k' => value - 273.15,
        _ => value,
      };
      return switch (to.id) {
        'c' => celsius,
        'f' => celsius * 9.0 / 5.0 + 32.0,
        'k' => celsius + 273.15,
        _ => celsius,
      };
    }

    final baseValue = value * from.toBaseFactor;
    return baseValue / to.toBaseFactor;
  }

  static String formatValue(double value) {
    if (value == 0) return '0';
    if (value.abs() >= 1e12 || (value.abs() > 0 && value.abs() < 1e-6)) {
      return value.toStringAsExponential(5).replaceAll(RegExp(r'\.?0+e'), 'e');
    }
    final factor = math.pow(10, 8);
    final rounded = (value * factor).round() / factor;
    if (rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }
    var text = rounded.toStringAsFixed(8);
    text = text.replaceAll(RegExp(r'0+$'), '');
    text = text.replaceAll(RegExp(r'\.$'), '');
    return text;
  }
}
