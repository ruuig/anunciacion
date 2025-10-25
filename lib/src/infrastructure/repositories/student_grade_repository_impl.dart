import 'package:anunciacion/src/infrastructure/db/database_helper.dart';
import 'package:anunciacion/src/domain/repositories/student_grade_repository.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:postgres/postgres.dart' as postgres;

class StudentGradeRepositoryImpl implements StudentGradeRepository {
  final DatabaseHelper _db = DatabaseHelper();

  @override
  Future<GradeEntry?> findById(int id) async {
    final db = await _db.database;
    try {
      final result = await db.execute(
        postgres.Sql.named('SELECT * FROM student_grades WHERE id = @id'),
        parameters: {'id': id}
      );
      if (result.isEmpty) return null;
      return _mapToGradeEntry(result.first.toColumnMap());
    } catch (e) {
      print('Error en findById: $e');
      return null;
    }
  }

  @override
  Future<List<GradeEntry>> findAll() async {
    final db = await _db.database;
    final result = await db.execute('SELECT * FROM student_grades ORDER BY student_id, subject_id, period_id');
    return result.map((row) => _mapToGradeEntry(row.toColumnMap())).toList();
  }

  @override
  Future<GradeEntry> save(GradeEntry entity) async {
    final db = await _db.database;

    // Primero intentar actualizar si ya existe
    final existing = await db.execute(
      postgres.Sql.named('''
        SELECT id FROM student_grades
        WHERE student_id = @studentId AND subject_id = @subjectId AND period_id = @periodId
      '''),
      parameters: {
        'studentId': entity.studentId,
        'subjectId': entity.subjectId,
        'periodId': entity.periodId,
      }
    );

    if (existing.isNotEmpty) {
      // Actualizar
      await db.execute(
        postgres.Sql.named('''
          UPDATE student_grades
          SET value = @value
          WHERE student_id = @studentId AND subject_id = @subjectId AND period_id = @periodId
        '''),
        parameters: {
          'studentId': entity.studentId,
          'subjectId': entity.subjectId,
          'periodId': entity.periodId,
          'value': entity.value ?? 0,
        }
      );
      return entity.copyWith(id: existing.first.first as int?);
    } else {
      // Insertar nuevo
      final result = await db.execute(
        postgres.Sql.named('''
          INSERT INTO student_grades (student_id, subject_id, period_id, value)
          VALUES (@studentId, @subjectId, @periodId, @value)
          RETURNING id
        '''),
        parameters: {
          'studentId': entity.studentId,
          'subjectId': entity.subjectId,
          'periodId': entity.periodId,
          'value': entity.value ?? 0,
        }
      );
      return entity.copyWith(id: result.first.first as int?);
    }
  }

  @override
  Future<GradeEntry> update(GradeEntry entity) async {
    if (entity.id == null) {
      throw Exception('Cannot update entity without id');
    }

    final db = await _db.database;
    await db.execute(
      postgres.Sql.named('''
        UPDATE student_grades
        SET value = @value, period_id = @periodId
        WHERE id = @id
      '''),
      parameters: {
        'id': entity.id,
        'value': entity.value ?? 0,
        'periodId': entity.periodId,
      }
    );

    return entity;
  }

  @override
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.execute(
      postgres.Sql.named('DELETE FROM student_grades WHERE id = @id'),
      parameters: {'id': id}
    );
  }

  @override
  Future<bool> existsById(int id) async {
    final entity = await findById(id);
    return entity != null;
  }

  @override
  Future<List<GradeEntry>> getGrades({
    required int groupId,
    required int subjectId,
    required int periodId,
  }) async {
    final db = await _db.database;
    final result = await db.execute(
      postgres.Sql.named('''
        SELECT sg.id, sg.student_id, sg.subject_id, sg.period_id, sg.value
        FROM student_grades sg
        JOIN estudiantes s ON s.id = sg.student_id
        WHERE s.group_id = @groupId
          AND sg.subject_id = @subjectId
          AND sg.period_id = @periodId
        ORDER BY s.nombre
      '''),
      parameters: {
        'groupId': groupId,
        'subjectId': subjectId,
        'periodId': periodId,
      }
    );

    return result.map((row) => _mapToGradeEntry(row.toColumnMap())).toList();
  }

  @override
  Future<void> upsertGrade({
    required int studentId,
    required int subjectId,
    required int periodId,
    required double value,
  }) async {
    await save(GradeEntry(
      studentId: studentId,
      subjectId: subjectId,
      periodId: periodId,
      value: value,
    ));
  }

  @override
  Future<void> upsertGradesBatch(List<GradeEntry> entries) async {
    for (final entry in entries) {
      final value = entry.value;
      if (value != null && (value < 0 || value > 100)) {
        throw RangeError.range(
          value,
          0,
          100,
          'value',
          'Las calificaciones deben estar entre 0 y 100.',
        );
      }
    }

    final db = await _db.database;
    for (final entry in entries) {
      await db.execute(
        postgres.Sql.named('''
          INSERT INTO student_grades (student_id, subject_id, period_id, value)
          VALUES (@studentId, @subjectId, @periodId, @value)
          ON CONFLICT (student_id, subject_id, period_id)
          DO UPDATE SET value = EXCLUDED.value
        '''),
        parameters: {
          'studentId': entry.studentId,
          'subjectId': entry.subjectId,
          'periodId': entry.periodId,
          'value': entry.value ?? 0,
        }
      );
    }
  }

  @override
  Future<double> getAverage({
    required int groupId,
    required int subjectId,
    required int periodId,
  }) async {
    final grades = await getGrades(
      groupId: groupId,
      subjectId: subjectId,
      periodId: periodId,
    );

    if (grades.isEmpty) return 0.0;

    final validGrades = grades.where((g) => g.value != null).toList();
    if (validGrades.isEmpty) return 0.0;

    final sum = validGrades.map((g) => g.value!).reduce((a, b) => a + b);
    return sum / validGrades.length;
  }

  @override
  Future<List<GradeEntry>> getStudentGrades({
    required int studentId,
    required int subjectId,
    required int periodId,
  }) async {
    final db = await _db.database;
    final result = await db.execute(
      postgres.Sql.named('''
        SELECT * FROM student_grades
        WHERE student_id = @studentId
          AND subject_id = @subjectId
          AND period_id = @periodId
      '''),
      parameters: {
        'studentId': studentId,
        'subjectId': subjectId,
        'periodId': periodId,
      }
    );

    return result.map((row) => _mapToGradeEntry(row.toColumnMap())).toList();
  }

  GradeEntry _mapToGradeEntry(Map<String, dynamic> row) {
    return GradeEntry(
      id: row['id'] as int?,
      studentId: row['student_id'] as int,
      subjectId: row['subject_id'] as int,
      periodId: row['period_id'] as int,
      value: (row['value'] as num?)?.toDouble(),
    );
  }
}
