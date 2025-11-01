import 'package:flutter/material.dart';

// entidad
import 'package:anunciacion/src/domain/entities/activity.dart';

// páginas que ya hicimos
import 'package:anunciacion/src/presentation/screens/actividades/create_edit_activity_page.dart';
import 'package:anunciacion/src/presentation/screens/actividades/grade_activity_page.dart';

// tus widgets compartidos
import 'package:anunciacion/src/presentation/widgets/widgets.dart';

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
  // catálogos base (luego se pueden traer del backend)
  final List<String> _subjects = const [
    'Matemáticas',
    'Español',
    'Ciencias Naturales',
  ];
  final List<String> _gradesCatalog = const [
    '1ro Primaria',
    '2do Primaria',
    '3ro Primaria',
    '4to Primaria',
  ];
  final List<String> _sections = const ['A', 'B', 'C'];
  final List<String> _periodsCatalog = const [
    'Primer Bimestre',
    'Segundo Bimestre',
  ];
  final List<String> _types = const ['Examen', 'Tarea', 'Proyecto'];

  // lista mock de actividades **usando la entidad**
  List<Activity> _activities = [
    Activity(
      id: 1,
      name: 'Examen Parcial - Fracciones',
      description: 'Evaluación de fracciones y operaciones básicas',
      subject: 'Matemáticas',
      grade: '3ro Primaria',
      section: 'A',
      period: 'Primer Bimestre',
      type: 'Examen',
      points: 25,
      date: DateTime(2025, 2, 15),
      status: 'completed',
      studentsGraded: 24,
      totalStudents: 28,
      averageGrade: 78.5,
      isGroupWork: false,
      groups: const [],
    ),
    Activity(
      id: 2,
      name: 'Tarea - Ejercicios de suma y resta',
      description: 'Tarea corta de refuerzo',
      subject: 'Matemáticas',
      grade: '3ro Primaria',
      section: 'A',
      period: 'Primer Bimestre',
      type: 'Tarea',
      points: 10,
      date: DateTime(2025, 2, 10),
      status: 'completed',
      studentsGraded: 28,
      totalStudents: 28,
      averageGrade: 85.2,
      isGroupWork: false,
      groups: const [],
    ),
    Activity(
      id: 3,
      name: 'Proyecto - Sistema Solar',
      description: 'Cada grupo debe exponer un planeta',
      subject: 'Ciencias Naturales',
      grade: '4to Primaria',
      section: 'B',
      period: 'Primer Bimestre',
      type: 'Proyecto',
      points: 20,
      date: DateTime(2025, 2, 20),
      status: 'pending',
      studentsGraded: 0,
      totalStudents: 25,
      averageGrade: null,
      isGroupWork: true,
      groups: [
        ActivityGroup(name: 'Grupo 1', members: ['Ana', 'Carlos']),
        ActivityGroup(name: 'Grupo 2', members: ['Diego', 'Sofía', 'Luis']),
      ],
    ),
  ];

  // --------------------------------------------------
  // ACCIONES
  // --------------------------------------------------

  Future<void> _createActivity() async {
    final created = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditActivityPage(
          name: 'Nueva actividad',
          grades: _gradesCatalog,
          periods: _periodsCatalog,
          subjects: _subjects,
          sections: _sections,
        ),
      ),
    );

    if (created != null) {
      setState(() {
        _activities.add(
          created.copyWith(
            status: 'pending',
            studentsGraded: 0,
            totalStudents: created.totalStudents == 0
                ? 28
                : created.totalStudents, // default
            averageGrade: null,
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad creada')),
      );
    }
  }

  Future<void> _editActivity(Activity activity) async {
    final updated = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditActivityPage(
          name: 'Editar actividad',
          initial: activity,
          grades: _gradesCatalog,
          periods: _periodsCatalog,
          subjects: _subjects,
          sections: _sections,
        ),
      ),
    );

    if (updated != null) {
      setState(() {
        _activities = _activities.map((a) {
          if (a.id == updated.id) return updated;
          return a;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad actualizada')),
      );
    }
  }

  void _deleteActivity(Activity activity) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: Text('¿Seguro que quieres eliminar "${activity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _activities.removeWhere((a) => a.id == activity.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actividad eliminada')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openGrade(Activity activity) async {
    final graded = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => GradeActivityPage(
          name: 'Calificar Actividad',
          initial: activity,
          grades: _gradesCatalog,
          periods: _periodsCatalog,
        ),
      ),
    );

    if (graded != null) {
      setState(() {
        _activities = _activities.map((a) {
          if (a.id == graded.id) return graded;
          return a;
        }).toList();
      });
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final completed = _activities.where((a) => a.status == 'completed').length;
    final pending = _activities.where((a) => a.status == 'pending').length;
    final totalPoints = _activities.fold<int>(0, (sum, a) => sum + a.points);

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
                    const Text(
                      'Gestión de Actividades',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Planifica y califica actividades académicas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlackButton(
                      label: 'Crear actividad',
                      icon: Icons.add_rounded,
                      onPressed: _createActivity,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                              title: 'Completadas', value: '$completed'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child:
                              _StatBox(title: 'Pendientes', value: '$pending'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                              title: 'Puntos Total', value: '$totalPoints'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_activities.isEmpty)
                const EmptyState(
                  title: 'No hay actividades',
                  description: 'Crea tu primera actividad para comenzar',
                  icon: Icon(Icons.assignment_outlined,
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
                    ..._activities.map((a) {
                      final progress = a.totalStudents == 0
                          ? 0.0
                          : a.studentsGraded / a.totalStudents;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // título
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _StatusBadge(status: a.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${a.subject} • ${a.grade} ${a.section}${a.isGroupWork ? ' • Trabajo grupal' : ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              if (a.description != null &&
                                  a.description!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    a.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${a.points} pts  |  ${_fmtDate(a.date)}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black54),
                                  ),
                                  if (a.averageGrade != null)
                                    Text(
                                      'Promedio: ${a.averageGrade!.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
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
                                'Progreso: ${a.studentsGraded}/${a.totalStudents} estudiantes',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 10),
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
                                    label: a.status == 'completed'
                                        ? 'Ver notas'
                                        : 'Calificar',
                                    onPressed: () => _openGrade(a),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600),
          ),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
