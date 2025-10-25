import 'package:anunciacion/src/domain/entities/activity_grade.dart';
import 'package:anunciacion/src/domain/repositories/activity_repository.dart';

class GradeActivityUseCase {
  final ActivityRepository repository;

  GradeActivityUseCase(this.repository);

  Future<void> call({
    required int activityId,
    required int gradedBy,
    required List<ActivityGrade> grades,
  }) {
    return repository.saveActivityGrades(
      activityId: activityId,
      gradedBy: gradedBy,
      grades: grades,
    );
  }
}
