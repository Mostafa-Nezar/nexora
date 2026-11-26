import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/app_toast.dart';
import '../logic/calculator_engine.dart';

class CalculatorTool extends StatefulWidget {
  const CalculatorTool({super.key});

  @override
  State<CalculatorTool> createState() => _CalculatorNexoratate();
}

class _CalculatorNexoratate extends State<CalculatorTool> {
  String _expression = '';
  String _preview = '';
  String? _errorText;
  bool _justEvaluated = false;

  static const _operators = {'+', '-', '×', '÷', '%'};

  void _onInput(String value) {
    setState(() {
      _errorText = null;

      if (_justEvaluated) {
        if (_operators.contains(value)) {
          _justEvaluated = false;
        } else {
          _expression = '';
          _justEvaluated = false;
        }
      }

      if (_operators.contains(value)) {
        if (_expression.isEmpty) {
          if (value == '-') {
            _expression = '-';
          }
          return;
        }
        final last = _expression[_expression.length - 1];
        if (_operators.contains(last)) {
          _expression =
              _expression.substring(0, _expression.length - 1) + value;
          _updatePreview();
          return;
        }
      }

      if (value == '.') {
        final lastSegment = _expression.split(RegExp(r'[+\-×÷%()]')).last;
        if (lastSegment.contains('.')) return;
        if (lastSegment.isEmpty) {
          _expression += '0.';
          _updatePreview();
          return;
        }
      }

      _expression += value;
      _updatePreview();
    });
  }

  void _onClear() {
    setState(() {
      _expression = '';
      _preview = '';
      _errorText = null;
      _justEvaluated = false;
    });
  }

  void _onBackspace() {
    if (_expression.isEmpty) return;
    setState(() {
      _errorText = null;
      _justEvaluated = false;
      _expression = _expression.substring(0, _expression.length - 1);
      _updatePreview();
    });
  }

  void _onToggleSign() {
    if (_expression.isEmpty) {
      setState(() {
        _expression = '-';
      });
      return;
    }
    setState(() {
      _errorText = null;
      _justEvaluated = false;
      if (_expression.startsWith('-')) {
        _expression = _expression.substring(1);
      } else {
        _expression = '-($_expression)';
      }
      _updatePreview();
    });
  }

  void _onEvaluate() {
    if (_expression.isEmpty) return;
    try {
      final result = CalculatorEngine.evaluate(_expression);
      final formatted = CalculatorEngine.formatResult(result);
      setState(() {
        _expression = formatted;
        _preview = '';
        _errorText = null;
        _justEvaluated = true;
      });
    } on UnsupportedError catch (e) {
      setState(() {
        _errorText = e.message ?? 'Math error';
      });
    } on FormatException {
      setState(() {
        _errorText = 'Invalid expression';
      });
    }
  }

  void _updatePreview() {
    if (_expression.isEmpty) {
      _preview = '';
      return;
    }
    try {
      final result = CalculatorEngine.evaluate(_expression);
      final formatted = CalculatorEngine.formatResult(result);
      _preview = formatted == _expression ? '' : formatted;
    } catch (_) {
      _preview = '';
    }
  }

  Future<void> _copyResult() async {
    final textToCopy = _preview.isNotEmpty ? _preview : _expression;
    if (textToCopy.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (mounted) {
      AppToast.success(context, 'Copied "$textToCopy" to clipboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayExpr = _expression.isEmpty ? '0' : _expression;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF030712),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _miniActionChip(
                        label: '%',
                        onTap: () => _onInput('%'),
                      ),
                      const SizedBox(width: 6),
                      _miniActionChip(
                        label: '±',
                        onTap: _onToggleSign,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed:
                        (_expression.isEmpty && _preview.isEmpty)
                            ? null
                            : _copyResult,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: Colors.amberAccent,
                    tooltip: 'Copy result',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  displayExpr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 22,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _errorText != null
                      ? Text(
                          _errorText!,
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          _preview.isNotEmpty ? '= $_preview' : '',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildKeypadRow([
          _KeySpec('AC', _onClear, isDanger: true),
          _KeySpec('(', () => _onInput('('), isOperator: true),
          _KeySpec(')', () => _onInput(')'), isOperator: true),
          _KeySpec('÷', () => _onInput('÷'), isOperator: true),
        ]),
        const SizedBox(height: 8),
        _buildKeypadRow([
          _KeySpec('7', () => _onInput('7')),
          _KeySpec('8', () => _onInput('8')),
          _KeySpec('9', () => _onInput('9')),
          _KeySpec('×', () => _onInput('×'), isOperator: true),
        ]),
        const SizedBox(height: 8),
        _buildKeypadRow([
          _KeySpec('4', () => _onInput('4')),
          _KeySpec('5', () => _onInput('5')),
          _KeySpec('6', () => _onInput('6')),
          _KeySpec('-', () => _onInput('-'), isOperator: true),
        ]),
        const SizedBox(height: 8),
        _buildKeypadRow([
          _KeySpec('1', () => _onInput('1')),
          _KeySpec('2', () => _onInput('2')),
          _KeySpec('3', () => _onInput('3')),
          _KeySpec('+', () => _onInput('+'), isOperator: true),
        ]),
        const SizedBox(height: 8),
        _buildKeypadRow([
          _KeySpec('⌫', _onBackspace, isOperator: true),
          _KeySpec('0', () => _onInput('0')),
          _KeySpec('.', () => _onInput('.')),
          _KeySpec('=', _onEvaluate, isPrimary: true),
        ]),
      ],
    );
  }

  Widget _miniActionChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<_KeySpec> keys) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildKeyButton(keys[i])),
        ],
      ],
    );
  }

  Widget _buildKeyButton(_KeySpec spec) {
    final Color bg;
    final Color fg;

    if (spec.isPrimary) {
      bg = Colors.amberAccent;
      fg = const Color(0xFF030712);
    } else if (spec.isDanger) {
      bg = const Color(0xFF3F1D2B);
      fg = const Color(0xFFFCA5A5);
    } else if (spec.isOperator) {
      bg = const Color(0xFF1E293B);
      fg = Colors.amberAccent;
    } else {
      bg = const Color(0xFF111827);
      fg = Colors.white;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: spec.onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              spec.label,
              style: TextStyle(
                color: fg,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeySpec {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isPrimary;
  final bool isDanger;

  const _KeySpec(
    this.label,
    this.onTap, {
    this.isOperator = false,
    this.isPrimary = false,
    this.isDanger = false,
  });
}
