import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Header con forma ondulada + gradiente + logo circular.
/// `collapse` va de 0 (expandido) a 1 (colapsado).
class CustomAppBAr extends StatelessWidget {
  const CustomAppBAr({
    super.key,
    required this.collapse,
    required this.name,
    required this.logoAsset,
  });

  final double collapse;
  final String name;
  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    // Tamaño del logo animado según colapso
    final double maxLogo = 84; // más grande al expandir
    final double minLogo = 84; // tamaño al colapsar
    final double logoSize = lerpDouble(maxLogo, minLogo, collapse) ?? minLogo;

    final showGreeting = collapse < 0.55; // oculta por completo al colapsar

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
                  Color.fromARGB(255, 91, 219, 215),
                  Color.fromARGB(255, 54, 45, 223),
                  Color.fromARGB(255, 224, 213, 58)
                  /*Color(0xFFEA445A),
                  Color(0xFFF37161),
                  Color(0xFFF9A856)*/
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // Contenido superior
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bloque de saludo (se oculta por completo al colapsar)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: showGreeting
                      ? const _GreetingBlock(key: ValueKey('greet'))
                      : const SizedBox(key: ValueKey('empty')),
                ),
              ),

              // Logo circular (en lugar de la nube)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.92),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.65),
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
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: showGreeting ? 1 : 0,
                    child: const Text(
                      'Bienvenido',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Barra compacta (aparece al colapsar) con más altura visual
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            // La altura visual de la barra compacta la controla SliverAppBar.collapsedHeight
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.transparent,
            child: Row(
              children: [
                AnimatedOpacity(
                  opacity: collapse.clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Avatar opcional al colapsar (quítalo si no lo quieres)
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=Maria+G&background=E5E7EB&color=111827',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Good Morning',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
        SizedBox(height: 4),
        Text(
          'María González',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

/// Clipper de la curva superior (onda)
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
