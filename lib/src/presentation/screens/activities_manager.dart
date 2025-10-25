import 'package:anunciacion/src/presentation/presentation.dart';
import 'package:anunciacion/src/presentation/widgets/seleccion%20title.dart';
import 'package:anunciacion/src/presentation/widgets/students_grade_raw.dart';
import 'package:anunciacion/src/presentation/widgets/sumary-raw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modelo simple de Actividad
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
    double? averageGrade, // usa null explícito para borrar
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
      averageGrade: averageGrade == null ? this.averageGrade : averageGrade,
    );
  }
}

/// Pestaña completa: Gestión de Actividades
class FullActivitiesTabBody extends StatefulWidget {
  final String userRole;
  final List<String> assignedGrades;
  const FullActivitiesTabBody({
    super.key,
    required this.userRole,
    this.assignedGrades = const [],
  });

  @override
  State<ActivitiesTabBody> createState() => _ActivitiesTabBodyState();
}

class _ActivitiesTabBodyState extends State<ActivitiesTabBody> {
  // Mock de catálogo (puedes cargar desde tus use cases)
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
      date: DateTime(2024, 2, 15),
      status: 'completed',
      studentsGraded: 24,
      totalStudents: 28,
      averageGrade: 78.5,
    ),
    Activity(
      id: 2,
      name: 'Tarea - Ejercicios de suma y resta',
      subject: 'Matemáticas',
      grade: '3ro Primaria',
      section: 'A',
      period: 'Primer Bimestre',
      type: 'Tarea',
      points: 10,
      date: DateTime(2024, 2, 10),
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
      date: DateTime(2024, 2, 20),
      status: 'pending',
      studentsGraded: 0,
      totalStudents: 25,
      averageGrade: null,
    ),
  ];

  // Filtros
  String? selectedGrade; // null = todos
  String? selectedPeriod; // null = todos

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
          // Header + Stats
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
                            heightFactor: 0.6, // compacto
                            child: _CreateEditActivitySheet(
                              subjects: subjects,
                              grades: availableGrades,
                              sections: sections,
                              periods: periods,
                              types: types,
                            ),
                          ),
                        );
                        if (created != null) {
                          setState(() => activities.add(created.copyWith(
                                status: 'pending',
                                studentsGraded: 0,
                                totalStudents: 28,
                                averageGrade: null,
                              )));
                        }
                      },
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    Expanded(
                        child: _StatBox(
                            title: 'Completadas', value: '$completed')),
                    const SizedBox(width: 10),
                    Expanded(
                        child:
                            _StatBox(title: 'Pendientes', value: '$pending')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatBox(
                            title: 'Puntos Total', value: '$totalPoints')),
                  ],
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
                        onSelected: (e) => setState(() => selectedGrade = e.isEmpty ? null : e),
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
                        onSelected: (e) => setState(() => selectedPeriod = e.isEmpty ? null : e),
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
                      // Header actividad
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
                                    text: a.subject),
                                _InfoRow(
                                    icon: Icons.people_alt_outlined,
                                    text: '${a.grade} - Sección ${a.section}'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                          top: Radius.circular(18)),
                                    ),
                                    builder: (_) => FractionallySizedBox(
                                      heightFactor: 0.6,
                                      child: _CreateEditActivitySheet(
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
                                    setState(() => activities = activities
                                        .map((x) => x.id == a.id ? updated : x)
                                        .toList());
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
                                          '¿Seguro que deseas eliminar esta actividad? Esta acción no se puede deshacer.'),
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
                                    setState(() => activities
                                        .removeWhere((x) => x.id == a.id));
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),

                      // Detalles inferiores: fecha, puntos, progreso, acción
                      const SizedBox(height: 10),
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
                                        text: _fmtDate(a.date)),
                                    _InfoRow(
                                        icon: Icons.track_changes_outlined,
                                        text: '${a.points} pts'),
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
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (a.averageGrade != null)
                                      Text(
                                        'Promedio: ${a.averageGrade!.toStringAsFixed(1)}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900),
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
                              final graded =
                                  await showModalBottomSheet<Activity>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(18)),
                                ),
                                builder: (_) => FractionallySizedBox(
                                  heightFactor: 0.7,
                                  child: _GradeActivitySheet(activity: a),
                                ),
                              );
                              if (graded != null) {
                                setState(() => activities = activities
                                    .map((x) => x.id == a.id ? graded : x)
                                    .toList());
                              }
                            },
                          ),
                        ],
                      )
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

/// ---------- Widgets internos de UI ----------

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
        border: Border.all(color: const Color(0xFFE6E7EA)),
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w700)),
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
            child: Container(height: 8, color: Colors.black),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                '$pct%',
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w900),
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

/// ---------- Bottom sheet: Crear / Editar actividad ----------
class _CreateEditActivitySheet extends StatefulWidget {
  final Activity? initial;
  final List<String> subjects;
  final List<String> grades;
  final List<String> sections;
  final List<String> periods;
  final List<String> types;

  const _CreateEditActivitySheet({
    this.initial,
    required this.subjects,
    required this.grades,
    required this.sections,
    required this.periods,
    required this.types,
  });

  @override
  State<_CreateEditActivitySheet> createState() =>
      _CreateEditActivitySheetState();
}

class _CreateEditActivitySheetState extends State<_CreateEditActivitySheet> {
  final _nameCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  String? subject;
  String? grade;
  String? section;
  String? period;
  String? type;
  DateTime? date;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final a = widget.initial!;
      _nameCtrl.text = a.name;
      _pointsCtrl.text = a.points.toString();
      subject = a.subject;
      grade = a.grade;
      section = a.section;
      period = a.period;
      type = a.type;
      date = a.date;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 10),
          Text(isEdit ? 'Editar Actividad' : 'Nueva Actividad',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          const Text('Nombre',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: _inputDecoration('Ej. Examen Parcial - Fracciones'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          SelectField<String>(
            label: 'Materia',
            placeholder: 'Selecciona una materia',
            value: subject,
            items: widget.subjects,
            itemLabel: (e) => e,
            onSelected: (e) => setState(() => subject = e),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SelectField<String>(
                  label: 'Grado',
                  placeholder: 'Grado',
                  value: grade,
                  items: widget.grades,
                  itemLabel: (e) => e,
                  onSelected: (e) => setState(() => grade = e),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectField<String>(
                  label: 'Sección',
                  placeholder: 'Sección',
                  value: section,
                  items: widget.sections,
                  itemLabel: (e) => e,
                  onSelected: (e) => setState(() => section = e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelectField<String>(
            label: 'Periodo',
            placeholder: 'Periodo',
            value: period,
            items: widget.periods,
            itemLabel: (e) => e,
            onSelected: (e) => setState(() => period = e),
          ),
          const SizedBox(height: 14),
          SelectField<String>(
            label: 'Tipo',
            placeholder: 'Tipo de actividad',
            value: type,
            items: widget.types,
            itemLabel: (e) => e,
            onSelected: (e) => setState(() => type = e),
          ),
          const SizedBox(height: 14),
          const Text('Puntos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: _pointsCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3)
            ],
            decoration: _inputDecoration('Ej. 25'),
          ),
          const SizedBox(height: 14),
          SelectField<DateTime>(
            label: 'Fecha',
            placeholder: 'Selecciona fecha',
            value: date,
            items: _nextDates(365),
            itemLabel: (d) => _fmtDate(d),
            onSelected: (d) => setState(() => date = d),
          ),
          const SizedBox(height: 18),
          BlackButton(
            label: isEdit ? 'Guardar Cambios' : 'Crear Actividad',
            onPressed: () {
              if (_nameCtrl.text.trim().isEmpty ||
                  subject == null ||
                  grade == null ||
                  section == null ||
                  period == null ||
                  type == null ||
                  date == null ||
                  _pointsCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa todos los campos')),
                );
                return;
              }
              final points = int.tryParse(_pointsCtrl.text) ?? 0;
              final base = widget.initial ??
                  Activity(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: _nameCtrl.text.trim(),
                    subject: subject!,
                    grade: grade!,
                    section: section!,
                    period: period!,
                    type: type!,
                    points: points,
                    date: date!,
                    status: 'pending',
                    studentsGraded: 0,
                    totalStudents: 28,
                    averageGrade: null,
                  );
              final updated = base.copyWith(
                name: _nameCtrl.text.trim(),
                subject: subject!,
                grade: grade!,
                section: section!,
                period: period!,
                type: type!,
                points: points,
                date: date!,
              );
              Navigator.pop(context, updated);
            },
          ),
        ],
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
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  List<DateTime> _nextDates(int days) {
    final now = DateTime.now();
    return List.generate(days,
        (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)));
  }
}

/// ---------- Bottom sheet: Calificar/Ver notas ----------
class _GradeActivitySheet extends StatefulWidget {
  final Activity activity;
  const _GradeActivitySheet({required this.activity});

  @override
  State<_GradeActivitySheet> createState() => _GradeActivitySheetState();
}

class _GradeActivitySheetState extends State<_GradeActivitySheet> {
  // Mock de alumnos + nota en puntos (puedes traer de DB)
  late List<_StudentGrade> grades;

  @override
  void initState() {
    super.initState();
    grades = List<_StudentGrade>.generate(
      widget.activity.totalStudents,
      (i) => _StudentGrade(
        i + 1,
        'Estudiante ${i + 1}',
        value: i < widget.activity.studentsGraded
            ? (widget.activity.points * 0.7)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approved = grades
        .where((g) => (g.value ?? -1) >= (widget.activity.points * 0.7))
        .length;
    final failed = grades
        .where((g) =>
            g.value != null && (g.value ?? 0) < (widget.activity.points * 0.7))
        .length;
    final pending = grades.where((g) => g.value == null).length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 10),
          Text('Calificar: ${widget.activity.name}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.activity.subject} · ${widget.activity.grade} ${widget.activity.section} · ${_fmtDate(widget.activity.date)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    BlackButton(
                      label: 'Guardar',
                      icon: Icons.save_outlined,
                      onPressed: () {
                        final graded =
                            grades.where((g) => g.value != null).toList();
                        final avg = graded.isEmpty
                            ? null
                            : graded.fold<double>(
                                    0, (s, g) => s + (g.value ?? 0)) /
                                graded.length;
                        final updated = widget.activity.copyWith(
                          status: pending == 0 ? 'completed' : 'grading',
                          studentsGraded: graded.length,
                          averageGrade: avg,
                        );
                        Navigator.pop(context, updated);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: grades.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFECEDEF)),
                  itemBuilder: (_, i) {
                    final g = grades[i];
                    return StudentGradeRow(
                      id: g.id,
                      name: g.name,
                      grade: g.value == null
                          ? null
                          : ((g.value! / widget.activity.points) * 100)
                              .clamp(0, 100),
                      onChanged: (t) {
                        final v = double.tryParse(t.replaceAll(',', '.'));
                        if (v == null) return;
                        final pct = v.clamp(0, 100);
                        final pts = (pct / 100.0) * widget.activity.points;
                        setState(() => grades[i] = g.copyWith(value: pts));
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                SummaryRow(
                    approved: approved, failed: failed, pending: pending),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- helpers ----------
String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$yyyy-$mm-$dd';
}

class _StudentGrade {
  final int id;
  final String name;
  final double? value; // puntos
  _StudentGrade(this.id, this.name, {this.value});

  _StudentGrade copyWith({double? value}) =>
      _StudentGrade(id, name, value: value ?? this.value);
}
