import '../entities/activity.dart';

abstract class ActivityRepository {
  Future<List<Activity>> getActivities();
  Future<Activity?> getActivityById(int id);
  Future<Activity> createActivity(Activity activity);
  Future<Activity> updateActivity(Activity activity);
  Future<void> deleteActivity(int id);
  Future<Activity> gradeActivity({
    required int activityId,
    required int studentsGraded,
    required String status,
    double? averageGrade,
    List<ActivityGroup>? groups,
  });
}
