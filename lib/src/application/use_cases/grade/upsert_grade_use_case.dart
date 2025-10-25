import 'package:anunciacion/src/domain/repositories/student_grade_repository.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';

class UpsertGradeUseCase {
  final StudentGradeRepository repo;
  UpsertGradeUseCase(this.repo);

  /// Inserta/actualiza una nota individual
  Future<void> upsert({
    required int studentId,
    required int subjectId,
    required int periodId,
    required double value,
  }) {
    return repo.upsertGrade(
      studentId: studentId,
      subjectId: subjectId,
      periodId: periodId,
      value: value,
    );
  }

  /// Inserta/actualiza un conjunto de notas
  Future<void> upsertBatch(List<GradeEntry> entries) {
    return repo.upsertGradesBatch(entries);
  }
}
