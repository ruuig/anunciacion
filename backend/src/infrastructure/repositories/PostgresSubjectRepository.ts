import { query } from "../../config/database";
import { Subject, SubjectWithTeachers } from "../../domain/entities/Subject";

export class PostgresSubjectRepository {
  async findAll(): Promise<SubjectWithTeachers[]> {
    const { rows } = await query<any>(
      `SELECT 
        m.id,
        m.nombre,
        m.codigo,
        m.descripcion,
        m.activo,
        m.fecha_creacion as "createdAt",
        COALESCE(
          json_agg(
            json_build_object('id', u.id, 'nombre', u.nombre)
            ORDER BY u.nombre
          ) FILTER (WHERE u.id IS NOT NULL),
          '[]'
        ) as teachers
      FROM materias m
      LEFT JOIN materias_docentes md ON m.id = md.materia_id AND md.activo = true
      LEFT JOIN usuarios u ON md.docente_id = u.id
      GROUP BY m.id, m.nombre, m.codigo, m.descripcion, m.activo, m.fecha_creacion
      ORDER BY m.nombre`
    );
    return rows;
  }

  async findById(id: number): Promise<SubjectWithTeachers | null> {
    const { rows } = await query<any>(
      `SELECT 
        m.id,
        m.nombre,
        m.codigo,
        m.descripcion,
        m.activo,
        m.fecha_creacion as "createdAt",
        COALESCE(
          json_agg(
            json_build_object('id', u.id, 'nombre', u.nombre)
            ORDER BY u.nombre
          ) FILTER (WHERE u.id IS NOT NULL),
          '[]'
        ) as teachers
      FROM materias m
      LEFT JOIN materias_docentes md ON m.id = md.materia_id AND md.activo = true
      LEFT JOIN usuarios u ON md.docente_id = u.id
      WHERE m.id = $1
      GROUP BY m.id, m.nombre, m.codigo, m.descripcion, m.activo, m.fecha_creacion`,
      [id]
    );
    return rows[0] || null;
  }

  async create(data: {
    nombre: string;
    codigo?: string | null;
    descripcion?: string | null;
  }): Promise<Subject> {
    const { rows } = await query<any>(
      `INSERT INTO materias (nombre, codigo, descripcion, activo)
       VALUES ($1, $2, $3, true)
       RETURNING 
         id,
         nombre,
         codigo,
         descripcion,
         activo,
         fecha_creacion as "createdAt"`,
      [data.nombre, data.codigo || null, data.descripcion || null]
    );
    return rows[0];
  }

  async update(
    id: number,
    data: {
      nombre?: string;
      codigo?: string | null;
      descripcion?: string | null;
      activo?: boolean;
    }
  ): Promise<Subject> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (data.nombre !== undefined) {
      fields.push(`nombre = $${paramIndex++}`);
      values.push(data.nombre);
    }
    if (data.codigo !== undefined) {
      fields.push(`codigo = $${paramIndex++}`);
      values.push(data.codigo);
    }
    if (data.descripcion !== undefined) {
      fields.push(`descripcion = $${paramIndex++}`);
      values.push(data.descripcion);
    }
    if (data.activo !== undefined) {
      fields.push(`activo = $${paramIndex++}`);
      values.push(data.activo);
    }

    values.push(id);

    const { rows } = await query<any>(
      `UPDATE materias
       SET ${fields.join(", ")}
       WHERE id = $${paramIndex}
       RETURNING 
         id,
         nombre,
         codigo,
         descripcion,
         activo,
         fecha_creacion as "createdAt"`,
      values
    );
    return rows[0];
  }

  async delete(id: number): Promise<void> {
    await query("DELETE FROM materias WHERE id = $1", [id]);
  }

  // Asignar docente a materia
  async assignTeacher(subjectId: number, teacherId: number): Promise<void> {
    await query(
      `INSERT INTO materias_docentes (materia_id, docente_id, activo)
       VALUES ($1, $2, true)
       ON CONFLICT (materia_id, docente_id) 
       DO UPDATE SET activo = true`,
      [subjectId, teacherId]
    );
  }

  // Remover docente de materia
  async removeTeacher(subjectId: number, teacherId: number): Promise<void> {
    await query(
      `DELETE FROM materias_docentes 
       WHERE materia_id = $1 AND docente_id = $2`,
      [subjectId, teacherId]
    );
  }

  // Obtener docentes de una materia
  async getTeachersBySubject(subjectId: number): Promise<any[]> {
    const { rows } = await query<any>(
      `SELECT u.id, u.nombre, u.telefono, u.email
       FROM usuarios u
       INNER JOIN materias_docentes md ON u.id = md.docente_id
       WHERE md.materia_id = $1 AND md.activo = true
       ORDER BY u.nombre`,
      [subjectId]
    );
    return rows;
  }

  // Asignar materia y docente a un grado
  async assignToGrade(data: {
    gradeId: number;
    subjectId: number;
    teacherId: number;
    anoAcademico: string;
  }): Promise<void> {
    await query(
      `INSERT INTO grados_materias_docentes (grado_id, materia_id, docente_id, ano_academico, activo)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (grado_id, materia_id, ano_academico)
       DO UPDATE SET docente_id = $3, activo = true`,
      [data.gradeId, data.subjectId, data.teacherId, data.anoAcademico]
    );
  }

  // Obtener materias y docentes de un grado
  async getGradeSubjects(gradeId: number, anoAcademico: string): Promise<any[]> {
    const { rows } = await query<any>(
      `SELECT 
        gmd.id,
        m.id as "subjectId",
        m.nombre as "subjectName",
        u.id as "teacherId",
        u.nombre as "teacherName"
       FROM grados_materias_docentes gmd
       INNER JOIN materias m ON gmd.materia_id = m.id
       INNER JOIN usuarios u ON gmd.docente_id = u.id
       WHERE gmd.grado_id = $1 AND gmd.ano_academico = $2 AND gmd.activo = true
       ORDER BY m.nombre`,
      [gradeId, anoAcademico]
    );
    return rows;
  }

  // Remover materia de un grado
  async removeFromGrade(gradeId: number, subjectId: number, anoAcademico: string): Promise<void> {
    await query(
      `DELETE FROM grados_materias_docentes 
       WHERE grado_id = $1 AND materia_id = $2 AND ano_academico = $3`,
      [gradeId, subjectId, anoAcademico]
    );
  }
}
