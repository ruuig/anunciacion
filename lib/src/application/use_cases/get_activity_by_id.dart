
import '../../domain/repositories/activity_repository.dart';
import '../../domain/entities/activity.dart';

class GetActivityById {
  final ActivityRepository repository;
  GetActivityById(this.repository);

  Future<Activity?> call(int id) {
    return repository.getActivityById(id);
  }
}
