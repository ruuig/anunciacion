import 'package:anunciacion/src/domain/entities/activity.dart';
import 'package:anunciacion/src/domain/repositories/activity_repository.dart';

class GetActivities {
  final ActivityRepository repository;
  GetActivities(this.repository);

  Future<List<Activity>> call() async {
    return await repository.getActivities();
  }
}
