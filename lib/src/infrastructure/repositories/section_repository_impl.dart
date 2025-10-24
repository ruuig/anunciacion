// Implementación del SectionRepository usando PostgreSQL
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../db/database_helper.dart';

class SectionRepositoryImpl implements SectionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Section?> findById(int id) async {
    final result = await _dbHelper.findById('secciones', id);
    if (result == null) return null;
    return _mapToSection(result);
  }

  @override
  Future<List<Section>> findAll() async {
    final result = await _dbHelper.findAll('secciones');
    return result.map((row) => _mapToSection(row)).toList();
  }

  @override
  Future<Section> save(Section entity) async {
    if (entity.id == 0) {
      final id = await _dbHelper.insert('secciones', _mapFromSection(entity));
      return entity.copyWith(id: id);
    } else {
      await _dbHelper.update('secciones', _mapFromSection(entity), 'id = @id', [entity.id]);
      return entity;
    }
  }

  @override
  Future<Section> update(Section entity) async {
    await _dbHelper.update('secciones', _mapFromSection(entity), 'id = @id', [entity.id]);
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.delete('secciones', 'id = @id', [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('secciones', 'id = @id', [id]);
  }

  @override
  Future<List<Section>> findByGrade(int gradeId) async {
    final result = await _dbHelper.query(
      'secciones',
      where: 'grado_id = @grado_id',
      whereArgs: [gradeId],
    );
    return result.map((row) => _mapToSection(row)).toList();
  }

  @override
  Future<Section?> findByGradeAndName(int gradeId, String name) async {
    final result = await _dbHelper.query(
      'secciones',
      where: 'grado_id = @grado_id AND nombre = @nombre',
      whereArgs: [gradeId, name],
    );

    if (result.isEmpty) return null;
    return _mapToSection(result.first);
  }

  @override
  Future<List<Section>> findActiveSections() async {
    final result = await _dbHelper.query(
      'secciones',
      where: 'activo = @activo',
      whereArgs: [true],
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
      active: row['activo'] == true,
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
      'activo': section.active,
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
