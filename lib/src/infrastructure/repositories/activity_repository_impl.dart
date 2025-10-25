import 'package:anunciacion/src/domain/entities/activity.dart';
import 'package:anunciacion/src/domain/entities/activity_grade.dart';
import 'package:anunciacion/src/domain/repositories/activity_repository.dart';
import 'package:anunciacion/src/domain/value_objects/activity_filters.dart';
import 'package:anunciacion/src/infrastructure/db/database_helper.dart';
import 'package:postgres/postgres.dart' as postgres;

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;

  @override
  Future<Activity?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.execute(
      postgres.Sql.named(_baseSelect(where: 'a.id = @id')),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return _mapToActivity(result.first.toColumnMap());
  }

  @override
  Future<List<Activity>> findAll() {
    return getActivities();
  }

  @override
  Future<Activity> save(Activity entity) {
    return createActivity(entity);
  }

  @override
  Future<Activity> update(Activity entity) async {
    if (entity.id == null) {
      throw ArgumentError('Activity id is required to update');
    }

    final db = await _dbHelper.database;
    await db.execute(
      postgres.Sql.named('''
        UPDATE actividades
           SET nombre = @name,
               descripcion = @description,
               materia_id = @subjectId,
               grado_id = @gradeId,
               seccion_id = @sectionId,
               periodo_id = @periodId,
               tipo = @type,
               puntos_maximos = @maxPoints,
               fecha_programada = @scheduledAt,
               fecha_entrega = @dueDate,
               estado = @status,
               fecha_actualizacion = NOW()
         WHERE id = @id
      '''),
      parameters: {
        'id': entity.id,
        'name': entity.name,
        'description': entity.description,
        'subjectId': entity.subjectId,
        'gradeId': entity.gradeId,
        'sectionId': entity.sectionId,
        'periodId': entity.periodId,
        'type': entity.type,
        'maxPoints': entity.maxPoints,
        'scheduledAt': entity.scheduledAt,
        'dueDate': entity.dueDate,
        'status': entity.status,
      },
    );

    final updated = await findById(entity.id!);
    if (updated == null) {
      throw StateError('Activity ${entity.id} could not be loaded after update');
    }
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.execute(
      postgres.Sql.named('DELETE FROM actividades WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  @override
  Future<bool> existsById(int id) async {
    final entity = await findById(id);
    return entity != null;
  }

  @override
  Future<List<Activity>> getActivities({ActivityFilters? filters}) async {
    final db = await _dbHelper.database;
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (filters?.gradeId != null) {
      conditions.add('a.grado_id = @gradeId');
      parameters['gradeId'] = filters!.gradeId;
    }
    if (filters?.sectionId != null) {
      conditions.add('a.seccion_id = @sectionId');
      parameters['sectionId'] = filters!.sectionId;
    }
    if (filters?.subjectId != null) {
      conditions.add('a.materia_id = @subjectId');
      parameters['subjectId'] = filters!.subjectId;
    }
    if (filters?.type != null && filters!.type!.isNotEmpty) {
      conditions.add('LOWER(a.tipo) = LOWER(@type)');
      parameters['type'] = filters.type;
    }

    final query = _baseSelect(
      where: conditions.isEmpty ? null : conditions.join(' AND '),
    );

    final result = await db.execute(
      postgres.Sql.named(query),
      parameters: parameters,
    );

    return result.map((row) => _mapToActivity(row.toColumnMap())).toList();
  }

  @override
  Future<Activity> createActivity(Activity activity) async {
    final db = await _dbHelper.database;
    final insertResult = await db.execute(
      postgres.Sql.named('''
        INSERT INTO actividades (
          nombre,
          descripcion,
          docente_id,
          materia_id,
          grado_id,
          seccion_id,
          periodo_id,
          tipo,
          puntos_maximos,
          fecha_programada,
          fecha_entrega,
          estado
        ) VALUES (
          @name,
          @description,
          @teacherId,
          @subjectId,
          @gradeId,
          @sectionId,
          @periodId,
          @type,
          @maxPoints,
          @scheduledAt,
          @dueDate,
          @status
        )
        RETURNING id
      '''),
      parameters: {
        'name': activity.name,
        'description': activity.description,
        'teacherId': activity.teacherId,
        'subjectId': activity.subjectId,
        'gradeId': activity.gradeId,
        'sectionId': activity.sectionId,
        'periodId': activity.periodId,
        'type': activity.type,
        'maxPoints': activity.maxPoints,
        'scheduledAt': activity.scheduledAt,
        'dueDate': activity.dueDate,
        'status': activity.status,
      },
    );

    final id = insertResult.first.first as int;
    final created = await findById(id);
    if (created == null) {
      throw StateError('Activity $id could not be loaded after creation');
    }
    return created;
  }

  @override
  Future<List<ActivityGrade>> getActivityGrades(int activityId) async {
    final db = await _dbHelper.database;

    final result = await db.execute(
      postgres.Sql.named('''
        WITH activity_data AS (
          SELECT id, grado_id, seccion_id
            FROM actividades
           WHERE id = @activityId
        )
        SELECT ca.id,
               COALESCE(ca.actividad_id, a.id) AS actividad_id,
               e.id AS student_id,
               e.nombre AS student_name,
               ca.puntos_obtenidos,
               ca.porcentaje_calificacion,
               ca.comentarios,
               ca.calificado_por,
               ca.fecha_calificacion,
               ca.fecha_creacion,
               ca.fecha_actualizacion
          FROM estudiantes e
          JOIN activity_data a ON a.grado_id = e.grado_id AND a.seccion_id = e.seccion_id
          LEFT JOIN calificaciones_actividades ca
                 ON ca.actividad_id = a.id AND ca.estudiante_id = e.id
         WHERE e.estado = 'activo'
         ORDER BY e.nombre
      '''),
      parameters: {'activityId': activityId},
    );

    return result.map((row) => _mapToActivityGrade(row.toColumnMap())).toList();
  }

  @override
  Future<void> saveActivityGrades({
    required int activityId,
    required int gradedBy,
    required List<ActivityGrade> grades,
  }) async {
    if (grades.isEmpty) return;

    final db = await _dbHelper.database;
    await db.runTx((ctx) async {
      final activityResult = await ctx.execute(
        postgres.Sql.named('''
          SELECT materia_id, periodo_id, puntos_maximos
            FROM actividades
           WHERE id = @activityId
        '''),
        parameters: {'activityId': activityId},
      );

      if (activityResult.isEmpty) {
        throw StateError('Activity $activityId not found');
      }

      final activityRow = activityResult.first.toColumnMap();
      final subjectId = activityRow['materia_id'] as int;
      final periodId = activityRow['periodo_id'] as int;
      final maxPoints = (activityRow['puntos_maximos'] as num).toDouble();

      for (final grade in grades) {
        final obtained = grade.obtainedPoints;
        final percentage = grade.percentage ??
            (obtained == null ? null : (obtained / maxPoints) * 100);

        await ctx.execute(
          postgres.Sql.named('''
            INSERT INTO calificaciones_actividades (
              actividad_id,
              estudiante_id,
              puntos_obtenidos,
              porcentaje_calificacion,
              comentarios,
              calificado_por,
              fecha_calificacion,
              fecha_actualizacion
            ) VALUES (
              @activityId,
              @studentId,
              @obtainedPoints,
              @percentage,
              @comments,
              @gradedBy,
              NOW(),
              NOW()
            )
            ON CONFLICT (actividad_id, estudiante_id)
            DO UPDATE SET
              puntos_obtenidos = EXCLUDED.puntos_obtenidos,
              porcentaje_calificacion = EXCLUDED.porcentaje_calificacion,
              comentarios = EXCLUDED.comentarios,
              calificado_por = EXCLUDED.calificado_por,
              fecha_calificacion = NOW(),
              fecha_actualizacion = NOW()
          '''),
          parameters: {
            'activityId': activityId,
            'studentId': grade.studentId,
            'obtainedPoints': obtained,
            'percentage': percentage,
            'comments': grade.comments,
            'gradedBy': gradedBy,
          },
        );

        final aggregatedResult = await ctx.execute(
          postgres.Sql.named('''
            SELECT COALESCE(SUM(ca.porcentaje_calificacion), 0) AS total_percentage
              FROM calificaciones_actividades ca
              JOIN actividades a ON a.id = ca.actividad_id
             WHERE ca.estudiante_id = @studentId
               AND a.materia_id = @subjectId
               AND a.periodo_id = @periodId
          '''),
          parameters: {
            'studentId': grade.studentId,
            'subjectId': subjectId,
            'periodId': periodId,
          },
        );

        final total = (aggregatedResult.first.toColumnMap()['total_percentage'] as num?)
                ?.toDouble() ??
            0;

        await ctx.execute(
          postgres.Sql.named('''
            INSERT INTO student_grades (
              student_id,
              subject_id,
              period_id,
              value,
              updated_at
            ) VALUES (
              @studentId,
              @subjectId,
              @periodId,
              @value,
              NOW()
            )
            ON CONFLICT (student_id, subject_id, period_id)
            DO UPDATE SET
              value = EXCLUDED.value,
              updated_at = NOW()
          '''),
          parameters: {
            'studentId': grade.studentId,
            'subjectId': subjectId,
            'periodId': periodId,
            'value': total,
          },
        );
      }
    });
  }

  String _baseSelect({String? where}) {
    final buffer = StringBuffer('''
      SELECT a.id,
             a.nombre,
             a.descripcion,
             a.docente_id,
             a.materia_id,
             a.grado_id,
             a.seccion_id,
             a.periodo_id,
             a.tipo,
             a.puntos_maximos,
             a.fecha_programada,
             a.fecha_entrega,
             a.estado,
             a.fecha_creacion,
             a.fecha_actualizacion,
             (SELECT COUNT(*)
                FROM estudiantes s
               WHERE s.grado_id = a.grado_id
                 AND s.seccion_id = a.seccion_id
                 AND s.estado = 'activo') AS total_students,
             (SELECT COUNT(*)
                FROM calificaciones_actividades ca
               WHERE ca.actividad_id = a.id
                 AND ca.puntos_obtenidos IS NOT NULL) AS graded_students,
             (SELECT AVG(ca.porcentaje_calificacion)
                FROM calificaciones_actividades ca
               WHERE ca.actividad_id = a.id
                 AND ca.porcentaje_calificacion IS NOT NULL) AS average_percentage,
             m.nombre AS materia_nombre,
             g.nombre AS grado_nombre,
             s.nombre AS seccion_nombre,
             p.nombre AS periodo_nombre
        FROM actividades a
        JOIN materias m ON m.id = a.materia_id
        JOIN grados g ON g.id = a.grado_id
        JOIN secciones s ON s.id = a.seccion_id
        JOIN periodos_academicos p ON p.id = a.periodo_id
    ''');

    if (where != null && where.isNotEmpty) {
      buffer.writeln('WHERE $where');
    }

    buffer.writeln(
        'ORDER BY COALESCE(a.fecha_programada, a.fecha_creacion) DESC, a.id DESC');
    return buffer.toString();
  }

  Activity _mapToActivity(Map<String, dynamic> row) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final maxPoints = (row['puntos_maximos'] as num?)?.toDouble() ?? 0;
    final average = (row['average_percentage'] as num?)?.toDouble();

    return Activity(
      id: row['id'] as int?,
      name: row['nombre'] as String? ?? '',
      description: row['descripcion'] as String?,
      teacherId: row['docente_id'] as int? ?? 0,
      subjectId: row['materia_id'] as int? ?? 0,
      gradeId: row['grado_id'] as int? ?? 0,
      sectionId: row['seccion_id'] as int? ?? 0,
      periodId: row['periodo_id'] as int? ?? 0,
      type: row['tipo'] as String? ?? '',
      maxPoints: maxPoints,
      scheduledAt: _parseDate(row['fecha_programada']),
      dueDate: _parseDate(row['fecha_entrega']),
      status: row['estado'] as String? ?? 'pendiente',
      createdAt: _parseDate(row['fecha_creacion']) ?? DateTime.now(),
      updatedAt: _parseDate(row['fecha_actualizacion']) ?? DateTime.now(),
      gradedStudents: row['graded_students'] as int?,
      totalStudents: row['total_students'] as int?,
      averagePercentage: average,
      subjectName: row['materia_nombre'] as String?,
      gradeName: row['grado_nombre'] as String?,
      sectionName: row['seccion_nombre'] as String?,
      periodName: row['periodo_nombre'] as String?,
    );
  }

  ActivityGrade _mapToActivityGrade(Map<String, dynamic> row) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return ActivityGrade(
      id: row['id'] as int?,
      activityId: row['actividad_id'] as int? ?? row['id'] as int? ?? 0,
      studentId: row['student_id'] as int? ?? 0,
      studentName: row['student_name'] as String?,
      obtainedPoints: (row['puntos_obtenidos'] as num?)?.toDouble(),
      percentage: (row['porcentaje_calificacion'] as num?)?.toDouble(),
      comments: row['comentarios'] as String?,
      gradedBy: row['calificado_por'] as int?,
      gradedAt: _parseDate(row['fecha_calificacion']),
      createdAt: _parseDate(row['fecha_creacion']),
      updatedAt: _parseDate(row['fecha_actualizacion']),
    );
  }
}
