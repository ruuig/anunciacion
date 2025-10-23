// Interfaz para RoleRepository
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';

abstract class RoleRepository implements BaseRepository<Role, int> {
  // Métodos específicos del repositorio de roles
  Future<Role?> findByName(String name);
  Future<List<Role>> findByLevel(int level);
  Future<bool> existsByName(String name);
  Future<Role?> findById(int id);
}
