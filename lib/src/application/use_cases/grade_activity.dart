
import '../../domain/repositories/activity_repository.dart';
import '../../domain/entities/activity.dart';

class GradeActivity {
  final ActivityRepository repository;
  GradeActivity(this.repository);

  Future<Activity> call({
    required int activityId,
    required int studentsGraded,
    required String status,
    double? averageGrade,
    List<ActivityGroup>? groups,
  }) {
    return repository.gradeActivity(
      activityId: activityId,
      studentsGraded: studentsGraded,
      status: status,
      averageGrade: averageGrade,
      groups: groups,
    );
  }
}
