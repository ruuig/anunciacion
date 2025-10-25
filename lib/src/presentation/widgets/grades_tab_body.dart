import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anunciacion/src/domain/entities/grade_entry.dart';
import '../screens/notas_controller.dart';
import 'app_card.dart';
import 'black_button.dart';
import 'empty_state.dart';
import 'select_field.dart';
import 'students_grade_raw.dart';

class GradesTabBody extends ConsumerStatefulWidget {
  final String userRole;
  final List<String> assignedGrades;

  const GradesTabBody({
    super.key,
    required this.userRole,
    required this.assignedGrades,
  });

  @override
  ConsumerState<GradesTabBody> createState() => _GradesTabBodyState();
}

class _GradesTabBodyState extends ConsumerState<GradesTabBody> {
  static const List<_SelectOption> _subjects = [
    _SelectOption(id: 1, label: 'Matemáticas'),
    _SelectOption(id: 2, label: 'Español'),
    _SelectOption(id: 3, label: 'Ciencias Naturales'),
    _SelectOption(id: 4, label: 'Inglés'),
  ];

  static const List<_SelectOption> _periods = [
    _SelectOption(id: 1, label: 'Primer Bimestre'),
    _SelectOption(id: 2, label: 'Segundo Bimestre'),
    _SelectOption(id: 3, label: 'Tercer Bimestre'),
    _SelectOption(id: 4, label: 'Cuarto Bimestre'),
  ];

  static const List<_GroupOption> _groups = [
    _GroupOption(id: 101, grade: '1ro Primaria', section: 'A'),
    _GroupOption(id: 102, grade: '1ro Primaria', section: 'B'),
    _GroupOption(id: 103, grade: '1ro Primaria', section: 'C'),
    _GroupOption(id: 201, grade: '2do Primaria', section: 'A'),
    _GroupOption(id: 202, grade: '2do Primaria', section: 'B'),
    _GroupOption(id: 203, grade: '2do Primaria', section: 'C'),
    _GroupOption(id: 301, grade: '3ro Primaria', section: 'A'),
    _GroupOption(id: 302, grade: '3ro Primaria', section: 'B'),
    _GroupOption(id: 303, grade: '3ro Primaria', section: 'C'),
    _GroupOption(id: 401, grade: '4to Primaria', section: 'A'),
    _GroupOption(id: 402, grade: '4to Primaria', section: 'B'),
    _GroupOption(id: 403, grade: '4to Primaria', section: 'C'),
  ];

  _SelectOption? selectedSubject;
  _SelectOption? selectedPeriod;
  String? selectedGrade;
  String? selectedSection;

  @override
  void initState() {
    super.initState();
    selectedSubject = _subjects.isNotEmpty ? _subjects.first : null;
    selectedPeriod = _periods.isNotEmpty ? _periods.first : null;

    final grades = _computeAvailableGrades();
    if (grades.isNotEmpty) {
      selectedGrade = grades.first;
      final sections = _sectionsForGrade(selectedGrade!);
      if (sections.isNotEmpty) {
        selectedSection = sections.first;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  @override
  void didUpdateWidget(covariant GradesTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.assignedGrades, widget.assignedGrades)) {
      final grades = _computeAvailableGrades();
      if (grades.isEmpty) {
        if (selectedGrade != null || selectedSection != null) {
          setState(() {
            selectedGrade = null;
            selectedSection = null;
          });
        }
      } else if (selectedGrade == null || !grades.contains(selectedGrade)) {
        setState(() {
          selectedGrade = grades.first;
          final sections = _sectionsForGrade(selectedGrade!);
          selectedSection = sections.isNotEmpty ? sections.first : null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyFilters();
        });
      }
    }
  }

  List<String> get _availableGrades => _computeAvailableGrades();

  List<String> get _availableSections {
    if (selectedGrade == null) return [];
    return _sectionsForGrade(selectedGrade!);
  }

  bool get _canShowStudents =>
      selectedGrade != null &&
      selectedSection != null &&
      selectedSubject != null &&
      selectedPeriod != null;

  List<String> _computeAvailableGrades() {
    final seen = <String>{};
    final grades = <String>[];
    for (final group in _groups) {
      if (seen.add(group.grade)) {
        grades.add(group.grade);
      }
    }

    if (widget.userRole == 'Docente' && widget.assignedGrades.isNotEmpty) {
      return grades
          .where((grade) => widget.assignedGrades.contains(grade))
          .toList();
    }
    return grades;
  }

  List<String> _sectionsForGrade(String grade) {
    final seen = <String>{};
    final sections = <String>[];
    for (final group in _groups) {
      if (group.grade == grade && seen.add(group.section)) {
        sections.add(group.section);
      }
    }
    return sections;
  }

  int? _resolveGroupId() {
    if (selectedGrade == null || selectedSection == null) return null;
    for (final group in _groups) {
      if (group.grade == selectedGrade && group.section == selectedSection) {
        return group.id;
      }
    }
    return null;
  }

  void _applyFilters() {
    final groupId = _resolveGroupId();
    final subjectId = selectedSubject?.id;
    final periodId = selectedPeriod?.id;

    if (groupId == null || subjectId == null || periodId == null) {
      return;
    }

    final controller = ref.read(notasControllerProvider.notifier);
    controller.setFilters(
      groupId: groupId,
      subjectId: subjectId,
      periodId: periodId,
    );
    controller.load();
  }

  void _handleGradeChange(int studentId, String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      ref.read(notasControllerProvider.notifier).updateValue(studentId, null);
      return;
    }

    final normalized = trimmed.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value != null) {
      ref.read(notasControllerProvider.notifier).updateValue(studentId, value);
    }
  }

  Future<void> _saveGrades() async {
    final state = ref.read(notasControllerProvider);
    final hasValues = state.entries.any((entry) => entry.value != null);
    if (!hasValues) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay calificaciones para guardar'),
          ),
        );
      }
      return;
    }

    await ref.read(notasControllerProvider.notifier).saveAll();
    if (!mounted) return;

    final updated = ref.read(notasControllerProvider);
    if (updated.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated.error!),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calificaciones guardadas exitosamente'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notasState = ref.watch(notasControllerProvider);
    final entries = notasState.entries;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ingreso de Calificaciones',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                const Text(
                  'Selecciona la clase y el período para registrar notas.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                SelectField<_SelectOption>(
                  label: 'Materia',
                  placeholder: 'Selecciona una materia',
                  value: selectedSubject,
                  items: _subjects,
                  itemLabel: (e) => e.label,
                  onSelected: (e) {
                    setState(() => selectedSubject = e);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SelectField<String>(
                        label: 'Grado',
                        placeholder: 'Grado',
                        value: selectedGrade,
                        items: _availableGrades,
                        itemLabel: (e) => e,
                        onSelected: (grade) {
                          setState(() {
                            selectedGrade = grade;
                            final sections = _sectionsForGrade(grade);
                            selectedSection =
                                sections.isNotEmpty ? sections.first : null;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectField<String>(
                        label: 'Sección',
                        placeholder: 'Sección',
                        value: selectedSection,
                        items: _availableSections,
                        itemLabel: (e) => e,
                        enabled: _availableSections.isNotEmpty,
                        onSelected: (section) {
                          setState(() => selectedSection = section);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectField<_SelectOption>(
                  label: 'Período',
                  placeholder: 'Selecciona el período',
                  value: selectedPeriod,
                  items: _periods,
                  itemLabel: (e) => e.label,
                  onSelected: (period) {
                    setState(() => selectedPeriod = period);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_canShowStudents)
            EmptyState(
              title: 'Selecciona todos los campos',
              description: 'Elige materia, grado, sección y período',
              icon: const Icon(Icons.menu_book_outlined,
                  size: 48, color: Colors.black45),
            )
          else
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lista de Estudiantes',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (notasState.loading) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  if (notasState.error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notasState.error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!notasState.loading && entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No se encontraron estudiantes para los filtros seleccionados.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (entries.isNotEmpty) ...[
                    for (int i = 0; i < entries.length; i++) ...[
                      StudentGradeRow(
                        id: entries[i].studentId,
                        name: entries[i].studentName ??
                            'Estudiante ${entries[i].studentId}',
                        grade: entries[i].value,
                        onChanged: (value) =>
                            _handleGradeChange(entries[i].studentId, value),
                      ),
                      if (i != entries.length - 1)
                        const Divider(height: 20, color: Color(0xFFEAEAEA)),
                    ],
                    const SizedBox(height: 12),
                    _SummaryBox(entries: entries, average: notasState.average),
                    const SizedBox(height: 14),
                  ],
                  BlackButton(
                    label: 'Guardar Calificaciones',
                    onPressed:
                        entries.isEmpty ? null : () => _saveGrades(),
                    busy: notasState.loading,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final List<GradeEntry> entries;
  final double average;
  const _SummaryBox({required this.entries, required this.average});

  @override
  Widget build(BuildContext context) {
    final aprobados =
        entries.where((s) => (s.value ?? 0) >= 70).length;
    final reprobados =
        entries.where((s) => s.value != null && s.value! < 70).length;
    final pendientes = entries.where((s) => s.value == null).length;
    final promedio = entries.isEmpty ? 0.0 : average;

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Aprobados',
            value: aprobados.toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            label: 'Reprobados',
            value: reprobados.toString(),
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            label: 'Pendientes',
            value: pendientes.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            label: 'Promedio',
            value: promedio.toStringAsFixed(1),
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SelectOption {
  final int id;
  final String label;

  const _SelectOption({required this.id, required this.label});
}

class _GroupOption {
  final int id;
  final String grade;
  final String section;

  const _GroupOption({
    required this.id,
    required this.grade,
    required this.section,
  });
}
