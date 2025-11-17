import 'dart:math';
import 'package:anunciacion/src/presentation/screens/config_screen.dart';
import 'package:anunciacion/src/presentation/screens/notas_page.dart';
import 'package:anunciacion/src/presentation/screens/qr_screen.dart';
import 'package:anunciacion/src/presentation/screens/reports/reports_screen.dart';
import 'package:anunciacion/src/presentation/screens/StudentsPage.dart';
import 'package:anunciacion/src/presentation/screens/bus/bus_service_screen.dart';
import 'package:anunciacion/src/presentation/screens/pagos/payments_management_screen.dart';
import 'package:anunciacion/src/presentation/screens/grados/grades_subjects_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anunciacion/src/presentation/widgets/CustomCard.dart';
import 'package:anunciacion/src/presentation/providers/providers.dart';

// Constantes para roles
const int ROLE_ADMIN = 1;
const int ROLE_DOCENTE = 2;

class HomeLuxuryPage extends ConsumerStatefulWidget {
  const HomeLuxuryPage({super.key});

  @override
  ConsumerState<HomeLuxuryPage> createState() => _HomeLuxuryPageState();
}

class _HomeLuxuryPageState extends ConsumerState<HomeLuxuryPage> {
  double _collapsePercent(double t, double max) => (t / max).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    const expandedHeight = 180.0;
    const collapsedHeight = 100.0;

    final userState = ref.watch(userProvider);
    final userRoleId = userState.currentUser?.roleId ?? 0;
    final isAdmin = userRoleId == ROLE_ADMIN;
    final isDocente = userRoleId == ROLE_DOCENTE;

    // Construir lista de menús según el rol
    final menuItems = _buildMenuItems(isAdmin, isDocente);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: NotificationListener<ScrollNotification>(
        onNotification: (_) => false,
        child: CustomScrollView(
          slivers: [
            // === SliverAppBar con forma ondulada y logo fijo ===
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, c) {
                  final h = c.constrainHeight();
                  final percent = 1 -
                      _collapsePercent(
                        max(0, h - collapsedHeight),
                        expandedHeight - collapsedHeight,
                      );
                  return _WaveHeaderConsumer(
                    collapse: percent,
                    logoAsset: 'assets/logoanunciacion.png',
                  );
                },
              ),
            ),

            // ======= Grid de accesos =======
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildListDelegate(menuItems),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(bool isAdmin, bool isDocente) {
    final items = <Widget>[];

    // Calificaciones - Solo para Docente
    if (isDocente) {
      items.add(
        CustomCard(
          imageUrl: 'assets/notas.png',
          title: 'Calificaciones',
          description: 'Consulta y registra notas por curso',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotasPage(userRole: 'Docente'),
              ),
            );
          },
        ),
      );
    }

    // Pagos - Solo Admin
    if (isAdmin) {
      items.add(
        CustomCard(
          imageUrl: 'assets/descarga.png',
          title: 'Pagos',
          description: 'Cuotas, estados y comprobantes',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentsManagementScreen(),
              ),
            );
          },
        ),
      );
    }

    // Reportes - Solo Admin
    if (isAdmin) {
      items.add(
        CustomCard(
          imageUrl: 'assets/reportes.png',
          title: 'Reportes',
          description: 'Promedios y boletas por grado',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(),
              ),
            );
          },
        ),
      );
    }

    // Estudiantes - Visible para Admin y Docente
    if (isAdmin || isDocente) {
      items.add(
        CustomCard(
          imageUrl: 'assets/estudiantes.png',
          title: 'Estudiantes',
          description: 'Perfiles, asistencia y familiares',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentsPage(),
              ),
            );
          },
        ),
      );
    }

    // Registro Entrada y Salida - Visible para Admin y Docente
    if (isAdmin || isDocente) {
      items.add(
        CustomCard(
          imageUrl: 'assets/asistencia.png',
          title: 'Registro Entrada y Salida',
          description: 'Registrar horarios de entrada y salida',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QrScannerPage(),
              ),
            );
          },
        ),
      );
    }

    // Configuración - Solo Admin
    if (isAdmin) {
      items.add(
        CustomCard(
          imageUrl: 'assets/configuracion.png',
          title: 'Configuración',
          description: 'Preferencias y usuarios',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdministrationPage(
                    user: AdminUser(name: 'Admin', role: 'Admin', permissions: [
                  'manage_users',
                  'manage_grades',
                  'edit_students',
                  'view_all'
                ])),
              ),
            );
          },
        ),
      );
    }

    return items;
  }
}

/// ===================== WAVE HEADER CONSUMER =====================

class _WaveHeaderConsumer extends ConsumerWidget {
  const _WaveHeaderConsumer({
    required this.collapse,
    required this.logoAsset,
  });

  final double collapse;
  final String logoAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final fullName = userState.currentUser?.name ?? 'Usuario';

    return _WaveHeader(
      collapse: collapse,
      logoAsset: logoAsset,
      fullName: fullName,
    );
  }
}

/// ===================== WAVE HEADER =====================

class _WaveHeader extends StatelessWidget {
  const _WaveHeader({
    required this.collapse,
    required this.logoAsset,
    required this.fullName,
  });

  final double collapse;
  final String logoAsset;
  final String fullName;

  String get name {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts[0] : 'Usuario';
  }

  String get lastName {
    final parts = fullName.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  @override
  Widget build(BuildContext context) {
    // control visual de opacidad
    final double opacity = (1 - collapse).clamp(0.0, 1.0);

    // desplazamiento suave del texto
    final double moveUp = collapse * 20;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo con curva
        ClipPath(
          clipper: _WaveClipper(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEA445A),
                  Color(0xFFF37161),
                  Color(0xFFF9A856)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // Contenido
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 30, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Texto (saludo + nombre)
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, -moveUp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (opacity > 0.5)
                        Opacity(
                          opacity: opacity,
                          child: const Text(
                            'Buenos días',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: '$name\n',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                          children: [
                            TextSpan(
                              text: lastName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Logo circular (ya no cambia de tamaño)
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.92),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  image: DecorationImage(
                    image: AssetImage(logoAsset),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Clipper para la curva superior (onda)
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()..lineTo(0, size.height * 0.75);
    p.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.97,
      size.width * 0.50,
      size.height * 0.86,
    );
    p.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.74,
      size.width,
      size.height * 0.90,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
