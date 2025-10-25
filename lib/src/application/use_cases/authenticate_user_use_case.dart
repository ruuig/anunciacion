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
      print('🔐 Iniciando autenticación para: ${input.username}');

      // Buscar usuario por username
      print('📝 Paso 1: Buscando usuario...');
      final user = await userRepository.findByUsername(input.username);

      if (user == null) {
        print('❌ Usuario no encontrado');
        return const Result.failure('Usuario no encontrado');
      }
      print('✅ Usuario encontrado: ${user.id} - ${user.username}');

      // Verificar estado del usuario
      print('📝 Paso 2: Verificando estado...');
      print('   Estado actual: ${user.status.value}');
      if (user.status.value != UserStatusValue.activo) {
        print('❌ Usuario inactivo');
        return const Result.failure('Usuario inactivo');
      }
      print('✅ Usuario activo');

      // Verificar contraseña
      print('📝 Paso 3: Verificando contraseña...');
      final passwordValid = user.verifyPassword(input.password);
      print('   Resultado: $passwordValid');
      if (!passwordValid) {
        print('❌ Contraseña incorrecta');
        return const Result.failure('Contraseña incorrecta');
      }
      print('✅ Contraseña correcta');

      // Actualizar último acceso
      print('📝 Paso 4: Actualizando último acceso...');
      await userRepository.updateLastAccess(user.id);
      print('✅ Último acceso actualizado');

      print('🎉 Autenticación exitosa');
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
