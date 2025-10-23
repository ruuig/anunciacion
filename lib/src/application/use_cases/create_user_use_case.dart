// Caso de uso para crear usuarios
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';
import 'base_use_case.dart';

class CreateUserUseCase extends UseCase<CreateUserInput, Result<User>> {
  final UserRepository userRepository;
  final RoleRepository roleRepository;

  CreateUserUseCase(this.userRepository, this.roleRepository);

  @override
  Future<Result<User>> execute(CreateUserInput input) async {
    try {
      // Validar que el username no exista
      final usernameExists =
          await userRepository.existsByUsername(input.username);
      if (usernameExists) {
        return const Result.failure('El nombre de usuario ya existe');
      }

      // Verificar que el rol existe
      final role = await roleRepository.findById(input.roleId);
      if (role == null) {
        return const Result.failure('Rol no encontrado');
      }

      // Crear el usuario
      final user = User.create(
        name: input.name,
        username: input.username,
        plainPassword: input.password,
        phone: input.phone,
        roleId: input.roleId,
        avatarUrl: input.avatarUrl,
      );

      // Guardar el usuario
      final savedUser = await userRepository.save(user);

      return Result.success(savedUser);
    } catch (e) {
      return Result.failure('Error al crear usuario: $e');
    }
  }
}

// Input para crear usuario
class CreateUserInput {
  final String name;
  final String username;
  final String password;
  final Phone? phone;
  final int roleId;
  final String? avatarUrl;

  const CreateUserInput({
    required this.name,
    required this.username,
    required this.password,
    this.phone,
    required this.roleId,
    this.avatarUrl,
  });
}
