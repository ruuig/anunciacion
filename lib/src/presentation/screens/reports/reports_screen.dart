import 'package:anunciacion/src/presentation/screens/reports/report_grades_page.dart';
import 'package:anunciacion/src/presentation/screens/reports/report_payments_page.dart';
import 'package:flutter/material.dart';
import 'general_reports_screen.dart';
import '../grados/grades_subjects_management_page.dart';
import '../pagos/payments_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Tipamos correctamente la lista de mapas
    final List<Map<String, dynamic>> reports = [
      {
        'title': 'Notas académicas',
        'icon': Icons.grade_outlined,
        'page': const ReportGradesPage(),
      },
      {
        'title': 'Pagos y solvencias',
        'icon': Icons.attach_money_outlined,
        'page': const ReportPaymentsPage(),
      },
      {
        'title': 'Resumen general',
        'icon': Icons.dashboard_customize_outlined,
        'page': const GeneralReportsScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Reportes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, i) {
          // ✅ Separamos los valores con cast seguro
          final String title = reports[i]['title'] as String;
          final IconData icon = reports[i]['icon'] as IconData;
          final Widget page = reports[i]['page'] as Widget;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF3FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
