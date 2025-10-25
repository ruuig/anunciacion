import 'package:anunciacion/src/domain/domain.dart';
import 'package:anunciacion/src/providers/activity_providers.dart';
import 'package:anunciacion/src/providers/user_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'app_card.dart';
import 'black_button.dart';
import 'empty_state.dart';
import 'select_field.dart';

class ActivitiesTabBody extends ConsumerStatefulWidget {
  final String userRole;
  final List<String> assignedGrades;

  const ActivitiesTabBody({
    super.key,
    required this.userRole,
    required this.assignedGrades,
  });

  @override
  ConsumerState<ActivitiesTabBody> createState() => _ActivitiesTabBodyState();
}

class _ActivitiesTabBodyState extends ConsumerState<ActivitiesTabBody> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'es');

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(activityFiltersProvider);
    final activitiesAsync = ref.watch(activitiesProvider);
    final gradesAsync = ref.watch(activeGradesProvider);
    final sectionsAsync = ref.watch(sectionsForSelectedGradeProvider);
    final subjectsAsync = ref.watch(activeSubjectsProvider);
    final types = ref.watch(activityTypesProvider);

    final activities = activitiesAsync.asData?.value ?? const <Activity>[];
    final completed =
        activities.where((a) => a.status.toLowerCase() == 'completada').length;
    final pending =
        activities.where((a) => a.status.toLowerCase() != 'completada').length;
    final totalPoints = activities.fold<double>(
      0,
      (sum, activity) => sum + activity.maxPoints,
    );

    final grades = gradesAsync.value ?? const <Grade>[];
    final sections = sectionsAsync.value ?? const <Section>[];
    final subjects = subjectsAsync.value ?? const <Subject>[];

    Grade? selectedGrade;
    if (filters.gradeId != null) {
      for (final grade in grades) {
        if (grade.id == filters.gradeId) {
          selectedGrade = grade;
          break;
        }
      }
    }

    Section? selectedSection;
    if (filters.sectionId != null) {
      for (final section in sections) {
        if (section.id == filters.sectionId) {
          selectedSection = section;
          break;
        }
      }
    }

    Subject? selectedSubject;
    if (filters.subjectId != null) {
      for (final subject in subjects) {
        if (subject.id == filters.subjectId) {
          selectedSubject = subject;
          break;
        }
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestión de Actividades',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Planifica, filtra y califica tus actividades académicas.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
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
                          child: _StatBox(
                            title: 'Completadas',
                            value: '$completed',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            title: 'Pendientes',
                            value: '$pending',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            title: 'Puntos Totales',
                            value: totalPoints.toStringAsFixed(1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    SelectField<Grade>(
                      label: 'Grado',
                      placeholder: gradesAsync.isLoading
                          ? 'Cargando grados...'
                          : 'Selecciona un grado',
                      value: selectedGrade,
                      items: grades,
                      itemLabel: (g) => g.name,
                      onSelected: (grade) =>
                          ref.read(activityFiltersProvider.notifier).setGrade(grade.id),
                      enabled: gradesAsync.hasValue,
                    ),
                    const SizedBox(height: 12),
                    SelectField<Section>(
                      label: 'Sección',
                      placeholder: filters.gradeId == null
                          ? 'Selecciona un grado primero'
                          : sectionsAsync.isLoading
                              ? 'Cargando secciones...'
                              : 'Selecciona una sección',
                      value: selectedSection,
                      items: sections,
                      itemLabel: (s) => s.name,
                      onSelected: (section) => ref
                          .read(activityFiltersProvider.notifier)
                          .setSection(section.id),
                      enabled: filters.gradeId != null && sectionsAsync.hasValue,
                    ),
                    const SizedBox(height: 12),
                    SelectField<Subject>(
                      label: 'Materia',
                      placeholder: subjectsAsync.isLoading
                          ? 'Cargando materias...'
                          : 'Selecciona una materia',
                      value: selectedSubject,
                      items: subjects,
                      itemLabel: (s) => s.name,
                      onSelected: (subject) => ref
                          .read(activityFiltersProvider.notifier)
                          .setSubject(subject.id),
                      enabled: subjectsAsync.hasValue,
                    ),
                    const SizedBox(height: 12),
                    SelectField<String>(
                      label: 'Tipo',
                      placeholder: 'Todos los tipos',
                      value: filters.type,
                      items: types,
                      itemLabel: (value) => value,
                      onSelected: (value) =>
                          ref.read(activityFiltersProvider.notifier).setType(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              activitiesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Error al cargar actividades: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (activities) => activities.isEmpty
                    ? const EmptyState(
                        title: 'No hay actividades',
                        description: 'Crea tu primera actividad para comenzar',
                        icon: Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.black45,
                        ),
                      )
                    : Column(
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
                          ...activities.map((activity) {
                            final totalStudents = activity.totalStudents ?? 0;
                            final gradedStudents = activity.gradedStudents ?? 0;
                            final progress = totalStudents == 0
                                ? 0.0
                                : (gradedStudents / totalStudents).clamp(0, 1);
                            final avg = activity.averagePercentage;
                            final dateLabel = _dateFormat.format(
                              (activity.scheduledAt ?? activity.createdAt).toLocal(),
                            );

                            return Padding(
                              key: ValueKey('activity_${activity.id}'),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            activity.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        _StatusBadge(status: activity.status),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${activity.subjectName ?? 'Materia'} • ${activity.gradeName ?? 'Grado'} ${activity.sectionName ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${activity.maxPoints.toStringAsFixed(1)} pts | $dateLabel',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        if (avg != null)
                                          Text(
                                            'Promedio: ${avg.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        color: Colors.black,
                                        backgroundColor: Colors.grey[300],
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Progreso: $gradedStudents/$totalStudents estudiantes',
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
                                          tooltip: 'Editar actividad',
                                          onPressed: () => _editActivity(activity),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.black,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar actividad',
                                          onPressed: () => _deleteActivity(activity),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        BlackButton(
                                          label: progress >= 1 ? 'Ver notas' : 'Calificar',
                                          onPressed: () => _gradeActivity(activity),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createActivity() async {
    final user = ref.read(userProvider);
    if (user == null) {
      _showMessage('Debes iniciar sesión para crear actividades');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ActivityFormSheet(teacherId: user.id),
    );
  }

  Future<void> _editActivity(Activity activity) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ActivityFormSheet(
        teacherId: activity.teacherId,
        initialActivity: activity,
      ),
    );
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: Text(
          '¿Estás seguro de eliminar "${activity.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(deleteActivityProvider)(activity.id!);
    _showMessage('Actividad eliminada correctamente');
  }

  Future<void> _gradeActivity(Activity activity) async {
    final user = ref.read(userProvider);
    if (user == null) {
      _showMessage('Debes iniciar sesión para calificar');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ActivityGradeSheet(
        activity: activity,
        teacherId: user.id,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
              fontWeight: FontWeight.w600,
            ),
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
    switch (status.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String get text {
    switch (status.toLowerCase()) {
      case 'completada':
        return 'Completada';
      case 'pendiente':
        return 'Pendiente';
      default:
        return status;
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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ActivityFormSheet extends ConsumerStatefulWidget {
  const ActivityFormSheet({
    super.key,
    required this.teacherId,
    this.initialActivity,
  });

  final int teacherId;
  final Activity? initialActivity;

  @override
  ConsumerState<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends ConsumerState<ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  DateTime? _scheduledAt;
  DateTime? _dueDate;
  int? _gradeId;
  int? _sectionId;
  int? _subjectId;
  int? _periodId;
  String? _type;
  bool _saving = false;
  bool _loadingSections = false;
  List<Section> _sections = const <Section>[];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialActivity;
    if (initial != null) {
      _nameController.text = initial.name;
      _descriptionController.text = initial.description ?? '';
      _pointsController.text = initial.maxPoints.toStringAsFixed(1);
      _scheduledAt = initial.scheduledAt?.toLocal();
      _dueDate = initial.dueDate?.toLocal();
      _gradeId = initial.gradeId;
      _sectionId = initial.sectionId;
      _subjectId = initial.subjectId;
      _periodId = initial.periodId;
      _type = initial.type;
    }

    if (_gradeId != null) {
      Future.microtask(() => _loadSections(_gradeId!));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(activeGradesProvider);
    final subjectsAsync = ref.watch(activeSubjectsProvider);
    final periodAsync = ref.watch(periodOptionsProvider);

    final isEditing = widget.initialActivity != null;

    final grades = gradesAsync.value ?? const <Grade>[];
    final subjects = subjectsAsync.value ?? const <Subject>[];
    final periods = periodAsync.value ?? const <PeriodOption>[];

    Grade? selectedGrade;
    if (_gradeId != null) {
      try {
        selectedGrade = grades.firstWhere((g) => g.id == _gradeId);
      } catch (_) {}
    }

    Subject? selectedSubject;
    if (_subjectId != null) {
      try {
        selectedSubject = subjects.firstWhere((s) => s.id == _subjectId);
      } catch (_) {}
    }

    PeriodOption? selectedPeriod;
    if (_periodId != null) {
      try {
        selectedPeriod = periods.firstWhere((p) => p.id == _periodId);
      } catch (_) {}
    }

    Section? selectedSection;
    if (_sectionId != null) {
      try {
        selectedSection = _sections.firstWhere((s) => s.id == _sectionId);
      } catch (_) {}
    }

    final sectionPlaceholder = _gradeId == null
        ? 'Selecciona un grado primero'
        : _loadingSections
            ? 'Cargando secciones...'
            : _sections.isEmpty
                ? 'No hay secciones disponibles'
                : 'Selecciona una sección';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Editar actividad' : 'Nueva actividad',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la actividad',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pointsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Puntos máximos',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DatePickerField(
                  label: 'Fecha programada',
                  value: _scheduledAt,
                  onChanged: (date) => setState(() => _scheduledAt = date),
                ),
                const SizedBox(height: 12),
                _DatePickerField(
                  label: 'Fecha de entrega (opcional)',
                  value: _dueDate,
                  onChanged: (date) => setState(() => _dueDate = date),
                ),
                const SizedBox(height: 12),
                SelectField<Subject>(
                  label: 'Materia',
                  placeholder: subjectsAsync.isLoading
                      ? 'Cargando materias...'
                      : 'Selecciona una materia',
                  value: selectedSubject,
                  items: subjects,
                  itemLabel: (s) => s.name,
                  onSelected: (value) => setState(() => _subjectId = value.id),
                ),
                const SizedBox(height: 12),
                SelectField<Grade>(
                  label: 'Grado',
                  placeholder: gradesAsync.isLoading
                      ? 'Cargando grados...'
                      : 'Selecciona un grado',
                  value: selectedGrade,
                  items: grades,
                  itemLabel: (g) => g.name,
                  onSelected: (value) {
                    setState(() {
                      _gradeId = value.id;
                      _sectionId = null;
                      _sections = const [];
                    });
                    _loadSections(value.id);
                  },
                ),
                const SizedBox(height: 12),
                SelectField<Section>(
                  label: 'Sección',
                  placeholder: sectionPlaceholder,
                  value: selectedSection,
                  items: _sections,
                  itemLabel: (s) => s.name,
                  enabled: _gradeId != null && !_loadingSections,
                  onSelected: (value) => setState(() => _sectionId = value.id),
                ),
                const SizedBox(height: 12),
                SelectField<PeriodOption>(
                  label: 'Período académico',
                  placeholder: periodAsync.isLoading
                      ? 'Cargando períodos...'
                      : 'Selecciona un período',
                  value: selectedPeriod,
                  items: periods,
                  itemLabel: (p) => p.name,
                  onSelected: (value) => setState(() => _periodId = value.id),
                ),
                const SizedBox(height: 12),
                SelectField<String>(
                  label: 'Tipo de actividad',
                  placeholder: 'Selecciona un tipo',
                  value: _type,
                  items: ref.read(activityTypesProvider),
                  itemLabel: (value) => value,
                  onSelected: (value) => setState(() => _type = value),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: BlackButton(
                    label: _saving
                        ? 'Guardando...'
                        : isEditing
                            ? 'Actualizar actividad'
                            : 'Crear actividad',
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null || _gradeId == null || _sectionId == null || _periodId == null) {
      _showMessage('Selecciona materia, grado, sección y período.');
      return;
    }
    if (_type == null || _type!.isEmpty) {
      _showMessage('Selecciona un tipo de actividad.');
      return;
    }

    setState(() => _saving = true);

    final points = double.parse(_pointsController.text);

    final gradeList = ref.read(activeGradesProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <Grade>[],
        );
    final subjectList = ref.read(activeSubjectsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <Subject>[],
        );
    final periodList = ref.read(periodOptionsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <PeriodOption>[],
        );

    final gradeName =
        gradeList.firstWhereOrNull((element) => element.id == _gradeId)?.name;
    final subjectName = subjectList
        .firstWhereOrNull((element) => element.id == _subjectId)
        ?.name;
    final periodName = periodList
        .firstWhereOrNull((element) => element.id == _periodId)
        ?.name;
    final sectionName = _sections
        .firstWhereOrNull((element) => element.id == _sectionId)
        ?.name;

    final activity = Activity(
      id: widget.initialActivity?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      teacherId: widget.teacherId,
      subjectId: _subjectId!,
      gradeId: _gradeId!,
      sectionId: _sectionId!,
      periodId: _periodId!,
      type: _type!,
      maxPoints: points,
      scheduledAt: _scheduledAt,
      dueDate: _dueDate,
      status: widget.initialActivity?.status ?? 'pendiente',
      createdAt: widget.initialActivity?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      gradedStudents: widget.initialActivity?.gradedStudents,
      totalStudents: widget.initialActivity?.totalStudents,
      averagePercentage: widget.initialActivity?.averagePercentage,
      subjectName: subjectName,
      gradeName: gradeName,
      sectionName: sectionName,
      periodName: periodName,
    );

    try {
      if (widget.initialActivity == null) {
        await ref.read(createActivityProvider)(activity);
        _showMessage('Actividad creada correctamente');
      } else {
        await ref.read(updateActivityProvider)(activity);
        _showMessage('Actividad actualizada correctamente');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMessage('Error guardando actividad: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadSections(int gradeId) async {
    setState(() {
      _loadingSections = true;
      _sections = const <Section>[];
    });

    try {
      final repo = ref.read(sectionRepositoryProvider);
      final result = await repo.findByGrade(gradeId);
      if (!mounted) return;
      setState(() {
        _sections = result;
        if (_sectionId != null && !result.any((s) => s.id == _sectionId)) {
          _sectionId = null;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSections = false;
        });
      }
    }
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 2),
            );
            onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6E7EA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? 'Selecciona una fecha' : formatter.format(value!),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: value == null ? FontWeight.w500 : FontWeight.w700,
                      color: value == null ? Colors.black54 : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.black87),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ActivityGradeSheet extends ConsumerStatefulWidget {
  const ActivityGradeSheet({
    super.key,
    required this.activity,
    required this.teacherId,
  });

  final Activity activity;
  final int teacherId;

  @override
  ConsumerState<ActivityGradeSheet> createState() => _ActivityGradeSheetState();
}

class _ActivityGradeSheetState extends ConsumerState<ActivityGradeSheet> {
  final Map<int, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(activityGradesProvider(widget.activity.id!));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: gradesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error al cargar estudiantes: $error'),
              ),
              data: (grades) {
                for (final grade in grades) {
                  _controllers.putIfAbsent(
                    grade.studentId,
                    () => TextEditingController(
                      text: grade.obtainedPoints?.toStringAsFixed(1) ?? '',
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Calificar ${widget.activity.name}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.activity.subjectName ?? 'Materia'} • ${widget.activity.gradeName ?? ''} ${widget.activity.sectionName ?? ''}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        itemCount: grades.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFECEDEF)),
                        itemBuilder: (context, index) {
                          final grade = grades[index];
                          final controller = _controllers[grade.studentId]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        grade.studentName ?? 'Estudiante',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (grade.percentage != null)
                                        Text(
                                          'Actual: ${grade.percentage!.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: controller,
                                    textAlign: TextAlign.center,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      hintText: '0-${widget.activity.maxPoints.toStringAsFixed(0)}',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            const BorderSide(color: Colors.black26),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: BlackButton(
                        label: _saving ? 'Guardando...' : 'Guardar calificaciones',
                        onPressed: _saving ? null : () => _save(grades),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(List<ActivityGrade> grades) async {
    setState(() => _saving = true);
    final entries = <ActivityGrade>[];

    for (final grade in grades) {
      final controller = _controllers[grade.studentId]!;
      final text = controller.text.trim();
      if (text.isEmpty) {
        entries.add(grade.copyWith(obtainedPoints: null, percentage: null));
        continue;
      }

      final value = double.tryParse(text);
      if (value == null) {
        setState(() => _saving = false);
        _showMessage('Valor inválido para ${grade.studentName ?? 'estudiante'}');
        return;
      }

      if (value < 0 || value > widget.activity.maxPoints) {
        setState(() => _saving = false);
        _showMessage(
            'La nota de ${grade.studentName ?? 'estudiante'} debe estar entre 0 y ${widget.activity.maxPoints.toStringAsFixed(1)}');
        return;
      }

      entries.add(grade.copyWith(obtainedPoints: value));
    }

    try {
      await ref.read(gradeActivityProvider)(
        activityId: widget.activity.id!,
        gradedBy: widget.teacherId,
        grades: entries,
      );
      _showMessage('Calificaciones guardadas correctamente');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMessage('Error al guardar calificaciones: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
