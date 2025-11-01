
import '../../domain/repositories/activity_repository.dart';
import '../../domain/entities/activity.dart';

class UpdateActivity {
  final ActivityRepository repository;
  UpdateActivity(this.repository);

  Future<Activity> call(Activity activity) {
    return repository.updateActivity(activity);
  }
}
