// Implementación del StudentRepository usando PostgreSQL
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/value_objects/dpi.dart';
import '../../domain/value_objects/gender.dart';
import '../../domain/value_objects/address.dart';
import '../../domain/value_objects/phone.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/user_status.dart';
import '../db/database_helper.dart';

class StudentRepositoryImpl implements StudentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Student?> findById(int id) async {
    final result = await _dbHelper.findById('estudiantes', id);
    if (result == null) return null;
    return _mapToStudent(result);
  }

  @override
  Future<List<Student>> findAll() async {
    final result = await _dbHelper.findAll('estudiantes');
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<Student> save(Student entity) async {
    if (entity.id == 0) {
      final id = await _dbHelper.insert('estudiantes', _mapFromStudent(entity));
      return entity.copyWith(id: id);
    } else {
      await _dbHelper.update('estudiantes', _mapFromStudent(entity), 'id = @id', [entity.id]);
      return entity;
    }
  }

  @override
  Future<Student> update(Student entity) async {
    await _dbHelper.update('estudiantes', _mapFromStudent(entity), 'id = @id', [entity.id]);
    return entity;
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.delete('estudiantes', 'id = @id', [id]);
  }

  @override
  Future<bool> existsById(int id) async {
    return await _dbHelper.exists('estudiantes', 'id = @id', [id]);
  }

  @override
  Future<Student?> findByDPI(DPI dpi) async {
    final result = await _dbHelper.query(
      'estudiantes',
      where: 'dpi = @dpi',
      whereArgs: [dpi.value],
    );

    if (result.isEmpty) return null;
    return _mapToStudent(result.first);
  }

  @override
  Future<List<Student>> findByGrade(int gradeId) async {
    final result = await _dbHelper.query(
      'estudiantes',
      where: 'grado_id = @grade_id',
      whereArgs: [gradeId],
    );
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<List<Student>> findBySection(int sectionId) async {
    final result = await _dbHelper.query(
      'estudiantes',
      where: 'seccion_id = @section_id',
      whereArgs: [sectionId],
    );
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<List<Student>> findByParent(int parentId) async {
    final result = await _dbHelper.query('''
      SELECT e.* FROM escuela.estudiantes e
      INNER JOIN escuela.estudiantes_padres ep ON e.id = ep.estudiante_id
      WHERE ep.padre_id = @parent_id
    ''', whereArgs: [parentId]);
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<List<Student>> findActiveStudents() async {
    final result = await _dbHelper.query(
      'estudiantes',
      where: 'estado = @estado',
      whereArgs: ['activo'],
    );
    return result.map((row) => _mapToStudent(row)).toList();
  }

  @override
  Future<bool> existsByDPI(DPI dpi) async {
    return await _dbHelper.exists('estudiantes', 'dpi = @dpi', [dpi.value]);
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
      phone: row['telefono'] != null ? Phone(row['telefono']) : null,
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
