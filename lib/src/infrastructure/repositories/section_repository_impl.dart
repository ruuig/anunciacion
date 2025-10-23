// Implementación del SectionRepository usando SQLite
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database_helper.dart';

class SectionRepositoryImpl implements SectionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Section?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'secciones',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return _mapToSection(result.first);
  }

  @override
  Future<List<Section>> findAll() async {
    final db = await _dbHelper.database;
    final result = await db.query('secciones');
    return result.map((row) => _mapToSection(row)).toList();
  }

  @override
  Future<Section> save(Section entity) async {
    final db = await _dbHelper.database;

    if (entity.id == 0) {
      final id = await db.insert('secciones', _mapFromSection(entity));
      return entity.copyWith(id: id);
    } else {
      await db.update(
        'secciones',
        _mapFromSection(entity),
        where: 'id = ?',
        whereArgs: [entity.id],
      );
      return entity;
    }
  }

  @override
  Future<Section> update(Section entity) async {
    final db = await _dbHelper.database;
    await db.update(
      'secciones',
      _mapFromSection(entity),
      where: 'id = ?',
      whereArgs: [entity.id],
    );
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('secciones', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('secciones', 'id = ?', [id]);
  }

  @override
  Future<List<Section>> findByGrade(int gradeId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'secciones',
      where: 'grado_id = ?',
      whereArgs: [gradeId],
    );
    return result.map((row) => _mapToSection(row)).toList();
  }

  @override
  Future<Section?> findByGradeAndName(int gradeId, String name) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'secciones',
      where: 'grado_id = ? AND nombre = ?',
      whereArgs: [gradeId, name],
    );

    if (result.isEmpty) return null;
    return _mapToSection(result.first);
  }

  @override
  Future<List<Section>> findActiveSections() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'secciones',
      where: 'activo = ?',
      whereArgs: [1],
    );
    return result.map((row) => _mapToSection(row)).toList();
  }

  // Método helper para convertir de Map a Section
  Section _mapToSection(Map<String, dynamic> row) {
    return Section(
      id: row['id'],
      gradeId: row['grado_id'],
      name: row['nombre'],
      capacity: row['capacidad'],
      studentCount: row['cantidad_estudiantes'],
      active: row['activo'] == 1,
      createdAt: DateTime.parse(row['fecha_creacion']),
    );
  }

  // Método helper para convertir de Section a Map
  Map<String, dynamic> _mapFromSection(Section section) {
    return {
      'id': section.id,
      'grado_id': section.gradeId,
      'nombre': section.name,
      'capacidad': section.capacity,
      'cantidad_estudiantes': section.studentCount,
      'activo': section.active ? 1 : 0,
      'fecha_creacion': section.createdAt.toIso8601String(),
    };
  }
}

// Extensión para crear una copia de Section con ID actualizado
extension SectionCopyWith on Section {
  Section copyWith({int? id}) {
    return Section(
      id: id ?? this.id,
      gradeId: gradeId,
      name: name,
      capacity: capacity,
      studentCount: studentCount,
      active: active,
      createdAt: createdAt,
    );
  }
}
