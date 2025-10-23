// Caso de uso para obtener perfil de usuario
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'base_use_case.dart';

class GetUserProfileUseCase extends UseCase<int, Result<User>> {
  final UserRepository userRepository;

  GetUserProfileUseCase(this.userRepository);

  @override
  Future<Result<User>> execute(int userId) async {
    try {
      final user = await userRepository.findById(userId);

      if (user == null) {
        return const Result.failure('Usuario no encontrado');
      }

      return Result.success(user);
    } catch (e) {
      return Result.failure('Error al obtener perfil: $e');
    }
  }
}
