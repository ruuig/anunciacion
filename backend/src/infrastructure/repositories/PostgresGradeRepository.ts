import { query } from "../../config/database";
import { GradeRepository } from "../../domain/repositories/GradeRepository";
import { Grade } from "../../domain/entities/Grade";

export class PostgresGradeRepository implements GradeRepository {
  async findAll(): Promise<Grade[]> {
    const { rows } = await query<any>(
      "SELECT id, nombre as name, nivel_educativo_id as \"educationalLevelId\", rango_edad as \"ageRange\", ano_academico as \"academicYear\", activo as active, fecha_creacion as \"createdAt\", fecha_actualizacion as \"updatedAt\" FROM grados ORDER BY id"
    );
    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      educationalLevelId: row.educationalLevelId,
      ageRange: row.ageRange,
      academicYear: row.academicYear,
      active: row.active,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt
    }));
  }

  // Asignar docente a grado
  async assignTeacher(gradeId: number, teacherId: number, anoAcademico: string): Promise<void> {
    // Convertir anoAcademico a integer (ej: "2025" o "2024-2025" -> 2025)
    const year = parseInt(anoAcademico.includes('-') ? anoAcademico.split('-')[1] : anoAcademico);
    await query(
      `INSERT INTO grados_docentes (grado_id, docente_id, ano_academico, activo)
       VALUES ($1, $2, $3, true)
       ON CONFLICT (grado_id, docente_id, ano_academico)
       DO UPDATE SET activo = true`,
      [gradeId, teacherId, year]
    );
  }

  // Remover docente de grado
  async removeTeacher(gradeId: number, teacherId: number, anoAcademico: string): Promise<void> {
    // Convertir anoAcademico a integer (ej: "2025" o "2024-2025" -> 2025)
    const year = parseInt(anoAcademico.includes('-') ? anoAcademico.split('-')[1] : anoAcademico);
    await query(
      `DELETE FROM grados_docentes 
       WHERE grado_id = $1 AND docente_id = $2 AND ano_academico = $3`,
      [gradeId, teacherId, year]
    );
  }

  // Obtener docentes de un grado
  async getGradeTeachers(gradeId: number, anoAcademico: string): Promise<any[]> {
    // Convertir anoAcademico a integer (ej: "2025" o "2024-2025" -> 2025)
    const anoStr = String(anoAcademico);
    const year = parseInt(anoStr.includes('-') ? anoStr.split('-')[1] : anoStr);
    const { rows } = await query<any>(
      `SELECT u.id, u.nombre as name, u.telefono as phone
       FROM usuarios u
       INNER JOIN grados_docentes gd ON u.id = gd.docente_id
       WHERE gd.grado_id = $1 AND gd.ano_academico = $2 AND gd.activo = true
       ORDER BY u.nombre`,
      [gradeId, year]
    );
    return rows;
  }

  // Obtener grados asignados a un docente
  async getTeacherGrades(teacherId: number, anoAcademico: string): Promise<Grade[]> {
    // Convertir anoAcademico a integer (ej: "2025" o "2024-2025" -> 2025)
    const anoStr = String(anoAcademico);
    const year = parseInt(anoStr.includes('-') ? anoStr.split('-')[1] : anoStr);
    const { rows } = await query<any>(
      `SELECT g.id, g.nombre as name, g.nivel_educativo_id as "educationalLevelId", 
              g.rango_edad as "ageRange", gd.ano_academico as "academicYear", 
              g.activo as active, g.fecha_creacion as "createdAt", 
              g.fecha_actualizacion as "updatedAt"
       FROM grados g
       INNER JOIN grados_docentes gd ON g.id = gd.grado_id
       WHERE gd.docente_id = $1 AND gd.ano_academico = $2 AND gd.activo = true
       ORDER BY g.nombre`,
      [teacherId, year]
    );
    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      educationalLevelId: row.educationalLevelId,
      ageRange: row.ageRange,
      academicYear: row.academicYear,
      active: row.active,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt
    }));
  }
}
