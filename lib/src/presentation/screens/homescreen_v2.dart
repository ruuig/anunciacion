import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anunciacion/src/presentation/providers/providers.dart';
import 'package:anunciacion/src/presentation/screens/grados/grades_subjects_management_page.dart';
import 'package:anunciacion/src/presentation/screens/pagos/payments_management_screen.dart';
import 'package:anunciacion/src/presentation/screens/reports/reports_screen.dart';
import 'package:anunciacion/src/presentation/screens/estudiantes/create_edit_student_page.dart';
import 'package:anunciacion/src/presentation/screens/qr_screen.dart';
import 'package:anunciacion/src/presentation/screens/bus/bus_service_screen.dart';
import 'package:anunciacion/src/presentation/screens/config_screen.dart'
    as config;

class HomeLuxuryPageV2 extends ConsumerWidget {
  const HomeLuxuryPageV2({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final userName = userState.currentUser?.name ?? 'Usuario';
    final formattedDate = _getFormattedDate();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== Header con usuario y fecha =====
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Logo del colegio
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/logoanunciacion.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nombre y fecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola $userName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón configuración
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => config.AdministrationPage(
                              user: config.AdminUser(
                                name: userName,
                                role: 'admin',
                                permissions: ['manage_all'],
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined),
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),

              // ===== Grid de módulos =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Fila 1: Calificaciones y Pagos
                    Row(
                      children: [
                        Expanded(
                          child: _ModuleCard(
                            icon: Icons.grade_outlined,
                            title: 'Calificaciones',
                            subtitle: 'Notas y promedios',
                            color: const Color(0xFF6366F1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const GradesSubjectsManagementPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModuleCard(
                            icon: Icons.attach_money_outlined,
                            title: 'Pagos',
                            subtitle: 'Cuotas y comprobantes',
                            color: const Color(0xFF10B981),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PaymentsManagementScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fila 2: Reportes y Estudiantes
                    Row(
                      children: [
                        Expanded(
                          child: _ModuleCard(
                            icon: Icons.assessment_outlined,
                            title: 'Reportes',
                            subtitle: 'Boletas y resúmenes',
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModuleCard(
                            icon: Icons.people_outline,
                            title: 'Estudiantes',
                            subtitle: 'Gestión de alumnos',
                            color: const Color(0xFFEC4899),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateEditStudentPage(
                                      student: null),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fila 3: Asistencia y Bus
                    Row(
                      children: [
                        Expanded(
                          child: _ModuleCard(
                            icon: Icons.qr_code_2_outlined,
                            title: 'Asistencia',
                            subtitle: 'Escanear QR',
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const QrScannerPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModuleCard(
                            icon: Icons.directions_bus_outlined,
                            title: 'Bus Escolar',
                            subtitle: 'Rutas y pagos',
                            color: const Color(0xFF06B6D4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BusServiceScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
