import 'package:anunciacion/src/domain/entities/activity.dart';
import 'package:anunciacion/src/domain/repositories/activity_repository.dart';

class CreateActivityUseCase {
  final ActivityRepository repository;

  CreateActivityUseCase(this.repository);

  Future<Activity> call(Activity activity) {
    return repository.createActivity(activity);
  }
}
