import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

class GradesTabBody extends StatefulWidget {
  final String userRole;
  final List<String> assignedGrades;

  const GradesTabBody({
    super.key,
    required this.userRole,
    required this.assignedGrades,
  });

  @override
  State<GradesTabBody> createState() => _GradesTabBodyState();
}

class _GradesTabBodyState extends State<GradesTabBody> {
  final subjects = ['Matemáticas', 'Español', 'Ciencias Naturales', 'Inglés'];
  final grades = [
    '1ro Primaria',
    '2do Primaria',
    '3ro Primaria',
    '4to Primaria'
  ];
  final sections = ['A', 'B', 'C'];
  final periods = [
    'Primer Bimestre',
    'Segundo Bimestre',
    'Tercer Bimestre',
    'Cuarto Bimestre'
  ];

  String? selectedSubject;
  String? selectedGrade;
  String? selectedSection;
  String? selectedPeriod;

  List<Map<String, dynamic>> students = [
    {'id': 1, 'name': 'Ana López', 'grade': null},
    {'id': 2, 'name': 'Carlos Mendez', 'grade': null},
    {'id': 3, 'name': 'María Hernández', 'grade': null},
    {'id': 4, 'name': 'Diego Ruiz', 'grade': null},
  ];

  bool get canShowStudents =>
      selectedSubject != null &&
      selectedGrade != null &&
      selectedSection != null &&
      selectedPeriod != null;

  void _saveGrades() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calificaciones guardadas exitosamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                SelectField<String>(
                  label: 'Materia',
                  placeholder: 'Selecciona una materia',
                  value: selectedSubject,
                  items: subjects,
                  itemLabel: (e) => e,
                  onSelected: (e) => setState(() => selectedSubject = e),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SelectField<String>(
                        label: 'Grado',
                        placeholder: 'Grado',
                        value: selectedGrade,
                        items: grades,
                        itemLabel: (e) => e,
                        onSelected: (e) => setState(() => selectedGrade = e),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectField<String>(
                        label: 'Sección',
                        placeholder: 'Sección',
                        value: selectedSection,
                        items: sections,
                        itemLabel: (e) => e,
                        onSelected: (e) => setState(() => selectedSection = e),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectField<String>(
                  label: 'Período',
                  placeholder: 'Selecciona el período',
                  value: selectedPeriod,
                  items: periods,
                  itemLabel: (e) => e,
                  onSelected: (e) => setState(() => selectedPeriod = e),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!canShowStudents)
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
                  for (final s in students) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(s['name'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0-100',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.black26),
                              ),
                            ),
                            onChanged: (val) {
                              final n = double.tryParse(val);
                              setState(() => s['grade'] = n);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFEAEAEA)),
                  ],
                  const SizedBox(height: 12),
                  _SummaryBox(students: students),
                  const SizedBox(height: 14),
                  BlackButton(
                      label: 'Guardar Calificaciones', onPressed: _saveGrades),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  const _SummaryBox({required this.students});

  @override
  Widget build(BuildContext context) {
    final aprobados = students.where((s) => (s['grade'] ?? 0) >= 70).length;
    final reprobados =
        students.where((s) => s['grade'] != null && s['grade'] < 70).length;
    final pendientes = students.where((s) => s['grade'] == null).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatBox(
            label: 'Aprobados',
            value: aprobados.toString(),
            color: Colors.green),
        _StatBox(
            label: 'Reprobados',
            value: reprobados.toString(),
            color: Colors.red),
        _StatBox(
            label: 'Pendientes',
            value: pendientes.toString(),
            color: Colors.black54),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
