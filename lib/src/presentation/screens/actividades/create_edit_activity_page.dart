import 'package:flutter/material.dart';
import 'package:anunciacion/src/domain/entities/activity.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';

class CreateEditActivityPage extends StatefulWidget {
  final String name;
  final Activity? initial;
  final List<String> grades;
  final List<String> periods;
  final List<String> subjects;
  final List<String> sections;

  const CreateEditActivityPage({
    super.key,
    required this.name,
    this.initial,
    required this.grades,
    required this.periods,
    required this.subjects,
    required this.sections,
  });

  @override
  State<CreateEditActivityPage> createState() => _CreateEditActivityPageState();
}

class _CreateEditActivityPageState extends State<CreateEditActivityPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _pointsCtrl;

  String? _subject;
  String? _grade;
  String? _section;
  String? _period;
  String? _type;
  DateTime _date = DateTime.now();
  bool _isGroupWork = false;
  List<ActivityGroup> _groups = [];

  final _types = const ['Examen', 'Tarea', 'Proyecto', 'Laboratorio'];

  // 🔹 Mock de estudiantes por grado (esto luego lo traes de tu backend)
  final Map<String, List<String>> _studentsByGrade = {
    '1ro Primaria': ['Ana', 'Brandon', 'Carlos', 'Dafne', 'Erick'],
    '2do Primaria': ['Alma', 'Beto', 'Camila', 'David', 'Esteban'],
    '3ro Primaria': ['Alexa', 'Diego', 'Sofía', 'Luis', 'Marta'],
    '4to Primaria': ['Pablo', 'Rocío', 'Valeria', 'Kevin', 'Gerson'],
    '5to Primaria': ['Carla', 'Román', 'Josefina', 'Ulises', 'Marcos'],
    '6to Primaria': ['Rudy', 'Fiorella', 'Ian', 'Paola', 'Selena'],
  };

  List<String> get _availableStudents {
    if (_grade == null) return const [];
    return _studentsByGrade[_grade] ?? const [];
  }

  @override
  void initState() {
    super.initState();
    final i = widget.initial;

    _titleCtrl = TextEditingController(text: i?.name ?? '');
    _descCtrl = TextEditingController(text: i?.description ?? '');
    _pointsCtrl = TextEditingController(
      text: i != null ? i.points.toString() : '',
    );

    _subject = i?.subject;
    _grade = i?.grade;
    _section = i?.section;
    _period = i?.period;
    _type = i?.type ?? _types.first;
    _date = i?.date ?? DateTime.now();
    _isGroupWork = i?.isGroupWork ?? false;
    _groups = i?.groups ?? [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty ||
        _subject == null ||
        _grade == null ||
        _section == null ||
        _period == null ||
        _pointsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios')),
      );
      return;
    }

    final pts = int.tryParse(_pointsCtrl.text.trim()) ?? 0;

    final created = Activity(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      subject: _subject!,
      grade: _grade!,
      section: _section!,
      period: _period!,
      type: _type ?? 'Examen',
      points: pts,
      date: _date,
      isGroupWork: _isGroupWork,
      groups: _isGroupWork ? _groups : const [],
      status: widget.initial?.status ?? 'pending',
      studentsGraded: widget.initial?.studentsGraded ?? 0,
      totalStudents: widget.initial?.totalStudents ?? 28,
      averageGrade: widget.initial?.averageGrade,
    );

    Navigator.pop(context, created);
  }

  void _addGroup() {
    setState(() {
      _groups = List<ActivityGroup>.from(_groups)
        ..add(
          ActivityGroup(
            name: 'Grupo ${_groups.length + 1}',
            members: const [],
          ),
        );
    });
  }

  // 🔹 abrir selector de alumnos para un grupo
  Future<void> _pickStudentForGroup(int groupIndex) async {
    final students = _availableStudents;
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona un grado')),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Seleccionar estudiante',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final name = students[i];
                    final alreadyIn =
                        _groups[groupIndex].members.contains(name);
                    return ListTile(
                      title: Text(name),
                      trailing: alreadyIn
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        Navigator.pop(context, name);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        final g = _groups[groupIndex];
        if (!g.members.contains(selected)) {
          final updatedMembers = List<String>.from(g.members)..add(selected);
          _groups[groupIndex] = g.copyWith(members: updatedMembers);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // ahora SOLO regresa, no guarda
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
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
            // datos principales
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos principales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Título',
                    child: TextField(
                      controller: _titleCtrl,
                      decoration: _input('Ej. Examen Parcial - Fracciones'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Descripción',
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: _input(
                        'Instrucciones, rúbrica o recordatorios (opcional)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectField<String>(
                    label: 'Materia',
                    placeholder: 'Selecciona',
                    value: _subject,
                    items: widget.subjects,
                    itemLabel: (e) => e,
                    onSelected: (v) => setState(() => _subject = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // asignación
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asignación',
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
                          placeholder: 'Selecciona',
                          value: _grade,
                          items: widget.grades,
                          itemLabel: (e) => e,
                          onSelected: (v) => setState(() {
                            _grade = v;
                            // opcional: limpiar grupos al cambiar de grado
                            // _groups = [];
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectField<String>(
                          label: 'Sección',
                          placeholder: 'Selecciona',
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
                    placeholder: 'Selecciona',
                    value: _period,
                    items: widget.periods,
                    itemLabel: (e) => e,
                    onSelected: (v) => setState(() => _period = v),
                  ),
                  const SizedBox(height: 12),
                  SelectField<String>(
                    label: 'Tipo',
                    placeholder: 'Selecciona',
                    value: _type,
                    items: _types,
                    itemLabel: (e) => e,
                    onSelected: (v) => setState(() => _type = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // evaluación
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evaluación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Puntos máximos',
                    child: TextField(
                      controller: _pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _input('Ej. 25'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Fecha',
                    child: TextField(
                      readOnly: true,
                      decoration: _input(_fmtDate(_date)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _date = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: _isGroupWork,
                        activeColor: Colors.black,
                        onChanged: (v) => setState(() => _isGroupWork = v),
                      ),
                      const Text(
                        'Trabajo grupal',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (_isGroupWork) ...[
                    const SizedBox(height: 8),
                    Column(
                      children: _groups.asMap().entries.map((entry) {
                        final index = entry.key;
                        final g = entry.value;
                        return Card(
                          elevation: 0,
                          color: const Color(0xFFF0F1F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            title: Text(g.name),
                            subtitle: g.members.isEmpty
                                ? const Text('Sin integrantes')
                                : Text(g.members.join(', ')),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Agregar estudiante',
                                  icon: const Icon(
                                    Icons.person_add_alt_1_outlined,
                                  ),
                                  onPressed: () => _pickStudentForGroup(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    setState(() {
                                      _groups.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    BlackButton(
                      label: 'Agregar grupo',
                      icon: Icons.group_add_outlined,
                      onPressed: _addGroup,
                    ),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: BlackButton(
          label: 'Guardar',
          icon: Icons.check_rounded,
          onPressed: _save,
        ),
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF4F5F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
