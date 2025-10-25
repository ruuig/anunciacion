import 'package:flutter/material.dart';

class SummaryRow extends StatelessWidget {
  final int approved;
  final int failed;
  final int pending;

  const SummaryRow({
    super.key,
    required this.approved,
    required this.failed,
    required this.pending,
  });

  Widget _cell(String t, int v) => Column(
        children: [
          Text(t,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('$v',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _cell('Aprobados', approved),
        _cell('Reprobados', failed),
        _cell('Pendientes', pending),
      ],
    );
  }
}
