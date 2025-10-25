import 'package:anunciacion/src/domain/entities/subject.dart';
import 'package:anunciacion/src/domain/repositories/subject_repository.dart';
import 'package:anunciacion/src/infrastructure/db/database_helper.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;

  @override
  Future<Subject?> findById(int id) async {
    final result = await _dbHelper.findById('materias', id);
    if (result == null) return null;
    return _mapToSubject(result);
  }

  @override
  Future<List<Subject>> findAll() async {
    final result = await _dbHelper.findAll('materias');
    return result.map(_mapToSubject).toList();
  }

  @override
  Future<Subject> save(Subject entity) async {
    if (entity.id == 0) {
      final id = await _dbHelper.insert('materias', _mapFromSubject(entity));
      return entity.copyWith(id: id);
    }

    await _dbHelper.update(
      'materias',
      _mapFromSubject(entity),
      'id = @id',
      [entity.id],
    );
    return entity;
  }

  @override
  Future<Subject> update(Subject entity) async {
    await _dbHelper.update(
      'materias',
      _mapFromSubject(entity),
      'id = @id',
      [entity.id],
    );
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.delete('materias', 'id = @id', [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return _dbHelper.exists('materias', 'id = @id', [id]);
  }

  @override
  Future<Subject?> findByCode(String code) async {
    final result = await _dbHelper.query(
      'materias',
      where: 'codigo = @codigo',
      whereArgs: [code],
    );
    if (result.isEmpty) return null;
    return _mapToSubject(result.first);
  }

  @override
  Future<Subject?> findByName(String name) async {
    final result = await _dbHelper.query(
      'materias',
      where: 'nombre = @nombre',
      whereArgs: [name],
    );
    if (result.isEmpty) return null;
    return _mapToSubject(result.first);
  }

  @override
  Future<List<Subject>> findActiveSubjects() async {
    final result = await _dbHelper.query(
      'materias',
      where: 'activo = @activo',
      whereArgs: [true],
    );
    return result.map(_mapToSubject).toList();
  }

  @override
  Future<bool> existsByCode(String code) {
    return _dbHelper.exists('materias', 'codigo = @codigo', [code]);
  }

  @override
  Future<bool> existsByName(String name) {
    return _dbHelper.exists('materias', 'nombre = @nombre', [name]);
  }

  Subject _mapToSubject(Map<String, dynamic> row) {
    DateTime _parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return Subject(
      id: row['id'] as int? ?? 0,
      name: row['nombre'] as String? ?? '',
      code: row['codigo'] as String?,
      description: row['descripcion'] as String?,
      active: row['activo'] == true,
      createdAt: _parseDate(row['fecha_creacion']),
    );
  }

  Map<String, dynamic> _mapFromSubject(Subject subject) {
    return {
      'id': subject.id,
      'nombre': subject.name,
      'codigo': subject.code,
      'descripcion': subject.description,
      'activo': subject.active,
      'fecha_creacion': subject.createdAt.toIso8601String(),
    };
  }
}

extension SubjectCopyWith on Subject {
  Subject copyWith({int? id}) {
    return Subject(
      id: id ?? this.id,
      name: name,
      code: code,
      description: description,
      active: active,
      createdAt: createdAt,
    );
  }
}
