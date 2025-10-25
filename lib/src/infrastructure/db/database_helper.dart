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
    await db.execute(postgres.Sql.named(query), parameters: data);

    // Obtener el ID del último registro insertado
    try {
      final result = await db.execute('SELECT LASTVAL()');
      return result.isNotEmpty && result.first.isNotEmpty ? result.first.first as int : 0;
    } catch (e) {
      print('Error obteniendo LASTVAL: $e');
      return 0;
    }
  }

  // Método genérico para actualizar
  Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;

    // Crear parámetros para los datos
    final parameters = Map<String, dynamic>.from(data);
    for (int i = 0; i < whereArgs.length; i++) {
      parameters['where_$i'] = whereArgs[i];
    }

    // Crear consulta con placeholders numéricos para evitar problemas
    final setClause = data.keys.map((k) => '$k = @${data.keys.toList().indexOf(k)}').join(', ');
    final query = 'UPDATE $table SET $setClause WHERE $whereClause';

    try {
      final result = await db.execute(postgres.Sql.named(query), parameters: parameters);
      return result.affectedRows;
    } catch (e) {
      print('Error en update: $e');
      return 0;
    }
  }

  // Método genérico para eliminar
  Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;

    // Convertir whereArgs a mapa de parámetros
    final parameters = <String, dynamic>{};
    for (int i = 0; i < whereArgs.length; i++) {
      parameters['param_$i'] = whereArgs[i];
    }

    final result = await db.execute(
      postgres.Sql.named('DELETE FROM $table WHERE $whereClause'),
      parameters: parameters
    );
    return result.affectedRows;
  }

  // Método genérico para consultar por ID
  Future<Map<String, dynamic>?> findById(String table, int id) async {
    final db = await database;
    try {
      final result = await db.execute(
        postgres.Sql.named('SELECT * FROM $table WHERE id = @id'),
        parameters: {'id': id}
      );
      return result.isNotEmpty ? _rowToMap(result.first) : null;
    } catch (e) {
      print('Error en findById: $e');
      return null;
    }
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
    String queryStr = 'SELECT * FROM $table';

    if (where != null && where.isNotEmpty) {
      queryStr += ' WHERE $where';
    }

    if (whereArgs != null && whereArgs.isNotEmpty) {
      // Si whereArgs es una lista, convertir a mapa de parámetros
      final parameters = <String, dynamic>{};
      for (int i = 0; i < whereArgs.length; i++) {
        parameters['param_$i'] = whereArgs[i];
      }
      final result = await db.execute(postgres.Sql.named(queryStr), parameters: parameters);
      return result.map((row) => _rowToMap(row)).toList();
    } else {
      final result = await db.execute(queryStr);
      return result.map((row) => _rowToMap(row)).toList();
    }
  }

  // Verificar si existe un registro
  Future<bool> exists(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;

    // Convertir whereArgs a mapa de parámetros
    final parameters = <String, dynamic>{};
    for (int i = 0; i < whereArgs.length; i++) {
      parameters['param_$i'] = whereArgs[i];
    }

    try {
      final result = await db.execute(
        postgres.Sql.named('SELECT EXISTS(SELECT 1 FROM $table WHERE $whereClause)'),
        parameters: parameters
      );
      return result.isNotEmpty && result.first.isNotEmpty ? result.first.first as bool : false;
    } catch (e) {
      print('Error en exists: $e');
      return false;
    }
  }

  // Contar registros
  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    String queryStr = 'SELECT COUNT(*) as count FROM $table';

    if (where != null && where.isNotEmpty) {
      queryStr += ' WHERE $where';
    }

    try {
      if (whereArgs != null && whereArgs.isNotEmpty) {
        // Convertir whereArgs a mapa de parámetros
        final parameters = <String, dynamic>{};
        for (int i = 0; i < whereArgs.length; i++) {
          parameters['param_$i'] = whereArgs[i];
        }
        final result = await db.execute(postgres.Sql.named(queryStr), parameters: parameters);
        return result.isNotEmpty && result.first.isNotEmpty ? result.first.first as int : 0;
      } else {
        final result = await db.execute(queryStr);
        return result.isNotEmpty && result.first.isNotEmpty ? result.first.first as int : 0;
      }
    } catch (e) {
      print('Error en count: $e');
      return 0;
    }
  }

  // Método específico para autenticación de usuarios
  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    final db = await database;
    try {
      final result = await db.execute(
        postgres.Sql.named('SELECT * FROM usuarios WHERE username = @username AND password = @password AND estado = @estado'),
        parameters: {
          'username': username,
          'password': password,
          'estado': 'activo'
        }
      );
      return result.isNotEmpty ? _rowToMap(result.first) : null;
    } catch (e) {
      print('Error en autenticación: $e');
      rethrow;
    }
  }

  // Método específico para obtener usuario por username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    try {
      final result = await db.execute(
        postgres.Sql.named('SELECT * FROM usuarios WHERE username = @username'),
        parameters: {'username': username}
      );
      return result.isNotEmpty ? _rowToMap(result.first) : null;
    } catch (e) {
      print('Error obteniendo usuario por username: $e');
      rethrow;
    }
  }

  // Helper method to convert result row to Map
  Map<String, dynamic> _rowToMap(dynamic row) {
    try {
      // Handle postgres result row structure
      if (row is Map) {
        return Map<String, dynamic>.from(row);
      }

      // Handle postgres ResultRow structure (most common case)
      if (row is postgres.ResultRow) {
        final map = <String, dynamic>{};
        for (int i = 0; i < row.length; i++) {
          // Usar nombres de columna estándar para evitar problemas
          // Esto es más confiable que tratar de obtener nombres dinámicos
          final standardColumns = [
            'id', 'nombre', 'username', 'password', 'telefono', 'rol_id', 'estado',
            'url_avatar', 'ultimo_acceso', 'fecha_creacion', 'fecha_actualizacion'
          ];

          if (i < standardColumns.length) {
            map[standardColumns[i]] = row[i];
          } else {
            map['col_$i'] = row[i];
          }
        }
        return map;
      }

      // If row is a List or other structure, convert accordingly
      if (row is List) {
        final map = <String, dynamic>{};
        for (int i = 0; i < row.length; i++) {
          map['col_$i'] = row[i];
        }
        return map;
      }

      return {};
    } catch (e) {
      print('Error en _rowToMap: $e');
      return {};
    }
  }
  Future<List<Map<String, dynamic>>> getStudentsWithDetails() async {
    final db = await database;
    try {
      final result = await db.execute(postgres.Sql.named('''
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
        WHERE e.estado = @estado
        ORDER BY e.nombre
      '''), parameters: {'estado': 'activo'});
      return result.map((row) => _rowToMap(row)).toList();
    } catch (e) {
      print('Error en getStudentsWithDetails: $e');
      // Fallback: consulta simplificada
      try {
        final result = await db.execute(
          postgres.Sql.named('SELECT * FROM estudiantes WHERE estado = @estado ORDER BY nombre'),
          parameters: {'estado': 'activo'}
        );
        return result.map((row) => _rowToMap(row)).toList();
      } catch (e2) {
        print('Error en fallback de getStudentsWithDetails: $e2');
        rethrow;
      }
    }
  }
}

