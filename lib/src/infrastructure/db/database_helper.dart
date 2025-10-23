// Helper para operaciones comunes de base de datos
import 'package:sqflite/sqflite.dart';
import 'database_config.dart';

class DatabaseHelper {
  final DatabaseConfig _config = DatabaseConfig.instance;

  Future<Database> get database => _config.database;

  // Método genérico para insertar
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  // Método genérico para actualizar
  Future<int> update(String table, Map<String, dynamic> data,
      String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, data,
        where: whereClause, whereArgs: whereArgs);
  }

  // Método genérico para eliminar
  Future<int> delete(
      String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: whereClause, whereArgs: whereArgs);
  }

  // Método genérico para consultar por ID
  Future<Map<String, dynamic>?> findById(String table, int id) async {
    final db = await database;
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  // Método genérico para consultar todos los registros
  Future<List<Map<String, dynamic>>> findAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  // Método genérico para consultar con condiciones
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  // Verificar si existe un registro
  Future<bool> exists(
      String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    final result =
        await db.query(table, where: whereClause, whereArgs: whereArgs);
    return result.isNotEmpty;
  }

  // Contar registros
  Future<int> count(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table ${where != null ? 'WHERE $where' : ''}',
      whereArgs,
    );
    return result.first['count'] as int;
  }
}
