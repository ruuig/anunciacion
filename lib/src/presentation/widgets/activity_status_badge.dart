import 'package:flutter/material.dart';

class ActivityStatusBadge extends StatelessWidget {
  final String status;
  const ActivityStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'grading':
        return Colors.orange;
      default:
        return Colors.black87;
    }
  }

  String get _text {
    switch (status) {
      case 'completed':
        return 'Completada';
      case 'grading':
        return 'Calificando';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}
