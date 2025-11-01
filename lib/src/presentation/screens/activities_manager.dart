import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ⚠️ importa tus propios widgets reales:
import 'package:anunciacion/src/presentation/presentation.dart';
import 'package:anunciacion/src/presentation/widgets/students_grade_raw.dart';
// el que llamaste "seleccion title" yo lo escribo igual que tú lo tenías
import 'package:anunciacion/src/presentation/widgets/seleccion title.dart';
import 'package:anunciacion/src/presentation/widgets/sumary-raw.dart';

/// =========================================================
/// 1. MODELO: Activity
/// =========================================================
class Activity {
  final int id;
  final String name;
  final String subject;
  final String grade;
  final String section;
  final String period;
  final String type; // Examen, Tarea, Proyecto, etc.
  final int points;
  final DateTime date;
  final String status; // completed | pending | grading
  final int studentsGraded;
  final int totalStudents;
  final double? averageGrade;

  // extras
  final String? description;
  final bool isGroupWork;
  final List<GroupActivity> groups;

  Activity({
    required this.id,
    required this.name,
    required this.subject,
    required this.grade,
    required this.section,
    required this.period,
    required this.type,
    required this.points,
    required this.date,
    required this.status,
    required this.studentsGraded,
    required this.totalStudents,
    required this.averageGrade,
    this.description,
    this.isGroupWork = false,
    this.groups = const [],
  });

  Activity copyWith({
    String? name,
    String? subject,
    String? grade,
    String? section,
    String? period,
    String? type,
    int? points,
    DateTime? date,
    String? status,
    int? studentsGraded,
    int? totalStudents,
    double? averageGrade,
    String? description,
    bool? isGroupWork,
    List<GroupActivity>? groups,
  }) {
    return Activity(
      id: id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      period: period ?? this.period,
      type: type ?? this.type,
      points: points ?? this.points,
      date: date ?? this.date,
      status: status ?? this.status,
      studentsGraded: studentsGraded ?? this.studentsGraded,
      totalStudents: totalStudents ?? this.totalStudents,
      // truco: si averageGrade viene explícitamente como null => se pone null
      averageGrade: averageGrade != null ? averageGrade : this.averageGrade,
      description: description ?? this.description,
      isGroupWork: isGroupWork ?? this.isGroupWork,
      groups: groups ?? this.groups,
    );
  }

  // si luego quieres pasar JSON de tu DB:
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int,
      name: map['name'] as String,
      subject: map['subject'] as String,
      grade: map['grade'] as String,
      section: map['section'] as String,
      period: map['period'] as String,
      type: map['type'] as String,
      points: map['points'] as int,
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String,
      studentsGraded: map['studentsGraded'] as int? ?? 0,
      totalStudents: map['totalStudents'] as int? ?? 0,
      averageGrade: (map['averageGrade'] as num?)?.toDouble(),
      description: map['description'] as String?,
      isGroupWork: map['isGroupWork'] as bool? ?? false,
      groups: (map['groups'] as List?)
              ?.map((g) => GroupActivity.fromMap(g as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'grade': grade,
      'section': section,
      'period': period,
      'type': type,
      'points': points,
      'date': date.toIso8601String(),
      'status': status,
      'studentsGraded': studentsGraded,
      'totalStudents': totalStudents,
      'averageGrade': averageGrade,
      'description': description,
      'isGroupWork': isGroupWork,
      'groups': groups.map((g) => g.toMap()).toList(),
    };
  }
}

/// modelo chiquito para los grupos
class GroupActivity {
  final String name;
  final List<String> members;
  final double? grade; // nota del grupo en puntos

  GroupActivity({
    required this.name,
    this.members = const [],
    this.grade,
  });

  GroupActivity copyWith({
    String? name,
    List<String>? members,
    double? grade,
  }) {
    return GroupActivity(
      name: name ?? this.name,
      members: members ?? this.members,
      grade: grade ?? this.grade,
    );
  }

  factory GroupActivity.fromMap(Map<String, dynamic> map) {
    return GroupActivity(
      name: map['name'] as String? ?? 'Grupo',
      members: (map['members'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      grade: (map['grade'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
      'grade': grade,
    };
  }
}

/// =========================================================
/// 2. SCREEN PRINCIPAL
/// =========================================================
class FullActivitiesTabBody extends StatefulWidget {
  final String userRole;
  final List<String> assignedGrades;
  const FullActivitiesTabBody({
    super.key,
    required this.userRole,
    this.assignedGrades = const [],
  });

  @override
  State<FullActivitiesTabBody> createState() => _FullActivitiesTabBodyState();
}

class _FullActivitiesTabBodyState extends State<FullActivitiesTabBody> {
  // catálogos
  final subjects = const [
    'Matemáticas',
    'Español',
    'Ciencias Naturales',
    'Estudios Sociales',
    'Inglés'
  ];
  final grades = const [
    '1ro Primaria',
    '2do Primaria',
    '3ro Primaria',
    '4to Primaria',
    '5to Primaria',
    '6to Primaria'
  ];
  final sections = const ['A', 'B', 'C'];
  final periods = const [
    'Primer Bimestre',
    'Segundo Bimestre',
    'Tercer Bimestre',
    'Cuarto Bimestre'
  ];
  final types = const [
    'Examen',
    'Tarea',
    'Proyecto',
    'Laboratorio',
    'Presentación',
    'Quiz'
  ];

  // lista de actividades ya como CLASE
  List<Activity> activities = [
    Activity(
      id: 1,
      name: 'Examen Parcial - Fracciones',
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
      description: 'Evaluar fracciones propias e impropias.',
    ),
    Activity(
      id: 2,
      name: 'Tarea - Suma y resta',
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
    ),
    Activity(
      id: 3,
      name: 'Proyecto - Sistema Solar',
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
        GroupActivity(name: 'Grupo 1', members: ['Ana', 'Carlos']),
        GroupActivity(name: 'Grupo 2', members: ['Diego', 'Sofía', 'Luis']),
      ],
      description: 'Maqueta + exposición en clase.',
    ),
  ];

  // Filtros
  String? selectedGrade;
  String? selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.userRole == 'Docente';
    final availableGrades = isTeacher && widget.assignedGrades.isNotEmpty
        ? grades.where(widget.assignedGrades.contains).toList()
        : grades;

    final filtered = activities.where((a) {
      final okGrade = selectedGrade == null || a.grade == selectedGrade;
      final okPeriod = selectedPeriod == null || a.period == selectedPeriod;
      return okGrade && okPeriod;
    }).toList();

    final completed = filtered.where((a) => a.status == 'completed').length;
    final pending = filtered.where((a) => a.status == 'pending').length;
    final totalPoints = filtered.fold<int>(0, (sum, a) => sum + a.points);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HEADER + STATS
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Gestión de Actividades'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    BlackButton(
                      label: 'Nueva Actividad',
                      icon: Icons.add_rounded,
                      onPressed: () async {
                        final created = await showModalBottomSheet<Activity>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          builder: (_) => FractionallySizedBox(
                            heightFactor: 0.7,
                            child: ActivityFormSheet(
                              subjects: subjects,
                              grades: availableGrades,
                              sections: sections,
                              periods: periods,
                              types: types,
                            ),
                          ),
                        );
                        if (created != null) {
                          setState(() {
                            activities.add(
                              created.copyWith(
                                status: 'pending',
                                studentsGraded: 0,
                                totalStudents: 28,
                                averageGrade: null,
                              ),
                            );
                          });
                        }
                      },
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child:
                          _StatBox(title: 'Completadas', value: '$completed'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(title: 'Pendientes', value: '$pending'),
                    ),
                    const SizedBox(width: 10),
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

          // FILTROS
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtros',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SelectField<String>(
                        label: 'Grado',
                        placeholder: 'Todos los grados',
                        value: selectedGrade,
                        items: availableGrades,
                        itemLabel: (e) => e.isEmpty ? 'Todos' : e,
                        onSelected: (e) => setState(
                            () => selectedGrade = e.isEmpty ? null : e),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectField<String>(
                        label: 'Periodo',
                        placeholder: 'Todos los periodos',
                        value: selectedPeriod,
                        items: periods,
                        itemLabel: (e) => e.isEmpty ? 'Todos' : e,
                        onSelected: (e) => setState(
                            () => selectedPeriod = e.isEmpty ? null : e),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // LISTA
          if (filtered.isEmpty)
            const EmptyState(title: 'No hay actividades')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final a = filtered[i];
                return AppCard(
                  child: Column(
                    children: [
                      // header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TypeIcon(type: a.type),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  runSpacing: 4,
                                  children: [
                                    Text(a.name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900)),
                                    const SizedBox(width: 8),
                                    _StatusBadge(status: a.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _InfoRow(
                                  icon: Icons.menu_book_outlined,
                                  text: a.subject,
                                ),
                                _InfoRow(
                                  icon: Icons.people_alt_outlined,
                                  text: '${a.grade} - Sección ${a.section}'
                                      '${a.isGroupWork ? ' • Trabajo grupal' : ''}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              _IconSquareButton(
                                icon: Icons.edit_outlined,
                                onPressed: () async {
                                  final updated =
                                      await showModalBottomSheet<Activity>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                    ),
                                    builder: (_) => FractionallySizedBox(
                                      heightFactor: 0.7,
                                      child: ActivityFormSheet(
                                        initial: a,
                                        subjects: subjects,
                                        grades: availableGrades,
                                        sections: sections,
                                        periods: periods,
                                        types: types,
                                      ),
                                    ),
                                  );
                                  if (updated != null) {
                                    setState(() {
                                      activities = activities
                                          .map(
                                              (x) => x.id == a.id ? updated : x)
                                          .toList();
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              _IconSquareButton(
                                icon: Icons.delete_outline_rounded,
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Eliminar actividad',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900)),
                                      content: const Text(
                                          '¿Seguro que deseas eliminar esta actividad?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    setState(() {
                                      activities
                                          .removeWhere((x) => x.id == a.id);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // detalles inferiores
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _InfoRow(
                                      icon: Icons.event_outlined,
                                      text: _fmtDate(a.date),
                                    ),
                                    _InfoRow(
                                      icon: Icons.track_changes_outlined,
                                      text: '${a.points} pts',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _ProgressLine(
                                  ratio: a.totalStudents == 0
                                      ? 0
                                      : a.studentsGraded / a.totalStudents,
                                  done: a.status == 'completed',
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progreso: ${a.studentsGraded}/${a.totalStudents}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (a.averageGrade != null)
                                      Text(
                                        'Promedio: ${a.averageGrade!.toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          BlackButton(
                            label: a.status == 'completed'
                                ? 'Ver Notas'
                                : 'Calificar',
                            onPressed: () async {
                              final result =
                                  await showModalBottomSheet<Activity>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(18)),
                                ),
                                builder: (_) => FractionallySizedBox(
                                  heightFactor: 0.8,
                                  child: GradeActivitySheet(activity: a),
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  activities = activities
                                      .map((x) => x.id == a.id ? result : x)
                                      .toList();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// =========================================================
/// 3. FORM SHEET (CREAR / EDITAR)
/// =========================================================
class ActivityFormSheet extends StatefulWidget {
  final Activity? initial;
  final List<String> subjects;
  final List<String> grades;
  final List<String> sections;
  final List<String> periods;
  final List<String> types;

  const ActivityFormSheet({
    super.key,
    this.initial,
    required this.subjects,
    required this.grades,
    required this.sections,
    required this.periods,
    required this.types,
  });

  @override
  State<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<ActivityFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _descCtrl;

  String? _subject;
  String? _grade;
  String? _section;
  String? _period;
  String? _type;
  DateTime _date = DateTime.now();
  bool _isGroupWork = false;
  List<GroupActivity> _groups = [];

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameCtrl = TextEditingController(text: init?.name ?? '');
    _pointsCtrl = TextEditingController(text: init?.points.toString() ?? '');
    _descCtrl = TextEditingController(text: init?.description ?? '');
    _subject = init?.subject;
    _grade = init?.grade;
    _section = init?.section;
    _period = init?.period;
    _type = init?.type;
    _date = init?.date ?? DateTime.now();
    _isGroupWork = init?.isGroupWork ?? false;
    _groups = init?.groups ?? [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pointsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _addGroup() {
    setState(() {
      _groups = [
        ..._groups,
        GroupActivity(name: 'Grupo ${_groups.length + 1}')
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Editar Actividad' : 'Nueva Actividad',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),

            const Text('Nombre', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDecoration('Ej. Examen Parcial'),
            ),
            const SizedBox(height: 12),

            const Text('Descripción',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: _inputDecoration(
                  'Instrucciones, rúbrica o notas del maestro'),
            ),
            const SizedBox(height: 12),

            SelectField<String>(
              label: 'Materia',
              placeholder: 'Selecciona una materia',
              value: _subject,
              items: widget.subjects,
              itemLabel: (e) => e,
              onSelected: (v) => setState(() => _subject = v),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: SelectField<String>(
                    label: 'Grado',
                    placeholder: 'Grado',
                    value: _grade,
                    items: widget.grades,
                    itemLabel: (e) => e,
                    onSelected: (v) => setState(() => _grade = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectField<String>(
                    label: 'Sección',
                    placeholder: 'Sección',
                    value: _section,
                    items: widget.sections,
                    itemLabel: (e) => e,
                    onSelected: (v) => setState(() => _section = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SelectField<String>(
              label: 'Periodo',
              placeholder: 'Periodo',
              value: _period,
              items: widget.periods,
              itemLabel: (e) => e,
              onSelected: (v) => setState(() => _period = v),
            ),
            const SizedBox(height: 12),

            SelectField<String>(
              label: 'Tipo',
              placeholder: 'Tipo de actividad',
              value: _type,
              items: widget.types,
              itemLabel: (e) => e,
              onSelected: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),

            const Text('Puntos', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _pointsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: _inputDecoration('Ej. 25'),
            ),
            const SizedBox(height: 12),

            const Text('Fecha', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextField(
                  decoration: _inputDecoration(_fmtDate(_date)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Switch(
                  value: _isGroupWork,
                  activeColor: Colors.black,
                  onChanged: (v) => setState(() => _isGroupWork = v),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Trabajo grupal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            if (_isGroupWork)
              Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    ..._groups.asMap().entries.map((entry) {
                      final i = entry.key;
                      final g = entry.value;
                      return ListTile(
                        title: Text(g.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            g.members.isEmpty
                                ? 'Sin integrantes'
                                : g.members.join(', '),
                            style: const TextStyle(color: Colors.black54)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () {
                            setState(() {
                              _groups.removeAt(i);
                            });
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BlackButton(
                        label: 'Agregar grupo',
                        icon: Icons.group_add_outlined,
                        onPressed: _addGroup,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),
            BlackButton(
              label: 'Guardar',
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty ||
                    _subject == null ||
                    _grade == null ||
                    _section == null ||
                    _period == null ||
                    _type == null ||
                    _pointsCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos')),
                  );
                  return;
                }

                final points = int.tryParse(_pointsCtrl.text.trim()) ?? 0;
                final act = Activity(
                  id: widget.initial?.id ??
                      DateTime.now().millisecondsSinceEpoch,
                  name: _nameCtrl.text.trim(),
                  subject: _subject!,
                  grade: _grade!,
                  section: _section!,
                  period: _period!,
                  type: _type!,
                  points: points,
                  date: _date,
                  status: widget.initial?.status ?? 'pending',
                  studentsGraded: widget.initial?.studentsGraded ?? 0,
                  totalStudents: widget.initial?.totalStudents ?? 28,
                  averageGrade: widget.initial?.averageGrade,
                  description: _descCtrl.text.trim().isEmpty
                      ? null
                      : _descCtrl.text.trim(),
                  isGroupWork: _isGroupWork,
                  groups: _isGroupWork ? _groups : const [],
                );
                Navigator.pop(context, act);
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF4F5F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

/// =========================================================
/// 4. SHEET PARA CALIFICAR
/// =========================================================
class GradeActivitySheet extends StatefulWidget {
  final Activity activity;
  const GradeActivitySheet({super.key, required this.activity});

  @override
  State<GradeActivitySheet> createState() => _GradeActivitySheetState();
}

class _GradeActivitySheetState extends State<GradeActivitySheet> {
  late final bool isGroupWork;
  late final int maxPoints;
  late final String? description;

  late List<_TempStudentGrade> _students;
  late List<GroupActivity> _groups;

  @override
  void initState() {
    super.initState();
    isGroupWork = widget.activity.isGroupWork;
    maxPoints = widget.activity.points;
    description = widget.activity.description;

    if (isGroupWork) {
      _groups = widget.activity.groups.map((g) => g.copyWith()).toList();
    } else {
      final total = widget.activity.totalStudents;
      final graded = widget.activity.studentsGraded;
      _students = List.generate(total, (i) {
        final has = i < graded;
        return _TempStudentGrade(
          name: 'Estudiante ${i + 1}',
          grade: has ? (maxPoints * 0.7) : null,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // resumen
    int approved = 0;
    int failed = 0;
    int pending = 0;

    if (isGroupWork) {
      for (final g in _groups) {
        if (g.grade == null) {
          pending++;
        } else if (g.grade! >= maxPoints * 0.7) {
          approved++;
        } else {
          failed++;
        }
      }
    } else {
      approved = _students
          .where((s) => s.grade != null && s.grade! >= maxPoints * 0.7)
          .length;
      failed = _students
          .where((s) => s.grade != null && s.grade! < maxPoints * 0.7)
          .length;
      pending = _students.where((s) => s.grade == null).length;
    }

    return WillPopScope(
      onWillPop: () async {
        _returnData();
        return true;
      },
      child: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _returnData();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.black),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.activity.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (description != null && description!.trim().isNotEmpty)
                      _InfoBlock(
                        title: 'Descripción',
                        child: Text(
                          description!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                    _InfoBlock(
                      title: 'Detalles',
                      child: Text(
                        '${widget.activity.subject} • ${widget.activity.grade} ${widget.activity.section} • ${_fmtDate(widget.activity.date)}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    if (!isGroupWork)
                      _InfoBlock(
                        title: 'Notas',
                        child: Column(
                          children: List.generate(_students.length, (i) {
                            final s = _students[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: StudentGradeRow(
                                id: i + 1,
                                name: s.name,
                                grade: s.grade == null
                                    ? null
                                    : (s.grade! / maxPoints) * 100.0,
                                onChanged: (text) {
                                  final asDouble = double.tryParse(
                                      text.replaceAll(',', '.'));
                                  if (asDouble == null) return;
                                  final pct = asDouble.clamp(0, 100);
                                  final pts = (pct / 100.0) * maxPoints;
                                  setState(() {
                                    _students[i] =
                                        _students[i].copyWith(grade: pts);
                                  });
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    if (isGroupWork)
                      ..._groups.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final g = entry.value;
                        return _InfoBlock(
                          title: 'Grupo ${idx + 1}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (g.members.isEmpty)
                                const Text(
                                  'Sin integrantes',
                                  style: TextStyle(
                                      color: Colors.black45, fontSize: 13),
                                )
                              else
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: g.members
                                      .map(
                                        (m) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0F1F3),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            m,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 10),
                              StudentGradeRow(
                                id: idx + 1,
                                name: 'Nota del grupo',
                                grade: g.grade == null
                                    ? null
                                    : (g.grade! / maxPoints) * 100.0,
                                onChanged: (text) {
                                  final asDouble = double.tryParse(
                                      text.replaceAll(',', '.'));
                                  if (asDouble == null) return;
                                  final pct = asDouble.clamp(0, 100);
                                  final pts = (pct / 100.0) * maxPoints;
                                  setState(() {
                                    _groups[idx] = g.copyWith(grade: pts);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Aprobados: $approved • Reprobados: $failed • Pendientes: $pending',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _returnData() {
    if (isGroupWork) {
      final graded = _groups.where((g) => g.grade != null).toList();
      final hasPending = _groups.any((g) => g.grade == null);
      final avg = graded.isEmpty
          ? null
          : graded.fold<double>(0, (s, g) => s + (g.grade ?? 0)) /
              graded.length;

      final updated = widget.activity.copyWith(
        status: hasPending ? 'grading' : 'completed',
        studentsGraded: graded.length, // grupos “calificados”
        averageGrade: avg,
        groups: _groups,
      );
      Navigator.pop(context, updated);
    } else {
      final graded = _students.where((s) => s.grade != null).toList();
      final pending = _students.where((s) => s.grade == null).length;
      final avg = graded.isEmpty
          ? null
          : graded.fold<double>(0, (s, g) => s + (g.grade ?? 0)) /
              graded.length;

      final updated = widget.activity.copyWith(
        status: pending == 0 ? 'completed' : 'grading',
        studentsGraded: graded.length,
        averageGrade: avg,
      );
      Navigator.pop(context, updated);
    }
  }
}

/// =========================================================
/// 5. ayuditas visuales
/// =========================================================
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

class _TypeIcon extends StatelessWidget {
  final String type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case 'Examen':
        icon = Icons.fact_check_outlined;
        break;
      case 'Tarea':
        icon = Icons.menu_book_outlined;
        break;
      case 'Proyecto':
        icon = Icons.track_changes_outlined;
        break;
      case 'Laboratorio':
        icon = Icons.science_outlined;
        break;
      case 'Presentación':
        icon = Icons.present_to_all_outlined;
        break;
      case 'Quiz':
        icon = Icons.quiz_outlined;
        break;
      default:
        icon = Icons.menu_book_outlined;
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.black87),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    switch (status) {
      case 'completed':
        text = 'Completada';
        break;
      case 'pending':
        text = 'Pendiente';
        break;
      case 'grading':
        text = 'Calificando';
        break;
      default:
        text = 'Sin estado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final double ratio; // 0..1
  final bool done;
  const _ProgressLine({required this.ratio, required this.done});

  @override
  Widget build(BuildContext context) {
    final pct = (ratio.clamp(0, 1) * 100).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 8, color: const Color(0xFFE7E8EB)),
          FractionallySizedBox(
            widthFactor: ratio.clamp(0, 1),
            child: Container(
              height: 8,
              color: Colors.black,
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _IconSquareButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}

/// helper
String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$yyyy-$mm-$dd';
}

/// modelo temporal solo para la pantalla de calificar
class _TempStudentGrade {
  final String name;
  final double? grade;
  _TempStudentGrade({required this.name, this.grade});

  _TempStudentGrade copyWith({double? grade}) =>
      _TempStudentGrade(name: name, grade: grade);
}
