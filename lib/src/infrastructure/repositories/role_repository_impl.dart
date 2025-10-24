// Implementación del RoleRepository usando PostgreSQL
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database_helper.dart';

class RoleRepositoryImpl implements RoleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Role?> findById(int id) async {
    final result = await _dbHelper.findById('roles', id);
    if (result == null) return null;
    return _mapToRole(result);
  }

  @override
  Future<List<Role>> findAll() async {
    final results = await _dbHelper.findAll('roles');
    return results.map((row) => _mapToRole(row)).toList();
  }

  @override
  Future<Role> save(Role entity) async {
    if (entity.id == 0) {
      // Insertar nuevo rol
      final id = await _dbHelper.insert('roles', _mapFromRole(entity));
      return entity.copyWith(id: id);
    } else {
      // Actualizar rol existente
      await _dbHelper.update(
        'roles',
        _mapFromRole(entity),
        'id = @id',
        [entity.id],
      );
      return entity;
    }
  }

  @override
  Future<Role> update(Role entity) async {
    await _dbHelper.update(
      'roles',
      _mapFromRole(entity),
      'id = @id',
      [entity.id],
    );
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.delete('roles', 'id = @id', [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('roles', 'id = @id', [id]);
  }

  @override
  Future<Role?> findByName(String name) async {
    final results = await _dbHelper.query(
      'roles',
      where: 'nombre = @nombre',
      whereArgs: [name],
    );

    if (results.isEmpty) return null;
    return _mapToRole(results.first);
  }

  @override
  Future<List<Role>> findByLevel(int level) async {
    final results = await _dbHelper.query(
      'roles',
      where: 'nivel = @nivel',
      whereArgs: [level],
    );

    return results.map((row) => _mapToRole(row)).toList();
  }

  @override
  Future<bool> existsByName(String name) async {
    return await _dbHelper.exists('roles', 'nombre = @nombre', [name]);
  }

  // Método helper para convertir de Map a Role
  Role _mapToRole(Map<String, dynamic> row) {
    return Role(
      id: row['id'],
      name: row['nombre'],
      description: row['descripcion'] ?? '',
      level: row['nivel'],
      createdAt: DateTime.parse(row['fecha_creacion']),
    );
  }

  // Método helper para convertir de Role a Map
  Map<String, dynamic> _mapFromRole(Role role) {
    return {
      'id': role.id,
      'nombre': role.name,
      'descripcion': role.description,
      'nivel': role.level,
      'fecha_creacion': role.createdAt.toIso8601String(),
    };
  }
}

// Extensión para crear una copia de Role con ID actualizado
extension RoleCopyWith on Role {
  Role copyWith({int? id}) {
    return Role(
      id: id ?? this.id,
      name: name,
      description: description,
      level: level,
      createdAt: createdAt,
    );
  }
}
