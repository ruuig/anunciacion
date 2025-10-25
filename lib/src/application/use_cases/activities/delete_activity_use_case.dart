import 'package:anunciacion/src/domain/repositories/activity_repository.dart';

class DeleteActivityUseCase {
  final ActivityRepository repository;

  DeleteActivityUseCase(this.repository);

  Future<void> call(int id) {
    return repository.deleteActivity(id);
  }
}
