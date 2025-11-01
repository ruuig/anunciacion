import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../widgets/students_grade_raw.dart'; // tu mismo componente de notas

class GradeActivitySheet extends StatefulWidget {
  final Map<String, dynamic> activity;

  const GradeActivitySheet({
    super.key,
    required this.activity,
  });

  @override
  State<GradeActivitySheet> createState() => _GradeActivitySheetState();
}

class _GradeActivitySheetState extends State<GradeActivitySheet> {
  late bool isGroupWork;
  late int maxPoints;
  late String? description;

  // individuales
  late List<_TempStudentGrade> _students;

  // grupales
  late List<_GroupModel> _groups;

  @override
  void initState() {
    super.initState();
    isGroupWork = widget.activity['isGroupWork'] == true;
    maxPoints = widget.activity['points'] as int? ?? 100;
    description = widget.activity['description'] as String?;

    if (isGroupWork) {
      final raw = (widget.activity['groups'] as List?) ?? const [];
      _groups = raw
          .map<_GroupModel>(
            (g) => _GroupModel(
              name: g['name'] as String? ?? 'Grupo',
              members:
                  (g['members'] as List?)?.map((e) => e.toString()).toList() ??
                      <String>[],
              grade: (g['grade'] as num?)?.toDouble(),
            ),
          )
          .toList();
    } else {
      final total = widget.activity['totalStudents'] as int? ?? 25;
      final graded = widget.activity['studentsGraded'] as int? ?? 0;

      _students = List<_TempStudentGrade>.generate(total, (i) {
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
                        widget.activity['name'] ?? 'Actividad',
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
                        '${widget.activity['subject']} • ${widget.activity['grade']} ${widget.activity['section']} • ${widget.activity['date']}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    ),

                    // INDIVIDUAL
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

                    // GRUPAL
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
                                              horizontal: 10, vertical: 5),
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
                                    g.grade = pts;
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
      final pending = _groups.where((g) => g.grade == null).toList();
      Navigator.pop<Map<String, dynamic>>(context, {
        'status': pending.isEmpty ? 'completed' : 'grading',
        'studentsGraded': graded.length, // grupos calificados
        'averageGrade': graded.isEmpty
            ? null
            : graded.fold<double>(0, (s, g) => s + (g.grade ?? 0)) /
                graded.length,
        'groups': _groups
            .map((g) => {
                  'name': g.name,
                  'members': g.members,
                  'grade': g.grade,
                })
            .toList(),
      });
    } else {
      final graded = _students.where((s) => s.grade != null).toList();
      final pending = _students.where((s) => s.grade == null).length;
      final avg = graded.isEmpty
          ? null
          : graded.fold<double>(0, (s, g) => s + (g.grade ?? 0)) /
              graded.length;

      Navigator.pop<Map<String, dynamic>>(context, {
        'status': pending == 0 ? 'completed' : 'grading',
        'studentsGraded': graded.length,
        'averageGrade': avg,
      });
    }
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

class _TempStudentGrade {
  final String name;
  final double? grade;
  _TempStudentGrade({required this.name, this.grade});

  _TempStudentGrade copyWith({double? grade}) =>
      _TempStudentGrade(name: name, grade: grade);
}

class _GroupModel {
  final String name;
  final List<String> members;
  double? grade;
  _GroupModel({
    required this.name,
    required this.members,
    this.grade,
  });
}
