import 'package:anunciacion/src/domain/repositories/student_grade_repository.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';

class GetGradesUseCase {
  final StudentGradeRepository repo;
  GetGradesUseCase(this.repo);

  /// Obtiene notas por grupo (grado/sección), materia y período.
  /// Ajusta los tipos/IDs según tu dominio.
  Future<List<GradeEntry>> call({
    required int groupId,
    required int subjectId,
    required int periodId,
  }) {
    return repo.getGrades(
        groupId: groupId, subjectId: subjectId, periodId: periodId);
  }
}
