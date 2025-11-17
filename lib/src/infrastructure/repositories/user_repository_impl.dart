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
      await _dbHelper.update(
          'usuarios', _mapFromUser(entity), 'id = @param_0', [entity.id]);
      return entity;
    }
  }

  @override
  Future<User> update(User entity) async {
    await _dbHelper
        .update('usuarios', _mapFromUser(entity), 'id = @param_0', [entity.id]);
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.delete('usuarios', 'id = @param_0', [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('usuarios', 'id = @param_0', [id]);
  }

  @override
  Future<User?> findByUsername(String username) async {
    final result = await _dbHelper.query(
      'usuarios',
      where: 'username = @param_0',
      whereArgs: [username],
    );

    if (result.isEmpty) return null;
    return _mapToUser(result.first);
  }

  @override
  Future<User?> findByEmail(String email) async {
    final result = await _dbHelper.query(
      'usuarios',
      where: 'email = @param_0',
      whereArgs: [email],
    );

    if (result.isEmpty) return null;
    return _mapToUser(result.first);
  }

  @override
  Future<List<User>> findByRole(int roleId) async {
    final result = await _dbHelper.query(
      'usuarios',
      where: 'rol_id = @param_0',
      whereArgs: [roleId],
    );

    return result.map((row) => _mapToUser(row)).toList();
  }

  @override
  Future<List<User>> findActiveUsers() async {
    final result = await _dbHelper.query(
      'usuarios',
      where: 'estado = @param_0',
      whereArgs: ['activo'],
    );

    return result.map((row) => _mapToUser(row)).toList();
  }

  @override
  Future<bool> existsByUsername(String username) async {
    return await _dbHelper
        .exists('usuarios', 'username = @param_0', [username]);
  }

  @override
  Future<User?> authenticate(String username, String password) async {
    final result = await _dbHelper.authenticateUser(username, password);
    if (result == null) return null;
    return _mapToUser(result);
  }

  @override
  Future<void> updateLastAccess(int userId) async {
    await _dbHelper.update(
      'usuarios',
      {'ultimo_acceso': DateTime.now().toIso8601String()},
      'id = @param_0',
      [userId],
    );
  }

  // Método helper para convertir de Map a User
  User _mapToUser(Map<String, dynamic> row) {
    return User(
      id: row['id'] ?? 0, // Default to 0 if null
      name: row['nombre'] ?? '', // Default to empty string if null
      username: row['username'] ?? '', // Default to empty string if null
      passwordHash: Password.fromPlainText(
          row['password'] as String), // Convertir texto plano a hash
      phone: row['telefono'] != null ? Phone(row['telefono']) : null,
      roleId: row['rol_id'] ?? 1, // Default to role 1 if null
      status: UserStatus.fromString(
          row['estado'] ?? 'activo'), // Default to 'activo' if null
      avatarUrl: row['url_avatar'],
      lastAccess: _parseDateTime(row['ultimo_acceso']),
      createdAt: _parseDateTime(row['fecha_creacion']) ?? DateTime.now(),
      updatedAt: _parseDateTime(row['fecha_actualizacion']) ?? DateTime.now(),
    );
  }

  // Helper method to parse DateTime from database (handles both DateTime objects and strings)
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value; // Already a DateTime object
    }

    if (value is String) {
      try {
        return DateTime.parse(value); // Parse string to DateTime
      } catch (e) {
        print('Error parsing date string: $value - $e');
        return null;
      }
    }

    print('Unknown date type: ${value.runtimeType}');
    return null;
  }

  // Método helper para convertir de User a Map
  Map<String, dynamic> _mapFromUser(User user) {
    return {
      'id': user.id,
      'nombre': user.name,
      'username': user.username,
      'password': user.passwordHash
          .hash, // Guardar el hash como texto (la BD espera texto plano)
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
