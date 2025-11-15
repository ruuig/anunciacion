import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/value_objects/value_objects.dart';

class UserManagementService {
  final UserRepository _userRepository;

  UserManagementService(this._userRepository);

  Future<List<User>> getUsers() async {
    try {
      return await _userRepository.findAll();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final roleId = int.tryParse(role) ?? 1;
      final user = User(
        id: 0, // El backend asignará el ID
        name: name,
        username:
            email, // Using email as username since User entity requires username
        passwordHash: Password(password), // Enviar contraseña en texto plano
        roleId: roleId,
        status: const UserStatus(UserStatusValue.activo),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _userRepository.save(user);
      return user;
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _userRepository.update(user);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _userRepository.delete(userId);
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // TODO: Implementar updateUserRole en UserRepository
  // Future<void> updateUserRole(String userId, String newRole) async {
  //   try {
  //     await _userRepository.updateUserRole(userId, newRole);
  //   } catch (e) {
  //     throw Exception('Error al actualizar rol de usuario: $e');
  //   }
  // }
}
