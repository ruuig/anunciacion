// Caso de uso para autenticar usuarios
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'base_use_case.dart';

class AuthenticateUserUseCase
    extends UseCase<AuthenticateUserInput, Result<User>> {
  final UserRepository userRepository;

  AuthenticateUserUseCase(this.userRepository);

  @override
  Future<Result<User>> execute(AuthenticateUserInput input) async {
    try {
      print('🔐 Iniciando autenticación para: ${input.username}');

      // Usar authenticate() que hace todo en el backend (más rápido)
      print('📝 Autenticando en el backend...');
      final user =
          await userRepository.authenticate(input.username, input.password);

      if (user == null) {
        print('❌ Autenticación fallida');
        return const Result.failure('Usuario o contraseña inválidos');
      }
      print('✅ Autenticación exitosa: ${user.id} - ${user.username}');

      print('🎉 Login completado');
      return Result.success(user);
    } catch (e, stackTrace) {
      print('💥 ERROR en autenticación: $e');
      print('📚 Stack trace: $stackTrace');
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
