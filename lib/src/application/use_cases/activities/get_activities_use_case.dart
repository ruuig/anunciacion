import 'package:anunciacion/src/domain/entities/activity.dart';
import 'package:anunciacion/src/domain/repositories/activity_repository.dart';
import 'package:anunciacion/src/domain/value_objects/activity_filters.dart';

class GetActivitiesUseCase {
  final ActivityRepository repository;

  GetActivitiesUseCase(this.repository);

  Future<List<Activity>> call({ActivityFilters? filters}) {
    return repository.getActivities(filters: filters);
  }
}
