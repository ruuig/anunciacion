import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeInput extends StatelessWidget {
  final double? value;
  final ValueChanged<double?> onChanged;

  const GradeInput({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          hintText: '0–100',
          hintStyle: const TextStyle(fontWeight: FontWeight.w700),
          filled: true,
          fillColor: _cellBg(value),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (t) {
          double? v = double.tryParse(t.replaceAll(',', '.'));
          if (v == null) {
            onChanged(null);
            return;
          }
          onChanged(v.clamp(0, 100));
        },
      ),
    );
  }

  Color _cellBg(double? g) {
    if (g == null) return const Color(0xFFF4F5F7);
    return g >= 70 ? const Color(0xFFEFF7EF) : const Color(0xFFFFF1F1);
  }
}
