import 'dart:math' as math;

/// Pure-Dart mathematical expression evaluator supporting +, -, ×, ÷, %,
/// parentheses, unary +/-, and decimal numbers.
class CalculatorEngine {
  const CalculatorEngine._();

  /// Evaluates [expression] and returns the numeric result.
  /// Throws [FormatException] for invalid syntax or [UnsupportedError] for
  /// division by zero.
  static double evaluate(String expression) {
    final normalized = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(' ', '');

    if (normalized.isEmpty) {
      throw const FormatException('Empty expression');
    }

    final parser = _ExpressionParser(normalized);
    final result = parser.parseExpression();
    if (!parser.isAtEnd) {
      throw FormatException('Unexpected character at index ${parser.index}');
    }
    if (result.isNaN || result.isInfinite) {
      throw UnsupportedError('Math error');
    }
    return result;
  }

  /// Formats [value] cleanly for display, trimming trailing zeros on decimals.
  static String formatResult(double value) {
    if (value == 0) return '0';
    if (value.abs() >= 1e12 || (value.abs() > 0 && value.abs() < 1e-9)) {
      return value.toStringAsExponential(6).replaceAll(RegExp(r'\.?0+e'), 'e');
    }
    // Round to 10 decimal places to avoid floating-point artifacts like 0.30000000000000004.
    final factor = math.pow(10, 10);
    final rounded = (value * factor).round() / factor;
    if (rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }
    var text = rounded.toStringAsFixed(10);
    text = text.replaceAll(RegExp(r'0+$'), '');
    text = text.replaceAll(RegExp(r'\.$'), '');
    return text;
  }
}

class _ExpressionParser {
  final String _input;
  int index = 0;

  _ExpressionParser(this._input);

  bool get isAtEnd => index >= _input.length;

  String get _current => _input[index];

  double parseExpression() {
    var value = parseTerm();
    while (!isAtEnd && (_current == '+' || _current == '-')) {
      final op = _current;
      index++;
      final right = parseTerm();
      value = op == '+' ? value + right : value - right;
    }
    return value;
  }

  double parseTerm() {
    var value = parseFactor();
    while (!isAtEnd && (_current == '*' || _current == '/' || _current == '%')) {
      final op = _current;
      index++;
      final right = parseFactor();
      if (op == '*') {
        value *= right;
      } else if (op == '/') {
        if (right == 0) {
          throw UnsupportedError('Division by zero');
        }
        value /= right;
      } else {
        if (right == 0) {
          throw UnsupportedError('Modulo by zero');
        }
        value %= right;
      }
    }
    return value;
  }

  double parseFactor() {
    if (isAtEnd) {
      throw const FormatException('Unexpected end of expression');
    }

    if (_current == '+') {
      index++;
      return parseFactor();
    }
    if (_current == '-') {
      index++;
      return -parseFactor();
    }

    if (_current == '(') {
      index++;
      final value = parseExpression();
      if (isAtEnd || _current != ')') {
        throw const FormatException('Missing closing parenthesis');
      }
      index++;
      return value;
    }

    return _parseNumber();
  }

  double _parseNumber() {
    final start = index;
    var hasDot = false;

    while (!isAtEnd) {
      final ch = _current;
      if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        index++;
      } else if (ch == '.' && !hasDot) {
        hasDot = true;
        index++;
      } else {
        break;
      }
    }

    if (start == index || _input.substring(start, index) == '.') {
      throw FormatException('Expected number at index $start');
    }

    return double.parse(_input.substring(start, index));
  }
}
