import 'package:flutter/material.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/services/grade_management_service.dart';
import 'package:anunciacion/src/infrastructure/repositories/http_grade_repository.dart';
import 'package:anunciacion/src/infrastructure/repositories/http_section_repository.dart';
import '../../widgets/widgets.dart';
import '../../widgets/input_field.dart';

class CreateEditSectionDialog extends StatefulWidget {
  final Section? section;
  final int gradeId;
  final String gradeName;

  const CreateEditSectionDialog({
    super.key,
    this.section,
    required this.gradeId,
    required this.gradeName,
  });

  @override
  State<CreateEditSectionDialog> createState() => _CreateEditSectionDialogState();
}

class _CreateEditSectionDialogState extends State<CreateEditSectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  
  bool _isLoading = false;

  final _gradeService = GradeManagementService(
    HttpGradeRepository(),
    HttpSectionRepository(),
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.section?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.section?.capacity?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final capacity = _capacityController.text.trim().isEmpty
          ? null
          : int.tryParse(_capacityController.text.trim());

      if (widget.section == null) {
        // Crear nueva sección
        await _gradeService.createSection(
          gradeId: widget.gradeId,
          name: _nameController.text.trim(),
          capacity: capacity,
        );
      } else {
        // Actualizar sección existente
        final updatedSection = Section(
          id: widget.section!.id,
          gradeId: widget.gradeId,
          name: _nameController.text.trim(),
          capacity: capacity,
          studentCount: widget.section!.studentCount,
          active: widget.section!.active,
          createdAt: widget.section!.createdAt,
        );
        await _gradeService.updateSection(updatedSection);
      }

      if (mounted) {
        Navigator.pop(context, true);
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
  Widget build(BuildContext context) {
    final isEdit = widget.section != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Editar Sección' : 'Nueva Sección',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grado: ${widget.gradeName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
              
              // Nombre de la sección
              InputField(
                label: 'Nombre de la Sección',
                placeholder: 'Ej: A, B, C, etc.',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Capacidad (opcional)
              InputField(
                label: 'Capacidad (Opcional)',
                placeholder: 'Número máximo de estudiantes',
                controller: _capacityController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final capacity = int.tryParse(value.trim());
                    if (capacity == null || capacity <= 0) {
                      return 'Debe ser un número mayor a 0';
                    }
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
