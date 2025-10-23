// Interfaz para UserRepository
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';

abstract class UserRepository implements BaseRepository<User, int> {
  // Métodos específicos del repositorio de usuarios
  Future<User?> findByUsername(String username);
  Future<User?> findByEmail(String email);
  Future<List<User>> findByRole(int roleId);
  Future<List<User>> findActiveUsers();
  Future<bool> existsByUsername(String username);
  Future<void> updateLastAccess(int userId);
}
