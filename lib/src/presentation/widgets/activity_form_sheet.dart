import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

class ActivityFormSheet extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initial;
  final List<String> subjects;
  final List<String> grades;
  final List<String> sections;
  final List<String> periods;
  final List<String> types;

  const ActivityFormSheet({
    super.key,
    required this.title,
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
  String? _date;
  bool _isGroupWork = false;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?['name'] ?? '');
    _pointsCtrl = TextEditingController(
      text: widget.initial?['points']?.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.initial?['description'] ?? '',
    );

    _subject = widget.initial?['subject'];
    _grade = widget.initial?['grade'];
    _section = widget.initial?['section'];
    _period = widget.initial?['period'];
    _type = widget.initial?['type'];
    _date = widget.initial?['date'] ?? _today();
    _isGroupWork = widget.initial?['isGroupWork'] == true;
    _groups = (widget.initial?['groups'] as List?)
            ?.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pointsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _addGroup() {
    setState(() {
      _groups.add({
        'name': 'Grupo ${_groups.length + 1}',
        'members': <String>[],
        'grade': null,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completa los datos de la actividad',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // NOMBRE
            const Text('Nombre',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDecoration('Ej. Examen Parcial'),
            ),
            const SizedBox(height: 12),

            // DESCRIPCIÓN
            const Text('Descripción',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: _inputDecoration(
                  'Instrucciones, rúbrica o recordatorios para el docente'),
            ),
            const SizedBox(height: 14),

            // Materia
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
              decoration: _inputDecoration('Ej. 25'),
            ),
            const SizedBox(height: 12),

            const Text('Fecha', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: _date),
              decoration: _inputDecoration('Selecciona fecha'),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 2),
                );
                if (picked != null) {
                  setState(() {
                    _date =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // trabajo grupal
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            if (_isGroupWork) ...[
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E6E9)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Grupos de trabajo',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    ..._groups.asMap().entries.map((e) {
                      final i = e.key;
                      final g = e.value;
                      final members =
                          (g['members'] as List?)?.cast<String>() ?? const [];
                      return ListTile(
                        dense: true,
                        title: Text(
                          g['name'] ?? 'Grupo ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          members.isEmpty
                              ? 'Sin integrantes'
                              : members.join(', '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.group_outlined),
                              onPressed: () {
                                // aquí luego tú abres tu selector real
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Elegir alumnos (demo)')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() => _groups.removeAt(i));
                              },
                            ),
                          ],
                        ),
                      );
                    }),
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
            ],

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
                    _pointsCtrl.text.trim().isEmpty ||
                    _date == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos')),
                  );
                  return;
                }

                final intPoints = int.tryParse(_pointsCtrl.text.trim()) ?? 0;

                Navigator.pop<Map<String, dynamic>>(context, {
                  'name': _nameCtrl.text.trim(),
                  'description': _descCtrl.text.trim(),
                  'subject': _subject,
                  'grade': _grade,
                  'section': _section,
                  'period': _period,
                  'type': _type,
                  'points': intPoints,
                  'date': _date,
                  'isGroupWork': _isGroupWork,
                  'groups': _isGroupWork ? _groups : <Map<String, dynamic>>[],
                });
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
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
