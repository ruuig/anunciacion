import 'package:anunciacion/src/domain/entities/activity_grade.dart';
import 'package:anunciacion/src/domain/repositories/activity_repository.dart';

class GetActivityGradesUseCase {
  final ActivityRepository repository;

  GetActivityGradesUseCase(this.repository);

  Future<List<ActivityGrade>> call(int activityId) {
    return repository.getActivityGrades(activityId);
  }
}
