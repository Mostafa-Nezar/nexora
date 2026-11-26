import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/app_toast.dart';
import '../logic/unit_converter_engine.dart';

class UnitConverterTool extends StatefulWidget {
  const UnitConverterTool({super.key});

  @override
  State<UnitConverterTool> createState() => _UnitConverterNexoratate();
}

class _UnitConverterNexoratate extends State<UnitConverterTool> {
  final TextEditingController _inputController = TextEditingController(text: '1');
  UnitCategory _category = UnitCategory.length;
  late UnitDefinition _fromUnit;
  late UnitDefinition _toUnit;

  @override
  void initState() {
    super.initState();
    final units = UnitConverterEngine.unitsByCategory[_category]!;
    _fromUnit = units[0];
    _toUnit = units[1];
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _selectCategory(UnitCategory category) {
    if (_category == category) return;
    final units = UnitConverterEngine.unitsByCategory[category]!;
    setState(() {
      _category = category;
      _fromUnit = units[0];
      _toUnit = units.length > 1 ? units[1] : units[0];
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
  }

  String _computeResultText() {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) return '0';
    final parsed = double.tryParse(raw);
    if (parsed == null) return 'Invalid number';
    final converted = UnitConverterEngine.convert(
      category: _category,
      value: parsed,
      from: _fromUnit,
      to: _toUnit,
    );
    return UnitConverterEngine.formatValue(converted);
  }

  Future<void> _copyResult(String resultText) async {
    if (resultText == 'Invalid number') return;
    final full = '$resultText ${_toUnit.symbol}';
    await Clipboard.setData(ClipboardData(text: full));
    if (mounted) {
      AppToast.success(context, 'Copied "$full" to clipboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = UnitConverterEngine.unitsByCategory[_category]!;
    final resultText = _computeResultText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in UnitCategory.values) ...[
                ChoiceChip(
                  label: Text(cat.label),
                  selected: _category == cat,
                  onSelected: (_) => _selectCategory(cat),
                  selectedColor: Colors.amberAccent,
                  backgroundColor: const Color(0xFF111827),
                  labelStyle: TextStyle(
                    color: _category == cat
                        ? const Color(0xFF030712)
                        : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: const BorderSide(color: Colors.white12),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inputController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Value (${_fromUnit.symbol})',
            labelStyle: const TextStyle(color: Colors.amberAccent),
            filled: true,
            fillColor: const Color(0xFF030712),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amberAccent),
            ),
            suffixIcon: _inputController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    onPressed: () {
                      _inputController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildUnitDropdown(
                label: 'From',
                value: _fromUnit,
                units: units,
                onChanged: (u) {
                  if (u != null) setState(() => _fromUnit = u);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton.filledTonal(
                onPressed: _swapUnits,
                icon: const Icon(Icons.swap_horiz_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.amberAccent,
                ),
                tooltip: 'Swap units',
              ),
            ),
            Expanded(
              child: _buildUnitDropdown(
                label: 'To',
                value: _toUnit,
                units: units,
                onChanged: (u) {
                  if (u != null) setState(() => _toUnit = u);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF030712),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Converted Result',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resultText == 'Invalid number'
                          ? resultText
                          : '$resultText ${_toUnit.symbol}',
                      style: TextStyle(
                        color: resultText == 'Invalid number'
                            ? const Color(0xFFF87171)
                            : Colors.amberAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: resultText == 'Invalid number'
                    ? null
                    : () => _copyResult(resultText),
                icon: const Icon(Icons.copy_rounded, color: Colors.amberAccent),
                tooltip: 'Copy converted result',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitDropdown({
    required String label,
    required UnitDefinition value,
    required List<UnitDefinition> units,
    required ValueChanged<UnitDefinition?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF030712),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UnitDefinition>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0F172A),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: units
              .map(
                (u) => DropdownMenuItem(
                  value: u,
                  child: Text(
                    '${u.name} (${u.symbol})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
