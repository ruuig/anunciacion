import 'package:flutter/material.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/services/grade_management_service.dart';
import 'package:anunciacion/src/infrastructure/repositories/http_grade_repository.dart';
import 'package:anunciacion/src/infrastructure/repositories/http_section_repository.dart';
import '../../widgets/widgets.dart';
import '../../widgets/input_field.dart';

class CreateEditGradeDialog extends StatefulWidget {
  final Grade? grade;
  final String currentAcademicYear;

  const CreateEditGradeDialog({
    super.key,
    this.grade,
    required this.currentAcademicYear,
  });

  @override
  State<CreateEditGradeDialog> createState() => _CreateEditGradeDialogState();
}

class _CreateEditGradeDialogState extends State<CreateEditGradeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageRangeController;
  late TextEditingController _academicYearController;
  
  int _selectedLevelId = 1; // Preprimaria por defecto
  bool _isLoading = false;

  final _gradeService = GradeManagementService(
    HttpGradeRepository(),
    HttpSectionRepository(),
  );

  final List<Map<String, dynamic>> _educationalLevels = [
    {'id': 1, 'name': 'Preprimaria'},
    {'id': 2, 'name': 'Primaria'},
    {'id': 3, 'name': 'Secundaria'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.grade?.name ?? '');
    _ageRangeController = TextEditingController(text: widget.grade?.ageRange ?? '');
    _academicYearController = TextEditingController(
      text: widget.grade?.academicYear ?? widget.currentAcademicYear,
    );
    
    if (widget.grade != null) {
      _selectedLevelId = widget.grade!.educationalLevelId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageRangeController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.grade == null) {
        // Crear nuevo grado
        await _gradeService.createGrade(
          name: _nameController.text.trim(),
          educationalLevelId: _selectedLevelId,
          ageRange: _ageRangeController.text.trim().isEmpty 
              ? null 
              : _ageRangeController.text.trim(),
          academicYear: _academicYearController.text.trim(),
        );
      } else {
        // La edición de grados no está disponible
        throw Exception('La edición de grados no está disponible');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Error al guardar'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
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
  Widget build(BuildContext context) {
    final isEdit = widget.grade != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Editar Grado' : 'Nuevo Grado',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
              
              // Nombre del grado
              InputField(
                label: 'Nombre del Grado',
                placeholder: 'Ej: 1ro Primaria, Kinder, etc.',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nivel educativo
              SelectField<int>(
                label: 'Nivel Educativo',
                placeholder: 'Selecciona un nivel',
                value: _selectedLevelId,
                items: _educationalLevels.map((e) => e['id'] as int).toList(),
                itemLabel: (id) => _educationalLevels
                    .firstWhere((e) => e['id'] == id)['name'] as String,
                onSelected: (value) => setState(() => _selectedLevelId = value),
              ),
              const SizedBox(height: 16),

              // Rango de edad (opcional)
              InputField(
                label: 'Rango de Edad (Opcional)',
                placeholder: 'Ej: 6-7 años',
                controller: _ageRangeController,
              ),
              const SizedBox(height: 16),

              // Año académico
              InputField(
                label: 'Año Académico',
                placeholder: 'Ej: 2024-2025',
                controller: _academicYearController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El año académico es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BlackButton(
                    label: isEdit ? 'Actualizar' : 'Crear',
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading ? null : Icons.check,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
