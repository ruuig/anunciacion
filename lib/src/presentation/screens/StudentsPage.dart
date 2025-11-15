import 'package:flutter/material.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/infrastructure/repositories/http_student_repository.dart';
import 'package:anunciacion/src/infrastructure/repositories/http_grade_repository.dart';
import 'student_detail_page.dart';
import '../widgets/app_card.dart';
import '../widgets/select_field.dart';
import '../widgets/input_field.dart';
import '../widgets/empty_state.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  // Repositories
  final _studentRepository = HttpStudentRepository();
  final _gradeRepository = HttpGradeRepository();

  // State
  List<Student> _allStudents = [];
  List<Grade> _grades = [];
  Grade? _selectedGrade;
  String _searchName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final grades = await _gradeRepository.findActiveGrades();
      final students = await _studentRepository.findAll();

      setState(() {
        _grades = grades;
        _allStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<Student> get _filteredStudents {
    return _allStudents.where((student) {
      // Filtrar por grado
      if (_selectedGrade != null && student.gradeId != _selectedGrade!.id) {
        return false;
      }
      // Filtrar por nombre
      if (_searchName.isNotEmpty &&
          !student.name.toLowerCase().contains(_searchName.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: .5,
        title: const Text(
          'Estudiantes',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Filtros
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_grades.isNotEmpty)
                          SelectField<String>(
                            label: 'Grado',
                            placeholder: 'Todos los grados',
                            value: _selectedGrade?.name ?? '',
                            items: ['', ..._grades.map((g) => g.name)],
                            itemLabel: (v) => v.isEmpty ? 'Todos' : v,
                            onSelected: (v) {
                              setState(() {
                                if (v.isEmpty) {
                                  _selectedGrade = null;
                                } else {
                                  _selectedGrade = _grades.firstWhere(
                                    (g) => g.name == v,
                                  );
                                }
                              });
                            },
                          ),
                        const SizedBox(height: 12),
                        InputField(
                          label: 'Nombre',
                          hintText: 'Buscar por nombre…',
                          icon: Icons.search,
                          onChanged: (v) => setState(() => _searchName = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista de estudiantes
                  if (_filteredStudents.isEmpty)
                    const EmptyState(
                      title: 'Sin resultados',
                      description:
                          'Ajusta los filtros o intenta con otro nombre.',
                      icon: Icon(
                        Icons.person_search_rounded,
                        size: 48,
                        color: Colors.black45,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredStudents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final s = _filteredStudents[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentDetailPage(student: s),
                              ),
                            );
                          },
                          child: AppCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFEFF4FF),
                                  child: Text(
                                    _initials(s.name),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        s.dpi.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final take = parts.length >= 2 ? parts.take(2) : parts.take(1);
    return take.map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }
}
