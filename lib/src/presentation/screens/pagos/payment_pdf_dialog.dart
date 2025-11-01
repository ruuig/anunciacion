import 'package:flutter/material.dart';

class PaymentPDFDialog extends StatelessWidget {
  final String grade;
  final List<Map<String, dynamic>> students;

  const PaymentPDFDialog({
    super.key,
    required this.grade,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final solventes = students.where((s) => s['status'] == 'solvente').toList();
    return AlertDialog(
      title: const Text('Listado generado'),
      content: Text(
        'Se generó el PDF de alumnos solventes para:\n\n'
        'Grado: $grade\n'
        'Solventes: ${solventes.length}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        TextButton(
          onPressed: () {
            // aquí podrías abrir el PDF
            Navigator.pop(context);
          },
          child: const Text('Ver PDF'),
        ),
      ],
    );
  }
}
