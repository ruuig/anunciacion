import 'dart:math';

import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

class ActivitiesTabBody extends StatefulWidget {
  final String userRole;
  final List<String> assignedGrades;

  const ActivitiesTabBody({
    super.key,
    required this.userRole,
    required this.assignedGrades,
  });

  @override
  State<ActivitiesTabBody> createState() => _ActivitiesTabBodyState();
}

class _ActivitiesTabBodyState extends State<ActivitiesTabBody> {
  final subjects = ['Matemáticas', 'Español', 'Ciencias Naturales'];
  final grades = ['1ro Primaria', '2do Primaria', '3ro Primaria'];
  final sections = ['A', 'B', 'C'];
  final periods = ['Primer Bimestre', 'Segundo Bimestre'];
  final types = ['Examen', 'Tarea', 'Proyecto'];

  List<Map<String, dynamic>> activities = [
    {
      'name': 'Examen Parcial - Fracciones',
      'subject': 'Matemáticas',
      'grade': '3ro Primaria',
      'section': 'A',
      'period': 'Primer Bimestre',
      'type': 'Examen',
      'points': 25,
      'date': '2025-02-15',
      'status': 'completed',
      'studentsGraded': 24,
      'totalStudents': 28,
      'averageGrade': 78.5,
    },
    {
      'name': 'Tarea - Ejercicios de suma y resta',
      'subject': 'Matemáticas',
      'grade': '3ro Primaria',
      'section': 'A',
      'period': 'Primer Bimestre',
      'type': 'Tarea',
      'points': 10,
      'date': '2025-02-10',
      'status': 'completed',
      'studentsGraded': 28,
      'totalStudents': 28,
      'averageGrade': 85.2,
    },
    {
      'name': 'Proyecto - Sistema Solar',
      'subject': 'Ciencias Naturales',
      'grade': '4to Primaria',
      'section': 'B',
      'period': 'Primer Bimestre',
      'type': 'Proyecto',
      'points': 20,
      'date': '2025-02-20',
      'status': 'pending',
      'studentsGraded': 0,
      'totalStudents': 25,
      'averageGrade': null,
    },
  ];

  void _createActivity() {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidad de creación en desarrollo')),
      );
    } catch (e) {
      // Handle any errors silently to prevent app freezing
      print('Error creating activity: $e');
    }
  }

  void _editActivity(Map<String, dynamic> activity) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Editar: ${activity['name'] ?? 'Actividad'}')),
      );
    } catch (e) {
      print('Error editing activity: $e');
    }
  }

  void _deleteActivity(Map<String, dynamic> activity) {
    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Actividad'),
          content: Text('¿Estás seguro de que quieres eliminar "${activity['name'] ?? 'esta actividad'}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                try {
                  setState(() {
                    activities.remove(activity);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Actividad eliminada')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al eliminar actividad')),
                  );
                  print('Error deleting activity: $e');
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = activities;
    final completed = filtered.where((a) => a['status'] == 'completed').length;
    final pending = filtered.where((a) => a['status'] == 'pending').length;
    final totalPoints =
        filtered.fold<int>(0, (sum, a) => sum + ((a['points'] as int?) ?? 0));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gestión de Actividades',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text(
                      'Planifica y califica actividades académicas',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    BlackButton(
                      label: 'Crear Actividad',
                      icon: Icons.add,
                      onPressed: _createActivity,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(title: 'Completadas', value: '$completed'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(title: 'Pendientes', value: '$pending'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child:
                              _StatBox(title: 'Puntos Total', value: '$totalPoints'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // LISTA DE ACTIVIDADES
              if (activities.isEmpty)
                EmptyState(
                  title: 'No hay actividades',
                  description: 'Crea tu primera actividad para comenzar',
                  icon: const Icon(Icons.assignment_outlined,
                      size: 48, color: Colors.black45),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actividades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...activities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final a = entry.value;
                      final studentsGraded = a['studentsGraded'] as int?;
                      final totalStudents = a['totalStudents'] as int?;
                      final progress = (studentsGraded ?? 0).toDouble() /
                          max(totalStudents ?? 0, 1);
                      final avg = a['averageGrade'] as double?;
                      final done = a['status'] == 'completed';

                      return Padding(
                        key: ValueKey('${a['name']}_${index}'), // Add more specific key
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre + estado
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      a['name'] ?? 'Sin nombre',
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _StatusBadge(status: a['status'] ?? 'pending'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('${a['subject']} • ${a['grade']} ${a['section']}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${a['points']} pts  |  ${a['date']}',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black54)),
                                  if (avg != null)
                                    Text('Promedio: ${avg.toStringAsFixed(1)}',
                                        style:
                                            const TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Barra de progreso
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  color: Colors.black,
                                  backgroundColor: Colors.grey[300],
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Progreso: ${a['studentsGraded']}/${a['totalStudents']} estudiantes',
                                style:
                                    const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 10),

                              // Botones acción
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _editActivity(a),
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.black),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteActivity(a),
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.black),
                                  ),
                                  const SizedBox(width: 8),
                                  BlackButton(
                                    label: done ? 'Ver Notas' : 'Calificar',
                                    onPressed: () {
                                      try {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '${done ? 'Ver' : 'Calificar'} ${a['name'] ?? 'actividad'}')),
                                        );
                                      } catch (e) {
                                        print('Error showing snackbar: $e');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  const _StatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get color {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get text {
    switch (status) {
      case 'completed':
        return 'Completada';
      case 'pending':
        return 'Pendiente';
      default:
        return 'Sin estado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
