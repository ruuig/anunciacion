// Implementación del UserRepository usando PostgreSQL
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/value_objects/password.dart';
import '../../domain/value_objects/phone.dart';
import '../../domain/value_objects/user_status.dart';
import '../db/database_helper.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<User?> findById(int id) async {
    final result = await _dbHelper.findById('usuarios', id);
    if (result == null) return null;
    return _mapToUser(result);
  }

  @override
  Future<List<User>> findAll() async {
    final result = await _dbHelper.findAll('usuarios');
    return result.map((row) => _mapToUser(row)).toList();
  }

  @override
  Future<User> save(User entity) async {
    if (entity.id == 0) {
      // Insertar nuevo usuario
      final id = await _dbHelper.insert('usuarios', _mapFromUser(entity));
      return entity.copyWith(id: id);
    } else {
      // Actualizar usuario existente
      await _dbHelper.update('usuarios', _mapFromUser(entity), 'id = @id', [entity.id]);
      return entity;
    }
  }

  @override
  Future<User> update(User entity) async {
    await _dbHelper.update('usuarios', _mapFromUser(entity), 'id = @id', [entity.id]);
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.delete('usuarios', 'id = @id', [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('usuarios', 'id = @id', [id]);
  }

  @override
  Future<User?> findByUsername(String username) async {
    final result = await _dbHelper.query(
      'usuarios',
      where: 'username = @username',
      whereArgs: [username],
    );

    if (result.isEmpty) return null;
    return _mapToUser(result.first);
  }

  @override
  Future<User?> findByEmail(String email) async {
    final result = await _dbHelper.query(
      'usuarios',
      where: 'email = @email',
      whereArgs: [email],
    );

    if (result.isEmpty) return null;
    return _mapToUser(result.first);
  }

  @override
  Future<List<User>> findByRole(int roleId) async {
    final result = await _dbHelper.query(
      'usuarios',
      where: 'rol_id = @role_id',
      whereArgs: [roleId],
    );

    return result.map((row) => _mapToUser(row)).toList();
  }

  @override
  Future<List<User>> findActiveUsers() async {
    final result = await _dbHelper.query(
      'usuarios',
      where: 'estado = @estado',
      whereArgs: ['activo'],
    );

    return result.map((row) => _mapToUser(row)).toList();
  }

  @override
  Future<bool> existsByUsername(String username) async {
    return await _dbHelper.exists('usuarios', 'username = @username', [username]);
  }

  @override
  Future<void> updateLastAccess(int userId) async {
    await _dbHelper.update(
      'usuarios',
      {'ultimo_acceso': DateTime.now().toIso8601String()},
      'id = @id',
      [userId],
    );
  }

  // Método helper para convertir de Map a User
  User _mapToUser(Map<String, dynamic> row) {
    return User(
      id: row['id'],
      name: row['nombre'],
      username: row['username'],
      passwordHash: Password(row['password_hash']),
      phone: row['telefono'] != null ? Phone(row['telefono']) : null,
      roleId: row['rol_id'],
      status: UserStatus.fromString(row['estado']),
      avatarUrl: row['url_avatar'],
      lastAccess: row['ultimo_acceso'] != null
          ? DateTime.parse(row['ultimo_acceso'])
          : null,
      createdAt: DateTime.parse(row['fecha_creacion']),
      updatedAt: DateTime.parse(row['fecha_actualizacion']),
    );
  }

  // Método helper para convertir de User a Map
  Map<String, dynamic> _mapFromUser(User user) {
    return {
      'id': user.id,
      'nombre': user.name,
      'username': user.username,
      'password_hash': user.passwordHash.hash,
      'telefono': user.phone?.value,
      'rol_id': user.roleId,
      'estado': user.status.toString(),
      'url_avatar': user.avatarUrl,
      'ultimo_acceso': user.lastAccess?.toIso8601String(),
      'fecha_creacion': user.createdAt.toIso8601String(),
      'fecha_actualizacion': user.updatedAt.toIso8601String(),
    };
  }
}

// Extensión para crear una copia de User con ID actualizado
extension UserCopyWith on User {
  User copyWith({int? id}) {
    return User(
      id: id ?? this.id,
      name: name,
      username: username,
      passwordHash: passwordHash,
      phone: phone,
      roleId: roleId,
      status: status,
      avatarUrl: avatarUrl,
      lastAccess: lastAccess,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
