
import '../../domain/repositories/activity_repository.dart';
import '../../domain/entities/activity.dart';

class CreateActivity {
  final ActivityRepository repository;
  CreateActivity(this.repository);

  Future<Activity> call(Activity activity) {
    return repository.createActivity(activity);
  }
}
