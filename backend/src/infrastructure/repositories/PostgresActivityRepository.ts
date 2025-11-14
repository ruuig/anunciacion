import { query } from "../../config/database";
import { Activity, ActivityGrade, Grade } from "../../domain/entities/Activity";

export class PostgresActivityRepository {
  // ============================================
  // ACTIVIDADES
  // ============================================

  async createActivity(data: {
    nombre: string;
    descripcion?: string;
    materiaId: number;
    gradoId: number;
    docenteId: number;
    periodo: number;
    anoAcademico: number;
    ponderacion: number;
    fechaEntrega?: Date;
    tipo?: string;
  }): Promise<Activity> {
    const { rows } = await query<any>(
      `INSERT INTO actividades (
        nombre, descripcion, materia_id, grado_id, docente_id, 
        periodo, ano_academico, ponderacion, fecha_entrega, tipo, 
        puntos_maximos, activo
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, true)
      RETURNING 
        id,
        nombre,
        descripcion,
        materia_id as "materiaId",
        grado_id as "gradoId",
        docente_id as "docenteId",
        periodo,
        ano_academico as "anoAcademico",
        ponderacion,
        fecha_entrega as "fechaEntrega",
        fecha_creacion as "fechaCreacion",
        tipo,
        puntos_maximos as "puntosMaximos",
        activo`,
      [
        data.nombre,
        data.descripcion || null,
        data.materiaId,
        data.gradoId,
        data.docenteId,
        data.periodo,
        data.anoAcademico,
        data.ponderacion,
        data.fechaEntrega || null,
        data.tipo || 'Tarea', // Valor por defecto
        data.ponderacion // puntos_maximos = ponderacion
      ]
    );
    return rows[0];
  }

  async getActivities(filters: {
    materiaId: number;
    gradoId: number;
    periodo: number;
    anoAcademico: number;
    docenteId?: number;
  }): Promise<Activity[]> {
    const conditions = [
      'materia_id = $1',
      'grado_id = $2',
      'periodo = $3',
      'ano_academico = $4',
      'activo = true'
    ];
    const params: any[] = [
      filters.materiaId,
      filters.gradoId,
      filters.periodo,
      filters.anoAcademico
    ];

    if (filters.docenteId) {
      conditions.push(`docente_id = $${params.length + 1}`);
      params.push(filters.docenteId);
    }

    const { rows } = await query<any>(
      `SELECT 
        id,
        nombre,
        descripcion,
        materia_id as "materiaId",
        grado_id as "gradoId",
        docente_id as "docenteId",
        periodo,
        ano_academico as "anoAcademico",
        ponderacion,
        fecha_entrega as "fechaEntrega",
        fecha_creacion as "fechaCreacion",
        activo
      FROM actividades
      WHERE ${conditions.join(' AND ')}
      ORDER BY fecha_creacion DESC`,
      params
    );
    return rows;
  }

  async updateActivity(id: number, data: Partial<Activity>): Promise<Activity> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (data.nombre !== undefined) {
      fields.push(`nombre = $${paramIndex++}`);
      values.push(data.nombre);
    }
    if (data.descripcion !== undefined) {
      fields.push(`descripcion = $${paramIndex++}`);
      values.push(data.descripcion);
    }
    if (data.ponderacion !== undefined) {
      fields.push(`ponderacion = $${paramIndex++}`);
      values.push(data.ponderacion);
    }
    if (data.fechaEntrega !== undefined) {
      fields.push(`fecha_entrega = $${paramIndex++}`);
      values.push(data.fechaEntrega);
    }
    if (data.activo !== undefined) {
      fields.push(`activo = $${paramIndex++}`);
      values.push(data.activo);
    }

    values.push(id);

    const { rows } = await query<any>(
      `UPDATE actividades
       SET ${fields.join(", ")}
       WHERE id = $${paramIndex}
       RETURNING 
        id,
        nombre,
        descripcion,
        materia_id as "materiaId",
        grado_id as "gradoId",
        docente_id as "docenteId",
        periodo,
        ano_academico as "anoAcademico",
        ponderacion,
        fecha_entrega as "fechaEntrega",
        fecha_creacion as "fechaCreacion",
        activo`,
      values
    );
    return rows[0];
  }

  async deleteActivity(id: number): Promise<void> {
    await query('UPDATE actividades SET activo = false WHERE id = $1', [id]);
  }

  // ============================================
  // CALIFICACIONES DE ACTIVIDADES
  // ============================================

  async setActivityGrade(data: {
    actividadId: number;
    estudianteId: number;
    nota: number;
    observaciones?: string;
  }): Promise<ActivityGrade> {
    const { rows } = await query<any>(
      `INSERT INTO calificaciones_actividad (
        actividad_id, estudiante_id, nota, observaciones
      )
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (actividad_id, estudiante_id)
      DO UPDATE SET
        nota = $3,
        observaciones = $4,
        fecha_actualizacion = CURRENT_TIMESTAMP
      RETURNING 
        id,
        actividad_id as "actividadId",
        estudiante_id as "estudianteId",
        nota,
        observaciones,
        fecha_registro as "fechaRegistro",
        fecha_actualizacion as "fechaActualizacion"`,
      [data.actividadId, data.estudianteId, data.nota, data.observaciones || null]
    );
    return rows[0];
  }

  async getActivityGrades(actividadId: number): Promise<ActivityGrade[]> {
    const { rows } = await query<any>(
      `SELECT 
        id,
        actividad_id as "actividadId",
        estudiante_id as "estudianteId",
        nota,
        observaciones,
        fecha_registro as "fechaRegistro",
        fecha_actualizacion as "fechaActualizacion"
      FROM calificaciones_actividad
      WHERE actividad_id = $1
      ORDER BY estudiante_id`,
      [actividadId]
    );
    return rows;
  }

  async getStudentActivityGrades(estudianteId: number, filters: {
    materiaId: number;
    gradoId: number;
    periodo: number;
    anoAcademico: number;
  }): Promise<ActivityGrade[]> {
    const { rows } = await query<any>(
      `SELECT 
        ca.id,
        ca.actividad_id as "actividadId",
        ca.estudiante_id as "estudianteId",
        ca.nota,
        ca.observaciones,
        ca.fecha_registro as "fechaRegistro",
        ca.fecha_actualizacion as "fechaActualizacion"
      FROM calificaciones_actividad ca
      INNER JOIN actividades a ON ca.actividad_id = a.id
      WHERE ca.estudiante_id = $1
        AND a.materia_id = $2
        AND a.grado_id = $3
        AND a.periodo = $4
        AND a.ano_academico = $5
        AND a.activo = true
      ORDER BY a.fecha_creacion`,
      [estudianteId, filters.materiaId, filters.gradoId, filters.periodo, filters.anoAcademico]
    );
    return rows;
  }

  // ============================================
  // CALIFICACIONES FINALES
  // ============================================

  async setManualGrade(data: {
    estudianteId: number;
    materiaId: number;
    gradoId: number;
    docenteId: number;
    periodo: number;
    anoAcademico: number;
    notaManual: number;
    observaciones?: string;
  }): Promise<Grade> {
    const { rows } = await query<any>(
      `INSERT INTO calificaciones (
        estudiante_id, materia_id, grado_id, docente_id, periodo,
        ano_academico, nota_manual, nota_final, usar_nota_manual, observaciones
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $7, true, $8)
      ON CONFLICT (estudiante_id, materia_id, grado_id, periodo, ano_academico)
      DO UPDATE SET
        nota_manual = $7,
        nota_final = $7,
        usar_nota_manual = true,
        observaciones = $8,
        fecha_actualizacion = CURRENT_TIMESTAMP
      RETURNING 
        id,
        estudiante_id as "estudianteId",
        materia_id as "materiaId",
        grado_id as "gradoId",
        docente_id as "docenteId",
        periodo,
        nota_final as "notaFinal",
        nota_manual as "notaManual",
        usar_nota_manual as "usarNotaManual",
        ano_academico as "anoAcademico",
        observaciones,
        fecha_registro as "fechaRegistro",
        fecha_actualizacion as "fechaActualizacion"`,
      [
        data.estudianteId,
        data.materiaId,
        data.gradoId,
        data.docenteId,
        data.periodo,
        data.anoAcademico,
        data.notaManual,
        data.observaciones || null
      ]
    );
    return rows[0];
  }

  async getGrades(filters: {
    materiaId: number;
    gradoId: number;
    periodo: number;
    anoAcademico: number;
  }): Promise<Grade[]> {
    const { rows } = await query<any>(
      `SELECT 
        id,
        estudiante_id as "estudianteId",
        materia_id as "materiaId",
        grado_id as "gradoId",
        docente_id as "docenteId",
        periodo,
        nota_final as "notaFinal",
        nota_manual as "notaManual",
        usar_nota_manual as "usarNotaManual",
        ano_academico as "anoAcademico",
        observaciones,
        fecha_registro as "fechaRegistro",
        fecha_actualizacion as "fechaActualizacion"
      FROM calificaciones
      WHERE materia_id = $1
        AND grado_id = $2
        AND periodo = $3
        AND ano_academico = $4
      ORDER BY estudiante_id`,
      [filters.materiaId, filters.gradoId, filters.periodo, filters.anoAcademico]
    );
    return rows;
  }

  async getStudentGrade(
    estudianteId: number,
    materiaId: number,
    gradoId: number,
    periodo: number,
    anoAcademico: number
  ): Promise<Grade | null> {
    const { rows } = await query<any>(
      `SELECT 
        id,
        estudiante_id as "estudianteId",
        materia_id as "materiaId",
        grado_id as "gradoId",
        docente_id as "docenteId",
        periodo,
        nota_final as "notaFinal",
        nota_manual as "notaManual",
        usar_nota_manual as "usarNotaManual",
        ano_academico as "anoAcademico",
        observaciones,
        fecha_registro as "fechaRegistro",
        fecha_actualizacion as "fechaActualizacion"
      FROM calificaciones
      WHERE estudiante_id = $1
        AND materia_id = $2
        AND grado_id = $3
        AND periodo = $4
        AND ano_academico = $5`,
      [estudianteId, materiaId, gradoId, periodo, anoAcademico]
    );
    return rows[0] || null;
  }
}
