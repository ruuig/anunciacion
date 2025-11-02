import { query } from "../../config/database.js";
import { StudentRepository } from "../../domain/repositories/StudentRepository.js";
import { Student } from "../../domain/entities/Student.js";

export class PostgresStudentRepository implements StudentRepository {
  async create(student: Omit<Student, "id">): Promise<Student> {
    const { rows } = await query<any>(
      `INSERT INTO estudiantes (
        dpi, nombre, fecha_nacimiento, genero, direccion, telefono, email, url_avatar,
        grado_id, seccion_id, fecha_inscripcion, estado, fecha_creacion, fecha_actualizacion
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,NOW(),NOW())
      RETURNING id, fecha_creacion as "createdAt", fecha_actualizacion as "updatedAt"`,
      [
        student.dpi,
        student.name,
        student.birthDate,
        student.gender,
        student.address,
        student.phone,
        student.email,
        student.avatarUrl,
        student.gradeId,
        student.sectionId,
        student.enrollmentDate,
        student.status
      ]
    );

    return {
      ...student,
      id: rows[0].id,
      createdAt: rows[0].createdAt,
      updatedAt: rows[0].updatedAt
    };
  }

  async findByGradeAndSection(gradeId: number, sectionId?: number): Promise<Student[]> {
    const params: any[] = [gradeId];
    let sql = `SELECT
      id, dpi, nombre as name, fecha_nacimiento as "birthDate", genero, direccion, telefono, email, url_avatar as "avatarUrl",
      grado_id as "gradeId", seccion_id as "sectionId", fecha_inscripcion as "enrollmentDate",
      estado as status, fecha_creacion as "createdAt", fecha_actualizacion as "updatedAt"
      FROM estudiantes WHERE grado_id = $1`;

    if (sectionId) {
      sql += " AND seccion_id = $2";
      params.push(sectionId);
    }

    const { rows } = await query<any>(sql, params);

    return rows.map((row) => ({
      id: row.id,
      dpi: row.dpi,
      name: row.name,
      birthDate: row.birthDate,
      gender: row.gender,
      address: row.direccion ?? row.address,
      phone: row.telefono,
      email: row.email,
      avatarUrl: row.avatarUrl,
      gradeId: row.gradeId,
      sectionId: row.sectionId,
      enrollmentDate: row.enrollmentDate,
      status: row.status,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt
    }));
  }
}
