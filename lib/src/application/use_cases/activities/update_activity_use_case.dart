import 'package:anunciacion/src/domain/entities/activity.dart';
import 'package:anunciacion/src/domain/repositories/activity_repository.dart';

class UpdateActivityUseCase {
  final ActivityRepository repository;

  UpdateActivityUseCase(this.repository);

  Future<Activity> call(Activity activity) {
    return repository.updateActivity(activity);
  }
}
