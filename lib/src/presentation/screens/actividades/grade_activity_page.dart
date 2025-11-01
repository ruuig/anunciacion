import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anunciacion/src/domain/entities/activity.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';

class GradeActivityPage extends StatefulWidget {
  final String name; // título de la página
  final Activity? initial;
  final List<String> grades;
  final List<String> periods;

  const GradeActivityPage({
    super.key,
    required this.name,
    this.initial,
    required this.grades,
    required this.periods,
  });

  @override
  State<GradeActivityPage> createState() => _GradeActivityPageState();
}

class _GradeActivityPageState extends State<GradeActivityPage> {
  // controllers de la actividad
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _sectionCtrl;
  late final TextEditingController _pointsCtrl;

  String? _grade;
  String? _period;
  DateTime _date = DateTime.now();
  bool _isGroupWork = false;
  List<ActivityGroup> _groups = [];

  // notas por estudiante (nombre -> nota)
  final Map<String, double?> _studentGrades = {};
  // notas por grupo (nombreGrupo -> nota)
  final Map<String, double?> _groupGrades = {};

  @override
  void initState() {
    super.initState();
    final i = widget.initial;

    _titleCtrl = TextEditingController(text: i?.name ?? '');
    _descCtrl = TextEditingController(text: i?.description ?? '');
    _subjectCtrl = TextEditingController(text: i?.subject ?? '');
    _sectionCtrl = TextEditingController(text: i?.section ?? '');
    _pointsCtrl =
        TextEditingController(text: i != null ? i.points.toString() : '');

    _grade = i?.grade;
    _period = i?.period;
    _date = i?.date ?? DateTime.now();
    _isGroupWork = i?.isGroupWork ?? false;
    _groups = i?.groups ?? [];

    // si no es grupal, generamos los estudiantes del grado
    if (!_isGroupWork) {
      final students = _studentsForGrade(_grade);
      for (final s in students) {
        _studentGrades[s] = null;
      }
    } else {
      // si es grupal, preparar las notas de grupo
      for (final g in _groups) {
        _groupGrades[g.name] = g.grade;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    _sectionCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  // 🔹 simula alumnos por grado (luego aquí metes lo que te devuelva tu backend)
  List<String> _studentsForGrade(String? grade) {
    if (grade == '3ro Primaria') {
      return [
        'Ana López',
        'Carlos Pérez',
        'Diego Hernández',
        'Sofía Gómez',
        'Luis Castillo',
        'María José',
        'Kevin Díaz',
      ];
    }
    return [
      'Estudiante 1',
      'Estudiante 2',
      'Estudiante 3',
      'Estudiante 4',
    ];
  }

  void _save() {
    // calcular estudiantes/grupos calificados
    int studentsGraded = 0;
    int totalStudents = 0;
    double sum = 0;

    if (_isGroupWork) {
      totalStudents = _groups.length;
      for (final g in _groups) {
        final gGrade = _groupGrades[g.name];
        if (gGrade != null) {
          studentsGraded++;
          sum += gGrade;
        }
      }
    } else {
      final entries = _studentGrades.entries.toList();
      totalStudents = entries.length;
      for (final e in entries) {
        if (e.value != null) {
          studentsGraded++;
          sum += e.value!;
        }
      }
    }

    final avg = totalStudents == 0 ? null : (sum / totalStudents);

    final updated = Activity(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      grade: _grade ?? '',
      section: _sectionCtrl.text.trim(),
      period: _period ?? '',
      type: widget.initial?.type ?? 'Examen',
      points: int.tryParse(_pointsCtrl.text.trim()) ?? 0,
      date: _date,
      isGroupWork: _isGroupWork,
      groups: _isGroupWork
          ? _groups
              .map(
                (g) => g.copyWith(
                  grade: _groupGrades[g.name],
                ),
              )
              .toList()
          : const [],
      status: studentsGraded == totalStudents && totalStudents > 0
          ? 'completed'
          : 'pending',
      studentsGraded: studentsGraded,
      totalStudents: totalStudents,
      averageGrade: avg,
    );

    Navigator.pop(context, updated);
  }

  void _addGroup() {
    setState(() {
      final newGroup = ActivityGroup(
        name: 'Grupo ${_groups.length + 1}',
        members: [],
      );
      _groups.add(newGroup);
      _groupGrades[newGroup.name] = null;
    });
  }

  void _addStudentToGroup(ActivityGroup group) async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar estudiante al grupo'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Nombre del estudiante',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  final idx = _groups.indexOf(group);
                  if (idx != -1) {
                    final current = _groups[idx];
                    final updatedMembers = List<String>.from(current.members)
                      ..add(name);
                    _groups[idx] = current.copyWith(members: updatedMembers);
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        title: Text(
          widget.name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== DATOS DE LA ACTIVIDAD =====
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actividad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF3FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.menu_book_outlined,
                            color: Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _titleCtrl,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Título de la actividad',
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _descCtrl,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Descripción / instrucciones',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        label: 'Materia',
                        value:
                            _subjectCtrl.text.isEmpty ? '—' : _subjectCtrl.text,
                        icon: Icons.subject_outlined,
                      ),
                      _InfoChip(
                        label: 'Grado',
                        value: _grade ?? '—',
                        icon: Icons.school_outlined,
                      ),
                      _InfoChip(
                        label: 'Sección',
                        value:
                            _sectionCtrl.text.isEmpty ? '—' : _sectionCtrl.text,
                        icon: Icons.group_outlined,
                      ),
                      _InfoChip(
                        label: 'Periodo',
                        value: _period ?? '—',
                        icon: Icons.calendar_month_outlined,
                      ),
                      _InfoChip(
                        label: 'Puntos',
                        value: _pointsCtrl.text.isEmpty
                            ? '0'
                            : '${_pointsCtrl.text} pts',
                        icon: Icons.stars_rounded,
                      ),
                      _InfoChip(
                        label: 'Fecha',
                        value: _fmtDate(_date),
                        icon: Icons.event_outlined,
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== SEGÚN SEA GRUPAL O NO =====
            if (!_isGroupWork)
              _buildStudentsSection()
            else
              _buildGroupsSection(),

            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: BlackButton(
          label: 'Guardar cambios',
          icon: Icons.save_outlined,
          onPressed: _save,
        ),
      ),
    );
  }

  // ---------- SECCIÓN: CALIFICAR ESTUDIANTES -------------
  Widget _buildStudentsSection() {
    final students = _studentGrades.keys.toList();
    // decidir hint según puntos
    final maxPoints = int.tryParse(_pointsCtrl.text.trim()) ?? 100;
    final hint = '0–$maxPoints';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lista de Estudiantes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (students.isEmpty)
            const Text(
              'No hay estudiantes vinculados a este grado.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...students.map((name) {
              final current = _studentGrades[name];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 72,
                      child: TextField(
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: TextEditingController(
                          text:
                              current != null ? current.toInt().toString() : '',
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black26),
                          ),
                        ),
                        onChanged: (val) {
                          final n = int.tryParse(val);
                          // opcional: limitar al máximo
                          final limited =
                              (n != null && n > maxPoints) ? maxPoints : n;
                          setState(() => _studentGrades[name] =
                              limited != null ? limited.toDouble() : null);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // ---------- SECCIÓN: CALIFICAR GRUPOS -------------
  Widget _buildGroupsSection() {
    final maxPoints = int.tryParse(_pointsCtrl.text.trim()) ?? 100;
    final hint = '0–$maxPoints';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calificar grupos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ..._groups.map((g) {
            final current = _groupGrades[g.name];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        onPressed: () => _addStudentToGroup(g),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _groups.remove(g);
                            _groupGrades.remove(g.name);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g.members.isEmpty
                        ? 'Sin integrantes'
                        : 'Integrantes: ${g.members.join(', ')}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      controller: TextEditingController(
                        text: current != null ? current.toInt().toString() : '',
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black26),
                        ),
                      ),
                      onChanged: (val) {
                        final n = int.tryParse(val);
                        final limited =
                            (n != null && n > maxPoints) ? maxPoints : n;
                        setState(() => _groupGrades[g.name] =
                            limited != null ? limited.toDouble() : null);
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          BlackButton(
            label: 'Agregar grupo',
            icon: Icons.group_add_outlined,
            onPressed: _addGroup,
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// --------- MINI WIDGETS DE UI ---------
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: chip,
      );
    }
    return chip;
  }
}
