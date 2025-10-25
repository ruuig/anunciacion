import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudentGradeRow extends StatelessWidget {
  final int id;
  final String name;
  final double? grade;
  final ValueChanged<String> onChanged;

  const StudentGradeRow({
    super.key,
    required this.id,
    required this.name,
    required this.grade,
    required this.onChanged,
  });

  Color _bg(double? g) {
    if (g == null) return const Color(0xFFF4F5F7);
    return g >= 70 ? const Color(0xFFEFF7EF) : const Color(0xFFFFF1F1);
    // sin colores fuertes, solo contexto suave
  }

  @override
  Widget build(BuildContext context) {
    String _initialValue() {
      if (grade == null) return '';
      if (grade! % 1 == 0) {
        return grade!.toStringAsFixed(0);
      }
      return grade!.toStringAsFixed(1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: TextFormField(
              key: ValueKey('grade_$id'),
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                LengthLimitingTextInputFormatter(6),
              ],
              initialValue: _initialValue(),
              decoration: InputDecoration(
                hintText: '0–100',
                hintStyle: const TextStyle(fontWeight: FontWeight.w700),
                filled: true,
                fillColor: _bg(grade),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
