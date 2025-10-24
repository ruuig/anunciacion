// Implementación del GradeRepository usando PostgreSQL
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database_helper.dart';

class GradeRepositoryImpl implements GradeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Grade?> findById(int id) async {
    final result = await _dbHelper.findById('grados', id);
    if (result == null) return null;
    return _mapToGrade(result);
  }

  @override
  Future<List<Grade>> findAll() async {
    final result = await _dbHelper.findAll('grados');
    return result.map((row) => _mapToGrade(row)).toList();
  }

  @override
  Future<Grade> save(Grade entity) async {
    if (entity.id == 0) {
      final id = await _dbHelper.insert('grados', _mapFromGrade(entity));
      return entity.copyWith(id: id);
    } else {
      await _dbHelper.update('grados', _mapFromGrade(entity), 'id = @id', [entity.id]);
      return entity;
    }
  }

  @override
  Future<Grade> update(Grade entity) async {
    await _dbHelper.update('grados', _mapFromGrade(entity), 'id = @id', [entity.id]);
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.delete('grados', 'id = @id', [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('grados', 'id = @id', [id]);
  }

  @override
  Future<List<Grade>> findByEducationalLevel(int educationalLevelId) async {
    final result = await _dbHelper.query(
      'grados',
      where: 'nivel_educativo_id = @nivel_educativo_id',
      whereArgs: [educationalLevelId],
    );
    return result.map((row) => _mapToGrade(row)).toList();
  }

  @override
  Future<List<Grade>> findByAcademicYear(String academicYear) async {
    final result = await _dbHelper.query(
      'grados',
      where: 'ano_academico = @ano_academico',
      whereArgs: [academicYear],
    );
    return result.map((row) => _mapToGrade(row)).toList();
  }

  @override
  Future<Grade?> findByNameAndYear(String name, String academicYear) async {
    final result = await _dbHelper.query(
      'grados',
      where: 'nombre = @nombre AND ano_academico = @ano_academico',
      whereArgs: [name, academicYear],
    );

    if (result.isEmpty) return null;
    return _mapToGrade(result.first);
  }

  @override
  Future<List<Grade>> findActiveGrades() async {
    final result = await _dbHelper.query(
      'grados',
      where: 'activo = @activo',
      whereArgs: [true],
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
      active: row['activo'] == true,
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
      'activo': grade.active,
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
