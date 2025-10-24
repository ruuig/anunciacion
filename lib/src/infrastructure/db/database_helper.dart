import 'package:postgres/postgres.dart' as postgres;
import 'database_config.dart';

class DatabaseHelper {
  final DatabaseConfig _config = DatabaseConfig.instance;

  Future<postgres.Connection> get database => _config.database;

  // Método genérico para insertar
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    final columns = data.keys.join(', ');
    final placeholders = data.keys.map((k) => '@${data.keys.toList().indexOf(k)}').join(', ');

    final query = 'INSERT INTO $table ($columns) VALUES ($placeholders)';
    await db.execute(query, parameters: data);

    // Obtener el ID del último registro insertado
    final result = await db.execute('SELECT LASTVAL()');
    return result.first.first as int;
  }

  // Método genérico para actualizar
  Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    final setClause = data.keys.map((k) => '$k = @${data.keys.toList().indexOf(k)}').join(', ');
    final query = 'UPDATE $table SET $setClause WHERE $whereClause';

    final parameters = Map<String, dynamic>.from(data);
    for (int i = 0; i < whereArgs.length; i++) {
      parameters['where_$i'] = whereArgs[i];
    }

    final result = await db.execute(query, parameters: parameters);
    return result.affectedRows;
  }

  // Método genérico para eliminar
  Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    final query = 'DELETE FROM $table WHERE $whereClause';

    final result = await db.execute(query, parameters: whereArgs.asMap());
    return result.affectedRows;
  }

  // Método genérico para consultar por ID
  Future<Map<String, dynamic>?> findById(String table, int id) async {
    final db = await database;
    final result = await db.execute(
      'SELECT * FROM $table WHERE id = @id',
      parameters: {'id': id}
    );
    return result.isNotEmpty ? _rowToMap(result.first) : null;
  }

  // Método genérico para consultar todos los registros
  Future<List<Map<String, dynamic>>> findAll(String table) async {
    final db = await database;
    final result = await db.execute('SELECT * FROM $table');
    return result.map((row) => _rowToMap(row)).toList();
  }

  // Método genérico para consultar con condiciones
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    String query = 'SELECT * FROM $table';

    if (where != null && where.isNotEmpty) {
      query += ' WHERE $where';
    }

    final result = await db.execute(query, parameters: whereArgs);
    return result.map((row) => _rowToMap(row)).toList();
  }

  // Verificar si existe un registro
  Future<bool> exists(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    final result = await db.execute(
      'SELECT EXISTS(SELECT 1 FROM $table WHERE $whereClause)',
      parameters: whereArgs
    );
    return result.first.first as bool;
  }

  // Contar registros
  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    String query = 'SELECT COUNT(*) as count FROM $table';

    if (where != null && where.isNotEmpty) {
      query += ' WHERE $where';
    }

    final result = await db.execute(query, parameters: whereArgs);
    return result.first.first as int;
  }

  // Método específico para autenticación de usuarios
  Future<Map<String, dynamic>?> authenticateUser(String username, String passwordHash) async {
    final db = await database;
    final result = await db.execute(
      'SELECT * FROM usuarios WHERE username = @username AND password_hash = @password AND estado = @estado',
      parameters: {
        'username': username,
        'password': passwordHash,
        'estado': 'activo'
      }
    );
    return result.isNotEmpty ? _rowToMap(result.first) : null;
  }

  // Método específico para obtener usuario por username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.execute(
      'SELECT * FROM usuarios WHERE username = @username',
      parameters: {'username': username}
    );
    return result.isNotEmpty ? _rowToMap(result.first) : null;
  }

  // Helper method to convert result row to Map
  Map<String, dynamic> _rowToMap(dynamic row) {
    // Handle postgres result row structure
    if (row is Map) {
      return Map<String, dynamic>.from(row);
    }
    // If row is a List or other structure, convert accordingly
    if (row is List) {
      // Convert list of values to map with numeric keys
      final map = <String, dynamic>{};
      for (int i = 0; i < row.length; i++) {
        map[i.toString()] = row[i];
      }
      return map;
    }
    // If row has toMap() method (for backward compatibility)
    if (row != null && row.toMap != null) {
      return row.toMap();
    }
    return {};
  }
  Future<List<Map<String, dynamic>>> getStudentsWithDetails() async {
    final db = await database;
    final result = await db.execute('''
      SELECT
        e.*,
        g.nombre as grado_nombre,
        g.ano_academico,
        n.nombre as nivel_educativo,
        n.color_hex,
        s.nombre as seccion_nombre
      FROM estudiantes e
      JOIN grados g ON e.grado_id = g.id
      JOIN niveles_educativos n ON g.nivel_educativo_id = n.id
      JOIN secciones s ON e.seccion_id = s.id
      WHERE e.estado = 'activo'
      ORDER BY e.nombre
    ''');
    return result.map((row) => _rowToMap(row)).toList();
  }
}

