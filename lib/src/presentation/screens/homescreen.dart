import 'dart:math';
import 'package:anunciacion/src/presentation/screens/StudentsPage.dart';
import 'package:anunciacion/src/presentation/screens/config_screen.dart';
import 'package:anunciacion/src/presentation/screens/qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:anunciacion/src/presentation/widgets/CustomCard.dart';
import 'package:anunciacion/src/presentation/widgets/bottomBar.dart';
import 'notas_page.dart';

class HomeLuxuryPage extends StatefulWidget {
  const HomeLuxuryPage({super.key});

  @override
  State<HomeLuxuryPage> createState() => _HomeLuxuryPageState();
}

class _HomeLuxuryPageState extends State<HomeLuxuryPage> {
  int _tab = 0;

  double _collapsePercent(double t, double max) => (t / max).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    const expandedHeight = 180.0;
    const collapsedHeight = 100.0;

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
                  return _WaveHeader(
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
                delegate: SliverChildListDelegate([
                  CustomCard(
                    imageUrl: 'assets/notas.png',
                    title: 'Calificaciones',
                    description: 'Consulta y registra notas por curso',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotasPage(
                            userRole: 'Docente',
                            assignedGrades: ['1ro Primaria', '2do Primaria'],
                          ),
                        ),
                      );
                    },
                  ),
                  CustomCard(
                    imageUrl: 'assets/descarga.png',
                    title: 'Pagos',
                    description: 'Cuotas, estados y comprobantes',
                    onTap: () {},
                  ),
                  CustomCard(
                    imageUrl: 'assets/reportes.png',
                    title: 'Reportes',
                    description: 'Promedios y boletas por grado',
                    onTap: () {},
                  ),
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
                  CustomCard(
                    imageUrl: 'assets/configuracion.png',
                    title: 'Configuración',
                    description: 'Preferencias y usuarios',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdministrationPage(
                              user: AdminUser(
                                  name: 'Admin',
                                  role: 'Admin',
                                  permissions: [
                                'manage_users',
                                'manage_grades',
                                'edit_students',
                                'view_all'
                              ])),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),

      // ======= Bottom bar elegante =======
      bottomNavigationBar: BottomBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// ===================== WAVE HEADER =====================

class _WaveHeader extends StatelessWidget {
  const _WaveHeader({
    required this.collapse,
    required this.logoAsset,
  });

  final double collapse;
  final String name = 'María';
  final String lastName = 'González';
  final String logoAsset;

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
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                          children: [
                            TextSpan(
                              text: lastName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
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
