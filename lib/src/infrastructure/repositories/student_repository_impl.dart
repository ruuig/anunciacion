// Implementación del StudentRepository usando SQLite
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/value_objects/value_objects.dart';
import '../db/database_helper.dart';

class StudentRepositoryImpl implements StudentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Student?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'estudiantes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return _mapToStudent(result.first);
  }

  @override
  Future<List<Student>> findAll() async {
    final db = await _dbHelper.database;
    final result = await db.query('estudiantes');
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<Student> save(Student entity) async {
    final db = await _dbHelper.database;

    if (entity.id == 0) {
      final id = await db.insert('estudiantes', _mapFromStudent(entity));
      return entity.copyWith(id: id);
    } else {
      await db.update(
        'estudiantes',
        _mapFromStudent(entity),
        where: 'id = ?',
        whereArgs: [entity.id],
      );
      return entity;
    }
  }

  @override
  Future<Student> update(Student entity) async {
    final db = await _dbHelper.database;
    await db.update(
      'estudiantes',
      _mapFromStudent(entity),
      where: 'id = ?',
      whereArgs: [entity.id],
    );
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('estudiantes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('estudiantes', 'id = ?', [id]);
  }

  @override
  Future<Student?> findByDPI(DPI dpi) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'estudiantes',
      where: 'dpi = ?',
      whereArgs: [dpi.value],
    );

    if (result.isEmpty) return null;
    return _mapToStudent(result.first);
  }

  @override
  Future<List<Student>> findByGrade(int gradeId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'estudiantes',
      where: 'grado_id = ?',
      whereArgs: [gradeId],
    );
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<List<Student>> findBySection(int sectionId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'estudiantes',
      where: 'seccion_id = ?',
      whereArgs: [sectionId],
    );
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<List<Student>> findByParent(int parentId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT e.* FROM estudiantes e
      INNER JOIN estudiantes_padres ep ON e.id = ep.estudiante_id
      WHERE ep.padre_id = ?
    ''', [parentId]);
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<List<Student>> findActiveStudents() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'estudiantes',
      where: 'estado = ?',
      whereArgs: ['activo'],
    );
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<bool> existsByDPI(DPI dpi) async {
    return await _dbHelper.exists('estudiantes', 'dpi = ?', [dpi.value]);
  }

  // Método helper para convertir de Map a Student
  Student _mapToStudent(Map<String, dynamic> row) {
    return Student(
      id: row['id'],
      dpi: DPI(row['dpi']),
      name: row['nombre'],
      birthDate: DateTime.parse(row['fecha_nacimiento']),
      gender: row['genero'] != null ? Gender.fromString(row['genero']) : null,
      address: row['direccion'] != null ? Address.fromString(row['direccion']) : null,
      phone: row['telefono'] != null ? Phone.fromString(row['telefono']) : null,
      email: row['email'] != null ? Email.fromString(row['email']) : null,
      avatarUrl: row['url_avatar'],
      gradeId: row['grado_id'],
      sectionId: row['seccion_id'],
      enrollmentDate: DateTime.parse(row['fecha_inscripcion']),
      status: UserStatus.fromString(row['estado']),
      createdAt: DateTime.parse(row['fecha_creacion']),
      updatedAt: DateTime.parse(row['fecha_actualizacion']),
    );
  }

  // Método helper para convertir de Student a Map
  Map<String, dynamic> _mapFromStudent(Student student) {
    return {
      'id': student.id,
      'dpi': student.dpi.value,
      'nombre': student.name,
      'fecha_nacimiento': student.birthDate.toIso8601String(),
      'genero': student.gender?.toString(),
      'direccion': student.address?.toString(),
      'telefono': student.phone?.value,
      'email': student.email?.value,
      'url_avatar': student.avatarUrl,
      'grado_id': student.gradeId,
      'seccion_id': student.sectionId,
      'fecha_inscripcion': student.enrollmentDate.toIso8601String(),
      'estado': student.status.toString(),
      'fecha_creacion': student.createdAt.toIso8601String(),
      'fecha_actualizacion': student.updatedAt.toIso8601String(),
    };
  }
}

// Extensión para crear una copia de Student con ID actualizado
extension StudentCopyWith on Student {
  Student copyWith({int? id}) {
    return Student(
      id: id ?? this.id,
      dpi: dpi,
      name: name,
      birthDate: birthDate,
      gender: gender,
      address: address,
      phone: phone,
      email: email,
      avatarUrl: avatarUrl,
      gradeId: gradeId,
      sectionId: sectionId,
      enrollmentDate: enrollmentDate,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
