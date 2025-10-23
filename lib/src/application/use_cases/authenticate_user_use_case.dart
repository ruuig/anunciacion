// Caso de uso para autenticar usuarios
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';
import 'base_use_case.dart';

class AuthenticateUserUseCase
    extends UseCase<AuthenticateUserInput, Result<User>> {
  final UserRepository userRepository;

  AuthenticateUserUseCase(this.userRepository);

  @override
  Future<Result<User>> execute(AuthenticateUserInput input) async {
    try {
      // Buscar usuario por username
      final user = await userRepository.findByUsername(input.username);

      if (user == null) {
        return const Result.failure('Usuario no encontrado');
      }

      // Verificar estado del usuario
      if (user.status.value != UserStatusValue.activo) {
        return const Result.failure('Usuario inactivo');
      }

      // Verificar contraseña
      if (!user.verifyPassword(input.password)) {
        return const Result.failure('Contraseña incorrecta');
      }

      // Actualizar último acceso
      await userRepository.updateLastAccess(user.id);

      return Result.success(user);
    } catch (e) {
      return Result.failure('Error al autenticar: $e');
    }
  }
}

// Input para autenticación
class AuthenticateUserInput {
  final String username;
  final String password;

  const AuthenticateUserInput({
    required this.username,
    required this.password,
  });
}
