import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    this.title = 'Selecciona todos los campos',
    this.subtitle = 'Completa la información para ver la lista de estudiantes',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFF0F1F3),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.black45, size: 36),
          ),
          const SizedBox(height: 14),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
