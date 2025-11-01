
import '../../domain/repositories/activity_repository.dart';

class DeleteActivity {
  final ActivityRepository repository;
  DeleteActivity(this.repository);

  Future<void> call(int id) {
    return repository.deleteActivity(id);
  }
}
