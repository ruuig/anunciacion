import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/widgets.dart';
import '../../widgets/input_field.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../infrastructure/repositories/http_student_repository.dart';
import '../../../infrastructure/repositories/http_grade_repository.dart';
import '../../../infrastructure/http/http_client.dart';

class CreateEditStudentPage extends StatefulWidget {
  final Student? student;

  const CreateEditStudentPage({super.key, this.student});

  @override
  State<CreateEditStudentPage> createState() => _CreateEditStudentPageState();
}

class _CreateEditStudentPageState extends State<CreateEditStudentPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _codigoController = TextEditingController();
  final _dpiController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();

  // State
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  int? _selectedGradeId;
  bool _hasBusService = false;
  bool _isLoading = false;

  // Data
  List<Grade> _grades = [];

  // Repositories
  final _studentRepository = HttpStudentRepository();
  final _gradeRepository = HttpGradeRepository();
  final _httpClient = HttpClient();

  @override
  void initState() {
    super.initState();

    _loadData();

    if (widget.student != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final student = widget.student!;
    _codigoController.text = student.codigo ?? '';
    _dpiController.text = student.dpi.value;
    _nameController.text = student.name;
    _selectedBirthDate = student.birthDate;
    _birthDateController.text = _formatDate(student.birthDate);
    _selectedGender = student.gender?.value.toString().split('.').last;
    _selectedGradeId = student.gradeId;
    _loadBusServiceStatus();
  }

  Future<void> _loadData() async {
    try {
      _grades = await _gradeRepository.findActiveGrades();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _loadBusServiceStatus() async {
    if (widget.student == null) return;

    try {
      final busStudents =
          await _httpClient.getList('/api/bus/students?activo=true');
      final hasBus =
          busStudents.any((s) => s['estudiante_id'] == widget.student!.id);
      setState(() {
        _hasBusService = hasBus;
      });
    } catch (e) {
      print('Error loading bus service status: $e');
    }
  }

  Future<void> _updateBusService(int studentId) async {
    try {
      final busStudents =
          await _httpClient.getList('/api/bus/students?activo=true');
      final hadBus = busStudents.any((s) => s['estudiante_id'] == studentId);

      if (_hasBusService && !hadBus) {
        // Activar servicio de bus
        await _httpClient.post('/api/bus/assign', {
          'estudiante_id': studentId,
          'monto_mensual': 200.0, // Monto por defecto
        });
      } else if (!_hasBusService && hadBus) {
        // Desactivar servicio de bus
        await _httpClient.put('/api/bus/deactivate/$studentId', {});
      }
    } catch (e) {
      print('Error updating bus service: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
        _birthDateController.text = _formatDate(date);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de nacimiento')),
      );
      return;
    }

    if (_selectedGradeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un grado')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final student = Student.create(
        codigo: _codigoController.text.trim(),
        dpi: DPI.fromString(_dpiController.text.trim()),
        name: _nameController.text.trim(),
        birthDate: _selectedBirthDate!,
        gender: _selectedGender != null
            ? Gender(GenderValue.values.firstWhere(
                (e) => e.toString().split('.').last == _selectedGender))
            : null,
        gradeId: _selectedGradeId!,
        sectionId:
            1, // Valor por defecto - la sección se maneja a nivel de grado
      );

      int studentId;

      if (widget.student != null) {
        // Actualizar estudiante existente
        final updatedStudent = Student(
          id: widget.student!.id,
          codigo: student.codigo,
          dpi: student.dpi,
          name: student.name,
          birthDate: student.birthDate,
          gender: student.gender,
          phone: null,
          email: null,
          address: null,
          avatarUrl: null,
          gradeId: student.gradeId,
          sectionId:
              1, // Valor por defecto - la sección se maneja a nivel de grado
          enrollmentDate: widget.student!.enrollmentDate,
          status: widget.student!.status,
          createdAt: widget.student!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _studentRepository.update(updatedStudent);
        studentId = widget.student!.id;

        // Gestionar servicio de bus
        await _updateBusService(studentId);
      } else {
        // Crear nuevo estudiante
        final savedStudent = await _studentRepository.save(student);
        studentId = savedStudent.id;

        // Si el toggle está activo, asignar servicio de bus
        if (_hasBusService) {
          await _httpClient.post('/api/bus/assign', {
            'estudiante_id': studentId,
            'monto_mensual': 200.0, // Monto por defecto
          });
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.student != null
                ? 'Estudiante actualizado exitosamente'
                : 'Estudiante creado exitosamente'),
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
    _codigoController.dispose();
    _dpiController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;

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
          isEdit ? 'Editar Estudiante' : 'Nuevo Estudiante',
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
              label: 'Código del Estudiante',
              placeholder: 'Ej: C716KYD',
              controller: _codigoController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El código es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'DPI / CUI',
              placeholder: 'Ej: 1234567890101',
              controller: _dpiController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El DPI es requerido';
                }
                if (value.trim().length != 13) {
                  return 'El DPI debe tener 13 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Nombre Completo',
              placeholder: 'Ej: Juan Carlos Pérez López',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _selectBirthDate,
              child: AbsorbPointer(
                child: InputField(
                  label: 'Fecha de Nacimiento',
                  placeholder: 'Selecciona una fecha',
                  controller: _birthDateController,
                  icon: Icons.calendar_today,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La fecha de nacimiento es requerida';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildGenderSelector(),
            const SizedBox(height: 24),

            // Información Académica
            _buildSectionTitle('Información Académica'),
            const SizedBox(height: 16),

            _buildGradeSelector(),
            const SizedBox(height: 24),

            // Toggle de servicio de bus
            _buildBusServiceToggle(),
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
                    label: isEdit ? 'Actualizar' : 'Crear Estudiante',
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

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Género',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption('Masculino', 'masculino'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption('Femenino', 'femenino'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, String value) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black26,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGradeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grado',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedGradeId,
              isExpanded: true,
              hint: const Text('Selecciona un grado'),
              items: _grades.map((grade) {
                return DropdownMenuItem<int>(
                  value: grade.id,
                  child: Text(grade.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGradeId = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusServiceToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E7EA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  _hasBusService ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: _hasBusService ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Servicio de Bus',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _hasBusService ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 12,
                    color: _hasBusService ? Colors.green : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _hasBusService,
            onChanged: (value) {
              setState(() {
                _hasBusService = value;
              });
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
