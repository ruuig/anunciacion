import 'package:anunciacion/src/presentation/screens/pagos/payment_manual_sheet.dart';
import 'package:anunciacion/src/presentation/screens/pagos/payment_upload_sheet.dart';
import 'package:flutter/material.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';

import 'payment_pdf_dialog.dart';
import 'payment_detail_page.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final List<String> _grades = const [
    '1ro Primaria',
    '2do Primaria',
    '3ro Primaria',
    '4to Primaria',
    '5to Primaria',
    '6to Primaria',
  ];

  String? _selectedGrade;

  // mock alumnos por grado
  final Map<String, List<Map<String, dynamic>>> _studentsByGrade = {
    '1ro Primaria': [
      {
        'id': 1,
        'name': 'Ana López',
        'status': 'solvente',
        'lastPayment': 'Octubre 2025',
        'amount': 350.0,
        'grade': '1ro Primaria',
        'section': 'A',
      },
      {
        'id': 2,
        'name': 'Carlos Pérez',
        'status': 'pendiente',
        'lastPayment': 'Septiembre 2025',
        'amount': 0.0,
        'grade': '1ro Primaria',
        'section': 'A',
      },
    ],
    '2do Primaria': [
      {
        'id': 3,
        'name': 'Diego Hernández',
        'status': 'solvente',
        'lastPayment': 'Octubre 2025',
        'amount': 350.0,
        'grade': '2do Primaria',
        'section': 'B',
      },
      {
        'id': 4,
        'name': 'Sofía Gómez',
        'status': 'pendiente',
        'lastPayment': 'Agosto 2025',
        'amount': 0.0,
        'grade': '2do Primaria',
        'section': 'B',
      },
    ],
  };

  List<Map<String, dynamic>> get _currentStudents {
    if (_selectedGrade == null) return [];
    return _studentsByGrade[_selectedGrade] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final students = _currentStudents;
    final total = students.length;
    final solventes = students.where((s) => s['status'] == 'solvente').length;
    final pendientes = students.where((s) => s['status'] == 'pendiente').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gestión de Pagos',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pagos y mensualidades',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registra pagos, asigna comprobantes y descarga listados por grado.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 14),

                  // grado + pdf
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;
                      if (isNarrow) {
                        return Column(
                          children: [
                            SelectField<String>(
                              label: 'Grado',
                              placeholder: 'Selecciona...',
                              value: _selectedGrade,
                              items: _grades,
                              itemLabel: (e) => e,
                              onSelected: (v) {
                                setState(() {
                                  _selectedGrade = v;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: BlackButton(
                                label: 'Descargar PDF',
                                icon: Icons.picture_as_pdf_outlined,
                                onPressed: _selectedGrade == null
                                    ? null
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => PaymentPDFDialog(
                                            grade: _selectedGrade!,
                                            students: _currentStudents,
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: SelectField<String>(
                              label: 'Grado',
                              placeholder: 'Selecciona...',
                              value: _selectedGrade,
                              items: _grades,
                              itemLabel: (e) => e,
                              onSelected: (v) {
                                setState(() {
                                  _selectedGrade = v;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          BlackButton(
                            label: 'Descargar PDF',
                            icon: Icons.picture_as_pdf_outlined,
                            onPressed: _selectedGrade == null
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => PaymentPDFDialog(
                                        grade: _selectedGrade!,
                                        students: _currentStudents,
                                      ),
                                    );
                                  },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          title: 'Total inscritos',
                          value: '$total',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          title: 'Solventes',
                          value: '$solventes',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          title: 'Pendientes',
                          value: '$pendientes',
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 🔥 botones de acción bonitos en pantallas angostas
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Acciones',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: BlackButton(
                                label: 'Registrar pago manual',
                                icon: Icons.attach_money_rounded,
                                onPressed: _selectedGrade == null
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PaymentManualPage(
                                              grade: _selectedGrade!,
                                              section: 'A',
                                              students: _currentStudents,
                                              onSaved: _onManualPaymentSaved,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: BlackButton(
                                label: 'Subir comprobante',
                                icon: Icons.upload_file_outlined,
                                onPressed: _selectedGrade == null
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PaymentUploadPage(
                                              grade: _selectedGrade!,
                                              students: _currentStudents,
                                              onUploaded: _onReceiptUploaded,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ],
                        );
                      }

                      // normal en fila
                      return Row(
                        children: [
                          Expanded(
                            child: BlackButton(
                              label: 'Registrar pago manual',
                              icon: Icons.attach_money_rounded,
                              onPressed: _selectedGrade == null
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PaymentManualPage(
                                            grade: _selectedGrade!,
                                            section: 'A',
                                            students: _currentStudents,
                                            onSaved: _onManualPaymentSaved,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BlackButton(
                              label: 'Subir comprobante',
                              icon: Icons.upload_file_outlined,
                              onPressed: _selectedGrade == null
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PaymentUploadPage(
                                            grade: _selectedGrade!,
                                            students: _currentStudents,
                                            onUploaded: _onReceiptUploaded,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedGrade == null)
              const EmptyState(
                title: 'Selecciona un grado',
                description: 'Para ver los pagos toca elegir un grado.',
                icon: Icon(Icons.school_outlined,
                    size: 48, color: Colors.black45),
              )
            else if (students.isEmpty)
              const EmptyState(
                title: 'No hay estudiantes',
                description: 'Este grado no tiene estudiantes registrados.',
                icon: Icon(Icons.people_alt_outlined,
                    size: 48, color: Colors.black45),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estudiantes del grado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...students.map((s) {
                    final isSolvente = s['status'] == 'solvente';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF3FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person_outline,
                                  color: Colors.black),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['name'],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Último pago: ${s['lastPayment'] ?? '—'}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isSolvente
                                              ? Colors.green
                                              : Colors.redAccent,
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                        child: Text(
                                          isSolvente ? 'Solvente' : 'Pendiente',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isSolvente
                                            ? 'Q${(s['amount'] as num).toStringAsFixed(2)}'
                                            : 'Debe mensualidad',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentDetailPage(
                                      student: s,
                                      grade: _selectedGrade!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _onManualPaymentSaved(
      Map<String, dynamic> student, Map<String, dynamic> paymentData) {
    setState(() {
      student['status'] = 'solvente';
      student['lastPayment'] = paymentData['month'] ?? '—';
      student['amount'] = paymentData['amount'] ?? 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pago registrado')),
    );
  }

  void _onReceiptUploaded(
      Map<String, dynamic> student, Map<String, dynamic> receiptData) {
    setState(() {
      student['status'] = 'solvente';
      student['lastPayment'] = receiptData['month'] ?? '—';
      student['amount'] = receiptData['amount'] ?? 0.0;
      student['receipt'] = receiptData;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comprobante asignado')),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  const _StatBox({
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color ?? Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
