import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anunciacion/src/infrastructure/http/http_grades_repository.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';
import 'package:anunciacion/src/presentation/providers/user_provider.dart';
import '../widgets/widgets.dart';

class NotasPage extends ConsumerStatefulWidget {
  final String userRole; // 'Docente' | 'Secretaria'
  final List<String> assignedGrades; // p.ej. ['3ro Primaria','4to Primaria']
  const NotasPage(
      {super.key, required this.userRole, this.assignedGrades = const []});

  @override
  ConsumerState<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends ConsumerState<NotasPage> {
  final _httpClient = HttpClient();
  final _gradesRepository = HttpGradesRepository();

  // State variables
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _students = [];

  Map<String, dynamic>? _selectedGrade;
  Map<String, dynamic>? _selectedSubject;
  int _selectedPeriod = 1;
  int _selectedYear = DateTime.now().year;

  bool _isLoading = false;
  Map<int, TextEditingController> _gradeControllers = {};

  final _periods = [1, 2, 3, 4];

  late int _docenteId;

  @override
  void initState() {
    super.initState();
    // Obtener el ID del docente del usuario autenticado
    final userState = ref.read(userProvider);
    _docenteId = userState.currentUser?.id ?? 0;
    _loadGrades();
  }

  @override
  void dispose() {
    for (var controller in _gradeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      // Cargar materias asignadas al docente actual
      final subjects = await _httpClient.getList(
        '/api/materias/teacher/$_docenteId',
      );

      // Cargar grados asignados al docente
      final grades = await _httpClient.getList(
        '/grades/teacher/$_docenteId',
      );

      setState(() {
        _subjects = subjects
            .map((s) => {
                  'id': s['id'],
                  'nombre': s['nombre'] ?? s['name'] ?? '',
                  'name': s['nombre'] ?? s['name'] ?? '',
                })
            .toList();
        _grades = List<Map<String, dynamic>>.from(grades);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedGrade == null || _selectedSubject == null) return;

    setState(() => _isLoading = true);
    try {
      final students = await _httpClient.getList(
        '/api/estudiantes?gradoId=${_selectedGrade!['id']}',
      );

      // Cargar calificaciones existentes
      final grades = await _gradesRepository.getGrades(
        materiaId: _selectedSubject!['id'],
        gradoId: _selectedGrade!['id'],
        periodo: _selectedPeriod.toString(),
        anoAcademico: _selectedYear,
      );

      // Mapear estudiantes con sus calificaciones
      final studentsList = List<Map<String, dynamic>>.from(students);
      for (var student in studentsList) {
        final gradeData = grades.firstWhere(
          (g) => g['estudianteId'] == student['id'],
          orElse: () => {},
        );
        student['grade'] =
            gradeData['notaManual'] ?? gradeData['notaFinal'] ?? '';
      }

      setState(() {
        _students = studentsList;
        _isLoading = false;

        // Inicializar controladores
        _gradeControllers.clear();
        for (var student in _students) {
          _gradeControllers[student['id']] = TextEditingController(
            text: student['grade']?.toString() ?? '',
          );
        }
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estudiantes: $e')),
        );
      }
    }
  }

  Future<void> _saveGrades() async {
    if (_selectedGrade == null || _selectedSubject == null) return;

    setState(() => _isLoading = true);
    try {
      for (var student in _students) {
        final gradeText = _gradeControllers[student['id']]?.text ?? '';
        if (gradeText.isNotEmpty) {
          final grade = double.tryParse(gradeText);
          if (grade != null) {
            await _gradesRepository.saveManualGrade(
              estudianteId: student['id'],
              materiaId: _selectedSubject!['id'],
              gradoId: _selectedGrade!['id'],
              docenteId: _docenteId,
              periodo: _selectedPeriod.toString(),
              anoAcademico: _selectedYear,
              notaManual: grade,
            );
          }
        }
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Calificaciones guardadas correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving grades: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar calificaciones: $e')),
        );
      }
    }
  }

  int get _aprobados => _students.where((s) {
        final grade = double.tryParse(_gradeControllers[s['id']]?.text ?? '');
        return grade != null && grade >= 60;
      }).length;

  int get _reprobados => _students.where((s) {
        final grade = double.tryParse(_gradeControllers[s['id']]?.text ?? '');
        return grade != null && grade < 60;
      }).length;

  int get _pendientes => _students.where((s) {
        final text = _gradeControllers[s['id']]?.text ?? '';
        return text.isEmpty;
      }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calificaciones',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading && _subjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingreso de Calificaciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecciona la clase y el período para registrar notas.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selector de Materia
                      const Text(
                        'Materia',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 0),
                      SelectField<Map<String, dynamic>>(
                        label: '',
                        placeholder: 'Selecciona una materia',
                        value: _selectedSubject,
                        items: _subjects,
                        itemLabel: (s) => s['nombre'] ?? s['name'] ?? '',
                        onSelected: (v) {
                          setState(() => _selectedSubject = v);
                          _loadStudents();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Grado y Período en la misma fila
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Grado',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 0),
                                SelectField<Map<String, dynamic>>(
                                  label: '',
                                  placeholder: 'Grado',
                                  value: _selectedGrade,
                                  items: _grades,
                                  itemLabel: (g) => g['name'] ?? '',
                                  onSelected: (v) {
                                    setState(() => _selectedGrade = v);
                                    _loadStudents();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Período',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 0),
                                SelectField<int>(
                                  label: '',
                                  placeholder: 'Período',
                                  value: _selectedPeriod,
                                  items: _periods,
                                  itemLabel: (p) => 'Bimestre $p',
                                  onSelected: (v) {
                                    setState(() => _selectedPeriod = v);
                                    _loadStudents();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de Estudiantes
                if (_students.isNotEmpty)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lista de Estudiantes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._students.map((student) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      student['name'] ?? 'Sin nombre',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 100,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller:
                                          _gradeControllers[student['id']],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: '0-100',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 12),

                        // Estadísticas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$_aprobados',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.green,
                                  ),
                                ),
                                const Text(
                                  'Aprobados',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '$_reprobados',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.red,
                                  ),
                                ),
                                const Text(
                                  'Reprobados',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '$_pendientes',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Text(
                                  'Pendientes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BlackButton(
                          label: _isLoading
                              ? 'Guardando...'
                              : 'Guardar Calificaciones',
                          onPressed: _isLoading ? null : _saveGrades,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
