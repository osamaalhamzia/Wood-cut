import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'utils.dart';

/// يقبل الأرقام الإنجليزية فقط (ويحوّل أي أرقام عربية يكتبها الكيبورد إلى إنجليزية).
class EnglishNumberFormatter extends TextInputFormatter {
  EnglishNumberFormatter({this.allowDecimal = true});

  final bool allowDecimal;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var t = normalizeDigits(newValue.text);
    t = t.replaceAll(RegExp(allowDecimal ? r'[^0-9.]' : r'[^0-9]'), '');
    if (allowDecimal) {
      final i = t.indexOf('.');
      if (i >= 0) {
        t = t.substring(0, i + 1) + t.substring(i + 1).replaceAll('.', '');
      }
    }
    if (t == newValue.text) return newValue;
    final offset = math.min(math.max(newValue.selection.end, 0), t.length);
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = AppColors.line,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class GridWrap extends StatelessWidget {
  const GridWrap({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final w = (cons.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: [
          for (final ch in children) SizedBox(width: w, child: ch),
        ],
      );
    });
  }
}

InputDecoration fieldDecoration({String? hint, String? suffix}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textDim),
    suffixText: suffix,
    suffixStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
    filled: true,
    fillColor: AppColors.inset,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.accent),
    border: border(AppColors.line),
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textDim, fontSize: 13),
      ),
    );
  }
}

/// حقل رقمي: الأرقام إنجليزية، والعنوان والوحدة بالعربية.
class NumField extends StatefulWidget {
  const NumField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.hint,
    this.decimal = true,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? suffix;
  final String? hint;
  final bool decimal;

  @override
  State<NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<NumField> {
  late final TextEditingController _c;

  String _show(double v) => v == 0 ? '' : fmtNum(v);

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _show(widget.value));
  }

  @override
  void didUpdateWidget(NumField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (parseNum(_c.text) != widget.value) {
      _c.text = _show(widget.value);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label),
        TextField(
          controller: _c,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
          inputFormatters: [EnglishNumberFormatter(allowDecimal: widget.decimal)],
          style: const TextStyle(fontSize: 16),
          decoration: fieldDecoration(hint: widget.hint, suffix: widget.suffix),
          onChanged: (t) => widget.onChanged(parseNum(t)),
        ),
      ],
    );
  }
}
