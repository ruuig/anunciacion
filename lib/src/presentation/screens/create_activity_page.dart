import 'package:anunciacion/src/presentation/screens/activities_manager.dart';
import 'package:flutter/material.dart'; // donde está tu clase Activity
import 'package:anunciacion/src/presentation/presentation.dart';

class CreateActivityPage extends StatefulWidget {
  final List<String> subjects;
  final List<String> grades;
  final List<String> sections;
  final List<String> periods;
  final List<String> types;

  // si quieres reutilizar para editar:
  final Activity? initial;

  const CreateActivityPage({
    super.key,
    required this.subjects,
    required this.grades,
    required this.sections,
    required this.periods,
    required this.types,
    this.initial,
  });

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _pointsCtrl;
  late DateTime _date;

  String? _subject;
  String? _grade;
  String? _section;
  String? _period;
  String? _type;
  bool _isGroupWork = false;
  List<_GroupDraft> _groups = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _descCtrl = TextEditingController(text: widget.initial?.description ?? '');
    _pointsCtrl = TextEditingController(
      text: widget.initial?.points.toString() ?? '',
    );
    _date = widget.initial?.date ??
        DateTime(now.year, now.month, now.day); // fecha de hoy

    _subject = widget.initial?.subject;
    _grade = widget.initial?.grade;
    _section = widget.initial?.section;
    _period = widget.initial?.period;
    _type = widget.initial?.type;
    _isGroupWork = widget.initial?.isGroupWork ?? false;

    // si algún día quieres venir con grupos del backend:
    // _groups = ...
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _save() {
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

    final pts = int.tryParse(_pointsCtrl.text.trim()) ?? 0;

    // si es edición, respetamos el id
    final activity = (widget.initial ??
            Activity(
              id: DateTime.now().millisecondsSinceEpoch,
              name: _nameCtrl.text.trim(),
              subject: _subject!,
              grade: _grade!,
              section: _section!,
              period: _period!,
              type: _type!,
              points: pts,
              date: _date,
              status: 'pending',
              studentsGraded: 0,
              totalStudents: 28,
              averageGrade: null,
              description: _descCtrl.text.trim(),
              isGroupWork: _isGroupWork,
            ))
        .copyWith(
      name: _nameCtrl.text.trim(),
      subject: _subject!,
      grade: _grade!,
      section: _section!,
      period: _period!,
      type: _type!,
      points: pts,
      date: _date,
      description: _descCtrl.text.trim(),
      isGroupWork: _isGroupWork,
    );

    Navigator.pop(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER blanco como el que quieres
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Editar actividad' : 'Nueva actividad',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  // si quieres que se guarde explícito, descomenta
                  // BlackButton(label: 'Guardar', onPressed: _save),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // card principal como las de "gestión de actividades"
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Datos principales',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nombre de la actividad',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameCtrl,
                          decoration: _inputDecoration(
                            'Ej. Examen Parcial - Fracciones',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Descripción',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descCtrl,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _inputDecoration(
                              'Instrucciones, rúbrica o recordatorios'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // card de selects
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalles académicos',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
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
                        const Text(
                          'Puntos máximos',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pointsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Ej. 25'),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Fecha',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(_date.year - 1),
                              lastDate: DateTime(_date.year + 2),
                            );
                            if (picked != null) {
                              setState(() => _date = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmtDate(_date)),
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Trabajo grupal
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Switch(
                              value: _isGroupWork,
                              activeColor: Colors.black,
                              onChanged: (v) {
                                setState(() {
                                  _isGroupWork = v;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Trabajo grupal',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (_isGroupWork) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Grupos',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          ..._groups.asMap().entries.map((e) {
                            final i = e.key;
                            final g = e.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F1F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      g.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    g.members.isEmpty
                                        ? 'Sin alumnos'
                                        : '${g.members.length} alumnos',
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 12),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      setState(() => _groups.removeAt(i));
                                    },
                                  )
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          BlackButton(
                            label: 'Agregar grupo',
                            icon: Icons.group_add_outlined,
                            onPressed: () {
                              setState(() {
                                _groups.add(
                                  _GroupDraft(
                                    name: 'Grupo ${_groups.length + 1}',
                                    members: [],
                                  ),
                                );
                              });
                            },
                          ),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: BlackButton(
                      label: isEdit ? 'Guardar cambios' : 'Guardar actividad',
                      onPressed: _save,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
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
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// helper
String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

class _GroupDraft {
  final String name;
  final List<String> members;
  _GroupDraft({required this.name, required this.members});
}
