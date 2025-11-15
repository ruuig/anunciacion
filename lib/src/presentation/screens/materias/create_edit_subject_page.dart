import 'package:flutter/material.dart';
import '../../widgets/app_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/black_button.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../infrastructure/repositories/http_subject_repository.dart';
import '../../../infrastructure/http/http_client.dart';

class CreateEditSubjectPage extends StatefulWidget {
  final Subject? subject;

  const CreateEditSubjectPage({super.key, this.subject});

  @override
  State<CreateEditSubjectPage> createState() => _CreateEditSubjectPageState();
}

class _CreateEditSubjectPageState extends State<CreateEditSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  List<User> _allTeachers = [];
  Set<int> _selectedTeacherIds = {};
  String _teacherSearchQuery = '';

  final _subjectRepository = HttpSubjectRepository();
  final _httpClient = HttpClient();

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.subject != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final subject = widget.subject!;
    _nameController.text = subject.name;
    _codeController.text = subject.code ?? '';
    _descriptionController.text = subject.description ?? '';

    // Cargar docentes asignados
    if (subject.teachers != null) {
      _selectedTeacherIds =
          subject.teachers!.map((t) => t['id'] as int).toSet();
    }
  }

  Future<void> _loadData() async {
    try {
      // Cargar solo usuarios con rol de docente (roleId = 2)
      print('🔍 Cargando usuarios desde /users...');
      final data = await _httpClient.getList('/users');
      print('📦 Usuarios recibidos: ${data.length}');

      final users = data.map((json) {
        final user = _mapToUser(json as Map<String, dynamic>);
        print('   Usuario: ${user.name}, roleId: ${user.roleId}');
        return user;
      }).toList();
      print('👥 Total usuarios mapeados: ${users.length}');

      final teachers = users.where((u) {
        print(
            '   Verificando ${u.name}: roleId=${u.roleId}, es docente? ${u.roleId == 2}');
        return u.roleId == 2;
      }).toList();
      print('👨‍🏫 Docentes filtrados (roleId=2): ${teachers.length}');

      if (teachers.isNotEmpty) {
        print('   Primer docente: ${teachers.first.name}');
      }

      setState(() {
        _allTeachers = teachers;
      });
    } catch (e, stackTrace) {
      print('❌ Error al cargar docentes: $e');
      print('📍 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar docentes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  User _mapToUser(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      passwordHash:
          Password.fromPlainText(''), // No necesitamos la contraseña aquí
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

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final subject = Subject(
        id: widget.subject?.id ?? 0,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isEmpty
            ? null
            : _codeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        active: widget.subject?.active ?? true,
        createdAt: widget.subject?.createdAt ?? DateTime.now(),
      );

      Subject savedSubject;
      if (widget.subject == null) {
        savedSubject = await _subjectRepository.save(subject);
      } else {
        savedSubject = await _subjectRepository.update(subject);
      }

      // Gestionar asignación de docentes
      if (widget.subject != null) {
        // Obtener docentes actuales
        final currentTeachers =
            widget.subject!.teachers?.map((t) => t['id'] as int).toSet() ?? {};

        // Docentes a agregar
        final toAdd = _selectedTeacherIds.difference(currentTeachers);
        for (final teacherId in toAdd) {
          await _subjectRepository.assignTeacher(savedSubject.id, teacherId);
        }

        // Docentes a remover
        final toRemove = currentTeachers.difference(_selectedTeacherIds);
        for (final teacherId in toRemove) {
          await _subjectRepository.removeTeacher(savedSubject.id, teacherId);
        }
      } else {
        // Nueva materia, asignar todos los docentes seleccionados
        for (final teacherId in _selectedTeacherIds) {
          await _subjectRepository.assignTeacher(savedSubject.id, teacherId);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.subject == null
                ? 'Materia creada exitosamente'
                : 'Materia actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
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
          widget.subject == null ? 'Nueva Materia' : 'Editar Materia',
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
                      'Información de la Materia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Nombre de la Materia',
                      placeholder: 'Ej: Matemáticas',
                      icon: Icons.book,
                      controller: _nameController,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Código',
                      placeholder: 'Ej: MAT-101',
                      icon: Icons.tag,
                      controller: _codeController,
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Descripción',
                      placeholder: 'Descripción de la materia',
                      icon: Icons.description,
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Docentes Asignados
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Docentes que Imparten esta Materia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona los docentes que pueden dar esta materia',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo de búsqueda
                    InputField(
                      label: 'Buscar Docente',
                      placeholder: 'Buscar por nombre...',
                      icon: Icons.search,
                      onChanged: (value) {
                        setState(() {
                          _teacherSearchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildTeacherSelector(),
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
                            label: widget.subject == null
                                ? 'Crear Materia'
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

  Widget _buildTeacherSelector() {
    // Filtrar docentes según la búsqueda
    final filteredTeachers = _allTeachers.where((teacher) {
      if (_teacherSearchQuery.isEmpty) return true;
      final query = _teacherSearchQuery.toLowerCase();
      return teacher.name.toLowerCase().contains(query);
    }).toList();

    if (_allTeachers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No hay docentes registrados',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (filteredTeachers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No se encontraron docentes',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        shrinkWrap: true,
        children: filteredTeachers.map((teacher) {
          final isSelected = _selectedTeacherIds.contains(teacher.id);

          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedTeacherIds.remove(teacher.id);
                } else {
                  _selectedTeacherIds.add(teacher.id);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.black.withOpacity(0.05) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black12,
                    width: filteredTeachers.last == teacher ? 0 : 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.black26,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      teacher.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
