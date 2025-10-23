// Implementación del GradeRepository usando SQLite
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database_helper.dart';

class GradeRepositoryImpl implements GradeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Grade?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'grados',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return _mapToGrade(result.first);
  }

  @override
  Future<List<Grade>> findAll() async {
    final db = await _dbHelper.database;
    final result = await db.query('grados');
    return result.map((row) => _mapToGrade(row)).toList();
  }

  @override
  Future<Grade> save(Grade entity) async {
    final db = await _dbHelper.database;

    if (entity.id == 0) {
      final id = await db.insert('grados', _mapFromGrade(entity));
      return entity.copyWith(id: id);
    } else {
      await db.update(
        'grados',
        _mapFromGrade(entity),
        where: 'id = ?',
        whereArgs: [entity.id],
      );
      return entity;
    }
  }

  @override
  Future<Grade> update(Grade entity) async {
    final db = await _dbHelper.database;
    await db.update(
      'grados',
      _mapFromGrade(entity),
      where: 'id = ?',
      whereArgs: [entity.id],
    );
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('grados', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('grados', 'id = ?', [id]);
  }

  @override
  Future<List<Grade>> findByEducationalLevel(int educationalLevelId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'grados',
      where: 'nivel_educativo_id = ?',
      whereArgs: [educationalLevelId],
    );
    return result.map((row) => _mapToGrade(row)).toList();
  }

  @override
  Future<List<Grade>> findByAcademicYear(String academicYear) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'grados',
      where: 'ano_academico = ?',
      whereArgs: [academicYear],
    );
    return result.map((row) => _mapToGrade(row)).toList();
  }

  @override
  Future<Grade?> findByNameAndYear(String name, String academicYear) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'grados',
      where: 'nombre = ? AND ano_academico = ?',
      whereArgs: [name, academicYear],
    );

    if (result.isEmpty) return null;
    return _mapToGrade(result.first);
  }

  @override
  Future<List<Grade>> findActiveGrades() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'grados',
      where: 'activo = ?',
      whereArgs: [1],
    );
    return result.map((row) => _mapToGrade(row)).toList();
  }

  // Método helper para convertir de Map a Grade
  Grade _mapToGrade(Map<String, dynamic> row) {
    return Grade(
      id: row['id'],
      name: row['nombre'],
      educationalLevelId: row['nivel_educativo_id'],
      ageRange: row['rango_edad'],
      academicYear: row['ano_academico'],
      active: row['activo'] == 1,
      createdAt: DateTime.parse(row['fecha_creacion']),
      updatedAt: DateTime.parse(row['fecha_actualizacion']),
    );
  }

  // Método helper para convertir de Grade a Map
  Map<String, dynamic> _mapFromGrade(Grade grade) {
    return {
      'id': grade.id,
      'nombre': grade.name,
      'nivel_educativo_id': grade.educationalLevelId,
      'rango_edad': grade.ageRange,
      'ano_academico': grade.academicYear,
      'activo': grade.active ? 1 : 0,
      'fecha_creacion': grade.createdAt.toIso8601String(),
      'fecha_actualizacion': grade.updatedAt.toIso8601String(),
    };
  }
}

// Extensión para crear una copia de Grade con ID actualizado
extension GradeCopyWith on Grade {
  Grade copyWith({int? id}) {
    return Grade(
      id: id ?? this.id,
      name: name,
      educationalLevelId: educationalLevelId,
      ageRange: ageRange,
      academicYear: academicYear,
      active: active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
