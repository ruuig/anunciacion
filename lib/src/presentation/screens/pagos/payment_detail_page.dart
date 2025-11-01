import 'package:flutter/material.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';

class PaymentDetailPage extends StatelessWidget {
  final Map<String, dynamic> student;
  final String grade;

  const PaymentDetailPage({
    super.key,
    required this.student,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final isSolvente = student['status'] == 'solvente';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          student['name'],
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información del alumno',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text('Grado: $grade',
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text('Estado: ${isSolvente ? 'Solvente' : 'Pendiente'}'),
                const SizedBox(height: 4),
                Text('Último pago: ${student['lastPayment'] ?? '—'}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial de pagos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aquí puedes listar los pagos reales que vengan del backend.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
