import 'package:flutter/material.dart';

class ReportPaymentsPage extends StatelessWidget {
  const ReportPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('PaymentsReporte', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Contenido de ReportPaymentsPage'),
      ),
    );
  }
}