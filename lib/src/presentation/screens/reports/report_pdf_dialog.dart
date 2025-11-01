import 'package:flutter/material.dart';

class ReportPDFDialog extends StatelessWidget {
  final String grade;
  final String? section;

  const ReportPDFDialog({super.key, required this.grade, this.section});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Descargar reporte'),
      content: Text('Se generará un PDF para $grade ${section ?? ''}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Descargar'),
        )
      ],
    );
  }
}