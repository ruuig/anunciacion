import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudentGradeRow extends StatelessWidget {
  final int id;
  final String name;
  final double? grade;
  final ValueChanged<String> onChanged;
  final String? placeholder;

  const StudentGradeRow({
    super.key,
    required this.id,
    required this.name,
    this.grade,
    this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: grade == null ? '' : grade!.toStringAsFixed(1),
    );

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: placeholder ?? 'Nota', // 👈 usa placeholder aquí
              filled: true,
              fillColor: const Color(0xFFF4F5F7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
