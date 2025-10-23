// Caso de uso para obtener estudiantes por grado
import 'package:anunciacion/src/domain/value_objects/user_status.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/application/use_cases/base_use_case.dart';

class GetStudentsByGradeUseCase extends UseCase<int, Result<List<Student>>> {
  final StudentRepository studentRepository;

  GetStudentsByGradeUseCase(this.studentRepository);

  @override
  Future<Result<List<Student>>> execute(int gradeId) async {
    try {
      final students = await studentRepository.findByGrade(gradeId);

      // Filtrar solo estudiantes activos
      final activeStudents = students
          .where((student) => student.status.value == UserStatusValue.activo)
          .toList();

      return Result.success(activeStudents);
    } catch (e) {
      return Result.failure('Error al obtener estudiantes: $e');
    }
  }
}
