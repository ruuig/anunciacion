import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// DOMAIN + USE CASES
import 'package:anunciacion/src/domain/entities/activity.dart';
import 'package:anunciacion/src/application/use_cases/get_activities.dart';
import 'package:anunciacion/src/application/use_cases/create_activity.dart';
import 'package:anunciacion/src/application/use_cases/update_activity.dart';
import 'package:anunciacion/src/application/use_cases/delete_activity.dart';

// SCREENS
import 'package:anunciacion/src/presentation/screens/actividades/create_edit_activity_page.dart';
import 'package:anunciacion/src/presentation/screens/actividades/grade_activity_page.dart';

// WIDGETS
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/presentation/widgets/activity_status_badge.dart';

class ActivitiesScreen extends StatefulWidget {
  final String userRole;
  final List<String> assignedGrades;

  const ActivitiesScreen({
    super.key,
    required this.userRole,
    this.assignedGrades = const [],
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _sl = GetIt.instance;

  late final GetActivities _getActivities;
  late final CreateActivity _createActivity;
  late final UpdateActivity _updateActivity;
  late final DeleteActivity _deleteActivity;

  List<Activity> _activities = [];
  bool _loading = true;

  // filtros
  String? _selectedGrade;
  String? _selectedPeriod;

  // catálogos simulados (luego los vas a traer del backend)
  final List<String> _gradesCatalog = const [
    '1ro Primaria',
    '2do Primaria',
    '3ro Primaria',
    '4to Primaria',
    '5to Primaria',
    '6to Primaria',
  ];

  final List<String> _periodsCatalog = const [
    'Primer Bimestre',
    'Segundo Bimestre',
    'Tercer Bimestre',
    'Cuarto Bimestre',
  ];

  // 👇 estos eran los que faltaban
  final List<String> _subjects = const [
    'Matemáticas',
    'Español',
    'Ciencias Naturales',
    'Estudios Sociales',
    'Inglés',
  ];

  final List<String> _sections = const [
    'A',
    'B',
    'C',
  ];

  @override
  void initState() {
    super.initState();
    _getActivities = _sl<GetActivities>();
    _createActivity = _sl<CreateActivity>();
    _updateActivity = _sl<UpdateActivity>();
    _deleteActivity = _sl<DeleteActivity>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _getActivities();
    setState(() {
      _activities = items;
      _loading = false;
    });
  }

  List<Activity> get _filteredActivities {
    return _activities.where((a) {
      final okGrade = _selectedGrade == null || a.grade == _selectedGrade;
      final okPeriod = _selectedPeriod == null || a.period == _selectedPeriod;
      return okGrade && okPeriod;
    }).toList();
  }

  Future<void> _goToCreate() async {
    final created = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => GradeActivityPage(
          name: 'Nueva actividad',
          grades: _gradesCatalog,
          periods: _periodsCatalog,
        ),
      ),
    );
    if (created != null) {
      final saved = await _createActivity(created);
      setState(() => _activities.add(saved));
    }
  }

  Future<void> _goToEdit(Activity activity) async {
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
      await _updateActivity(updated);
      setState(() {
        _activities = _activities.map((a) {
          return a.id == updated.id ? updated : a;
        }).toList();
      });
    }
  }

  Future<void> _goToGrade(Activity activity) async {
    // si tu GradeActivityPage SOLO recibe activity, deja esto así:
    final graded = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => GradeActivityPage(
          name: 'Editar actividad',
          initial: activity,
          grades: _gradesCatalog,
          periods: _periodsCatalog,
        ),
      ),
    );

    // si tu GradeActivityPage también necesita catálogos, usa esto mejor:
    // builder: (_) => GradeActivityPage(
    //   activity: activity,
    //   grades: _gradesCatalog,
    //   periods: _periodsCatalog,
    // ),

    if (graded != null) {
      await _updateActivity(graded);
      setState(() {
        _activities = _activities.map((a) {
          return a.id == graded.id ? graded : a;
        }).toList();
      });
    }
  }

  Future<void> _confirmDelete(Activity activity) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: Text('¿Querés eliminar "${activity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteActivity(activity.id);
      setState(() => _activities.removeWhere((a) => a.id == activity.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredActivities;
    final completed = filtered.where((a) => a.status == 'completed').length;
    final pending = filtered.where((a) => a.status == 'pending').length;
    final totalPoints = filtered.fold<int>(0, (s, a) => s + a.points);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    backgroundColor: Colors.white,
                    floating: true,
                    pinned: true,
                    title: Text(
                      'Gestión de Actividades',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Resumen
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resumen',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatBox(
                                        title: 'Completadas',
                                        value: '$completed',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatBox(
                                        title: 'Pendientes',
                                        value: '$pending',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatBox(
                                        title: 'Puntos total',
                                        value: '$totalPoints',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                BlackButton(
                                  label: 'Nueva actividad',
                                  icon: Icons.add_rounded,
                                  onPressed: _goToCreate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Filtros
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Filtros',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SelectField<String>(
                                        label: 'Grado',
                                        placeholder: 'Todos los grados',
                                        value: _selectedGrade,
                                        items: _gradesCatalog,
                                        itemLabel: (e) => e,
                                        onSelected: (v) =>
                                            setState(() => _selectedGrade = v),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SelectField<String>(
                                        label: 'Periodo',
                                        placeholder: 'Todos los periodos',
                                        value: _selectedPeriod,
                                        items: _periodsCatalog,
                                        itemLabel: (e) => e,
                                        onSelected: (v) =>
                                            setState(() => _selectedPeriod = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Lista
                          if (filtered.isEmpty)
                            const EmptyState(
                              title: 'No hay actividades',
                              description: 'Crea tu primera actividad',
                              icon: Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.black54,
                              ),
                            )
                          else
                            Column(
                              children: filtered.map((a) {
                                final progress = a.totalStudents == 0
                                    ? 0.0
                                    : a.studentsGraded / a.totalStudents;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: AppCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF3FF),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: const Icon(
                                                Icons.menu_book_outlined,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          a.name,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      ActivityStatusBadge(
                                                        status: a.status,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${a.subject} • ${a.grade} ${a.section}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _goToEdit(a),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _confirmDelete(a),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${a.points} pts • ${_fmtDate(a.date)}',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                            if (a.averageGrade != null)
                                              Text(
                                                'Promedio: ${a.averageGrade!.toStringAsFixed(1)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(99),
                                          child: LinearProgressIndicator(
                                            value: progress.clamp(0, 1),
                                            minHeight: 8,
                                            color: Colors.black,
                                            backgroundColor: Colors.grey[200],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Progreso: ${a.studentsGraded}/${a.totalStudents}',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                            BlackButton(
                                              label: a.status == 'completed'
                                                  ? 'Ver notas'
                                                  : 'Calificar',
                                              onPressed: () => _goToGrade(a),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
