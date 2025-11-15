import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';
import '../../widgets/input_field.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../infrastructure/repositories/http_parent_repository.dart';
import '../../../infrastructure/repositories/http_student_repository.dart';

class CreateEditParentPage extends StatefulWidget {
  final Parent? parent;

  const CreateEditParentPage({super.key, this.parent});

  @override
  State<CreateEditParentPage> createState() => _CreateEditParentPageState();
}

class _CreateEditParentPageState extends State<CreateEditParentPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _dpiController = TextEditingController();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();

  // State
  bool _isLoading = false;
  List<Student> _allStudents = [];
  Set<int> _selectedStudentIds = {};
  String _studentSearchQuery = '';

  // Repositories
  final _parentRepository = HttpParentRepository();
  final _studentRepository = HttpStudentRepository();

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.parent != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final parent = widget.parent!;
    _dpiController.text = parent.dpi?.value ?? '';
    _nameController.text = parent.name;
    _relationController.text = parent.relation;
    _phoneController.text = parent.phone.value;
    _secondaryPhoneController.text = parent.secondaryPhone?.value ?? '';
    _emailController.text = parent.email?.value ?? '';
    _addressController.text = parent.address?.street ?? '';
    _occupationController.text = parent.occupation ?? '';
  }

  Future<void> _loadData() async {
    try {
      final students = await _studentRepository.findAll();
      setState(() {
        _allStudents = students;
      });

      // Si estamos editando, cargar los estudiantes relacionados
      if (widget.parent != null) {
        final relatedStudents =
            await _parentRepository.getStudentsByParent(widget.parent!.id);
        setState(() {
          _selectedStudentIds = relatedStudents.toSet();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final parent = Parent.create(
        dpi: _dpiController.text.isNotEmpty
            ? DPI.fromString(_dpiController.text.trim())
            : null,
        name: _nameController.text.trim(),
        relation: _relationController.text.trim(),
        phone: Phone.fromString(_phoneController.text.trim()),
        secondaryPhone: _secondaryPhoneController.text.isNotEmpty
            ? Phone.fromString(_secondaryPhoneController.text.trim())
            : null,
        email: _emailController.text.isNotEmpty
            ? Email.fromString(_emailController.text.trim())
            : null,
        address: _addressController.text.isNotEmpty
            ? Address(
                street: _addressController.text.trim(),
                city: 'Guatemala',
                state: 'Guatemala',
                zipCode: '01001',
              )
            : null,
        occupation: _occupationController.text.isNotEmpty
            ? _occupationController.text.trim()
            : null,
      );

      int parentId;

      if (widget.parent != null) {
        // Actualizar padre existente
        final updatedParent = Parent(
          id: widget.parent!.id,
          dpi: parent.dpi,
          name: parent.name,
          relation: parent.relation,
          phone: parent.phone,
          secondaryPhone: parent.secondaryPhone,
          email: parent.email,
          address: parent.address,
          occupation: parent.occupation,
          createdAt: widget.parent!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _parentRepository.update(updatedParent);
        parentId = widget.parent!.id;
      } else {
        // Crear nuevo padre
        final created = await _parentRepository.save(parent);
        parentId = created.id;
      }

      // Asignar estudiantes seleccionados
      for (final studentId in _selectedStudentIds) {
        try {
          await _parentRepository.assignStudent(parentId, studentId);
        } catch (e) {
          // Ignorar si ya existe la relación
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.parent != null
                ? 'Padre/Madre actualizado exitosamente'
                : 'Padre/Madre creado exitosamente'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _dpiController.dispose();
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.parent != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Editar Padre/Madre' : 'Nuevo Padre/Madre',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Información Personal
            _buildSectionTitle('Información Personal'),
            const SizedBox(height: 16),

            InputField(
              label: 'DPI / CUI (Opcional)',
              placeholder: 'Ej: 1234567890101',
              controller: _dpiController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length != 13) {
                    return 'El DPI debe tener 13 dígitos';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Nombre Completo',
              placeholder: 'Ej: María José García López',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Relación',
              placeholder: 'Ej: Madre, Padre, Tutor',
              controller: _relationController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La relación es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Ocupación (Opcional)',
              placeholder: 'Ej: Docente, Comerciante',
              controller: _occupationController,
            ),
            const SizedBox(height: 24),

            // Información de Contacto
            _buildSectionTitle('Información de Contacto'),
            const SizedBox(height: 16),

            InputField(
              label: 'Teléfono Principal',
              placeholder: 'Ej: 50212345678',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El teléfono es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Teléfono Secundario (Opcional)',
              placeholder: 'Ej: 50298765432',
              controller: _secondaryPhoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Correo Electrónico (Opcional)',
              placeholder: 'Ej: correo@ejemplo.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Dirección (Opcional)',
              placeholder: 'Ej: Zona 1, Ciudad de Guatemala',
              controller: _addressController,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Estudiantes Relacionados
            _buildSectionTitle('Estudiantes a Cargo'),
            const SizedBox(height: 8),
            const Text(
              'Selecciona los estudiantes que están bajo el cuidado de este padre/madre',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Campo de búsqueda
            InputField(
              label: 'Buscar Estudiante',
              placeholder: 'Buscar por nombre o código...',
              icon: Icons.search,
              onChanged: (value) {
                setState(() {
                  _studentSearchQuery = value;
                });
              },
            ),
            const SizedBox(height: 12),

            _buildStudentSelector(),
            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black26),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: BlackButton(
                    label: isEdit ? 'Actualizar' : 'Crear Padre/Madre',
                    icon: _isLoading ? null : Icons.check,
                    onPressed: _isLoading ? null : _save,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.black,
      ),
    );
  }

  Widget _buildStudentSelector() {
    // Filtrar estudiantes según la búsqueda
    final filteredStudents = _allStudents.where((student) {
      if (_studentSearchQuery.isEmpty) return true;
      final query = _studentSearchQuery.toLowerCase();
      return student.name.toLowerCase().contains(query) ||
          (student.codigo?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (_allStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No hay estudiantes registrados',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (filteredStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No se encontraron estudiantes',
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
        children: filteredStudents.map((student) {
          final isSelected = _selectedStudentIds.contains(student.id);

          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedStudentIds.remove(student.id);
                } else {
                  _selectedStudentIds.add(student.id);
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
                    width: filteredStudents.last == student ? 0 : 1,
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
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Código: ${student.codigo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
