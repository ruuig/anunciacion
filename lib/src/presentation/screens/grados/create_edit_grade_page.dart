import 'package:flutter/material.dart';
import '../../widgets/app_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/select_field.dart';
import '../../widgets/black_button.dart';
import '../../../domain/entities/grade.dart';
import '../../../domain/entities/user.dart';
import '../../../infrastructure/repositories/http_grade_repository.dart';
import '../../../infrastructure/http/http_client.dart';
import '../../../domain/value_objects/value_objects.dart';

class CreateEditGradePage extends StatefulWidget {
  final Grade? grade;

  const CreateEditGradePage({super.key, this.grade});

  @override
  State<CreateEditGradePage> createState() => _CreateEditGradePageState();
}

class _CreateEditGradePageState extends State<CreateEditGradePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageRangeController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  int _selectedLevel = 1; // Por defecto Primaria

  final _gradeRepository = HttpGradeRepository();
  final _httpClient = HttpClient();

  // Docentes
  List<User> _allTeachers = [];
  Set<int> _selectedTeacherIds = {};
  bool _isLoadingTeachers = false;

  // Niveles educativos
  final List<Map<String, dynamic>> _levels = [
    {'id': 1, 'name': 'Primaria'},
    {'id': 2, 'name': 'Básicos'},
    {'id': 3, 'name': 'Diversificado'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    if (widget.grade != null) {
      _populateFields();
      _loadGradeTeachers();
    } else {
      // Año académico por defecto
      _academicYearController.text = DateTime.now().year.toString();
    }
  }

  void _populateFields() {
    final grade = widget.grade!;
    _nameController.text = grade.name;
    _ageRangeController.text = grade.ageRange ?? '';
    // Extraer solo el año si viene en formato "2024-2025"
    final year = grade.academicYear.contains('-') 
        ? grade.academicYear.split('-')[1] 
        : grade.academicYear;
    _academicYearController.text = year;
    _selectedLevel = grade.educationalLevelId;
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoadingTeachers = true);
    try {
      final data = await _httpClient.getList('/users');
      final users =
          data.map((json) => _mapToUser(json as Map<String, dynamic>)).toList();
      final teachers = users.where((u) => u.roleId == 2).toList();
      setState(() {
        _allTeachers = teachers;
        _isLoadingTeachers = false;
      });
    } catch (e) {
      setState(() => _isLoadingTeachers = false);
      print('Error loading teachers: $e');
    }
  }

  Future<void> _loadGradeTeachers() async {
    if (widget.grade == null) return;
    try {
      // Extraer solo el año si viene en formato "2024-2025"
      final year = widget.grade!.academicYear.contains('-') 
          ? widget.grade!.academicYear.split('-')[1] 
          : widget.grade!.academicYear;
      print('Loading teachers for grade ${widget.grade!.id}, year $year');
      final teachers = await _gradeRepository.getGradeTeachers(
        widget.grade!.id,
        year,
      );
      print('Loaded ${teachers.length} teachers: $teachers');
      setState(() {
        _selectedTeacherIds = teachers.map((t) => t['id'] as int).toSet();
      });
      print('Selected teacher IDs: $_selectedTeacherIds');
    } catch (e) {
      print('Error loading grade teachers: $e');
    }
  }

  User _mapToUser(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      passwordHash: Password.fromPlainText(''),
      roleId: json['roleId'] ?? 0,
      phone: null, // No necesitamos el teléfono para asignar docentes
      status: UserStatus.fromString(json['status'] ?? 'activo'),
      avatarUrl: json['avatarUrl'],
      lastAccess: json['lastAccess'] != null
          ? DateTime.parse(json['lastAccess'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  List<User> _getFilteredTeachers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _allTeachers;
    return _allTeachers
        .where((t) => t.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageRangeController.dispose();
    _academicYearController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final academicYear = _academicYearController.text.trim();
      
      // Crear o usar grado existente
      late Grade savedGrade;
      if (widget.grade == null) {
        // Crear nuevo grado
        final newGrade = Grade(
          id: 0,
          name: _nameController.text.trim(),
          educationalLevelId: _selectedLevel,
          ageRange: _ageRangeController.text.trim().isEmpty
              ? null
              : _ageRangeController.text.trim(),
          academicYear: academicYear,
          active: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        savedGrade = await _gradeRepository.save(newGrade);
      } else {
        // Usar grado existente
        savedGrade = widget.grade!;
      }

      // Asignar docentes al grado
      // Si es edición, primero remover docentes anteriores
      if (widget.grade != null) {
        try {
          final currentTeachers = await _gradeRepository.getGradeTeachers(
            widget.grade!.id,
            widget.grade!.academicYear,
          );
          for (final teacher in currentTeachers) {
            await _gradeRepository.removeTeacher(
              widget.grade!.id,
              teacher['id'] as int,
              widget.grade!.academicYear,
            );
          }
        } catch (e) {
          print('Error removing old teachers: $e');
        }
      }
      
      // Asignar nuevos docentes
      for (final teacherId in _selectedTeacherIds) {
        await _gradeRepository.assignTeacher(
            savedGrade.id, teacherId, academicYear);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Guardado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Error al guardar'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.grade == null ? 'Nuevo Grado' : 'Editar Grado',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información Básica
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Grado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Nombre del Grado',
                      placeholder: 'Ej: 1ro Primaria',
                      icon: Icons.school,
                      controller: _nameController,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SelectField<int>(
                      label: 'Nivel Educativo',
                      placeholder: 'Selecciona el nivel',
                      value: _selectedLevel,
                      items: _levels.map((l) => l['id'] as int).toList(),
                      itemLabel: (id) =>
                          _levels.firstWhere((l) => l['id'] == id)['name'],
                      onSelected: (value) {
                        if (value != null) {
                          setState(() => _selectedLevel = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Rango de Edad',
                      placeholder: 'Ej: 6-7 años',
                      icon: Icons.cake,
                      controller: _ageRangeController,
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Año Académico',
                      placeholder: 'Ej: 2024',
                      icon: Icons.calendar_today,
                      controller: _academicYearController,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'El año académico es requerido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Asignación de Docentes
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Docentes Asignados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona los docentes que darán clases en este grado',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buscador
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar docente...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.black54),
                        filled: true,
                        fillColor: const Color(0xFFF1F2F4),
                        border: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // Lista de docentes
                    if (_isLoadingTeachers)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_allTeachers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No hay docentes registrados',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    else
                      ..._getFilteredTeachers().map((teacher) {
                        final isSelected =
                            _selectedTeacherIds.contains(teacher.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedTeacherIds.add(teacher.id);
                              } else {
                                _selectedTeacherIds.remove(teacher.id);
                              }
                            });
                          },
                          title: Text(
                            teacher.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: teacher.phone != null
                              ? Text(
                                  teacher.phone!.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                )
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.black,
                          dense: true,
                        );
                      }),

                    if (_selectedTeacherIds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedTeacherIds.length} docente(s) seleccionado(s)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoading
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                            ),
                          )
                        : BlackButton(
                            label: widget.grade == null
                                ? 'Crear Grado'
                                : 'Guardar Cambios',
                            onPressed: _save,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
