import 'package:flutter/material.dart';

class ReportAttendancePage extends StatelessWidget {
  const ReportAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('AttendanceReporte', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Contenido de ReportAttendancePage'),
      ),
    );
  }
}