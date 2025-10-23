// Caso de uso para crear estudiantes
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';
import 'base_use_case.dart';

class CreateStudentUseCase
    extends UseCase<CreateStudentInput, Result<Student>> {
  final StudentRepository studentRepository;
  final GradeRepository gradeRepository;
  final SectionRepository sectionRepository;

  CreateStudentUseCase(
    this.studentRepository,
    this.gradeRepository,
    this.sectionRepository,
  );

  @override
  Future<Result<Student>> execute(CreateStudentInput input) async {
    try {
      // Validar que el DPI no exista
      final dpiExists = await studentRepository.existsByDPI(input.dpi);
      if (dpiExists) {
        return const Result.failure('Ya existe un estudiante con este DPI');
      }

      // Verificar que el grado existe
      final grade = await gradeRepository.findById(input.gradeId);
      if (grade == null) {
        return const Result.failure('Grado no encontrado');
      }

      // Verificar que la sección existe y pertenece al grado
      final section = await sectionRepository.findById(input.sectionId);
      if (section == null || section.gradeId != input.gradeId) {
        return const Result.failure(
            'Sección no válida para el grado seleccionado');
      }

      // Crear el estudiante
      final student = Student.create(
        dpi: input.dpi,
        name: input.name,
        birthDate: input.birthDate,
        gender: input.gender,
        address: input.address,
        phone: input.phone,
        email: input.email,
        avatarUrl: input.avatarUrl,
        gradeId: input.gradeId,
        sectionId: input.sectionId,
      );

      // Guardar el estudiante
      final savedStudent = await studentRepository.save(student);

      return Result.success(savedStudent);
    } catch (e) {
      return Result.failure('Error al crear estudiante: $e');
    }
  }
}

// Input para crear estudiante
class CreateStudentInput {
  final DPI dpi;
  final String name;
  final DateTime birthDate;
  final Gender? gender;
  final Address? address;
  final Phone? phone;
  final Email? email;
  final String? avatarUrl;
  final int gradeId;
  final int sectionId;

  const CreateStudentInput({
    required this.dpi,
    required this.name,
    required this.birthDate,
    this.gender,
    this.address,
    this.phone,
    this.email,
    this.avatarUrl,
    required this.gradeId,
    required this.sectionId,
  });
}
