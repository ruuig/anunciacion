import { query } from "../../config/database";
import { StudentRepository } from "../../domain/repositories/StudentRepository";
import { Student } from "../../domain/entities/Student";

export class PostgresStudentRepository implements StudentRepository {
  async create(student: Omit<Student, "id" | "createdAt" | "updatedAt">): Promise<Student> {
    const { rows } = await query<any>(
      `INSERT INTO estudiantes (
        codigo, dpi, nombre, fecha_nacimiento, genero, direccion, telefono, email, url_avatar,
        grado_id, fecha_inscripcion, estado, fecha_creacion, fecha_actualizacion
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,NOW(),NOW())
      RETURNING id, fecha_creacion as "createdAt", fecha_actualizacion as "updatedAt"`,
      [
        student.codigo,
        student.dpi,
        student.name,
        student.birthDate,
        student.gender,
        student.address,
        student.phone,
        student.email,
        student.avatarUrl,
        student.gradeId,
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

  async findAll(): Promise<Student[]> {
    const sql = `SELECT
      e.id, e.codigo, e.dpi, e.nombre as name, e.fecha_nacimiento as "birthDate", e.genero as gender, 
      e.direccion as address, e.telefono as phone, e.email, e.url_avatar as "avatarUrl",
      e.grado_id as "gradeId", e.fecha_inscripcion as "enrollmentDate",
      e.estado as status, e.fecha_creacion as "createdAt", e.fecha_actualizacion as "updatedAt",
      g.nombre as "gradeName"
      FROM estudiantes e
      LEFT JOIN grados g ON e.grado_id = g.id
      ORDER BY e.nombre`;

    const { rows } = await query<any>(sql);

    return rows.map((row) => ({
      id: row.id,
      codigo: row.codigo,
      dpi: row.dpi,
      name: row.name,
      birthDate: row.birthDate,
      gender: row.gender,
      address: row.address,
      phone: row.phone,
      email: row.email,
      avatarUrl: row.avatarUrl,
      gradeId: row.gradeId,
      gradeName: row.gradeName,
      enrollmentDate: row.enrollmentDate,
      status: row.status,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt
    }));
  }

  async findByGradeAndSection(gradeId: number, sectionId?: number): Promise<Student[]> {
    const params: any[] = [gradeId];
    let sql = `SELECT
      id, codigo, dpi, nombre as name, fecha_nacimiento as "birthDate", genero as gender, 
      direccion as address, telefono as phone, email, url_avatar as "avatarUrl",
      grado_id as "gradeId", fecha_inscripcion as "enrollmentDate",
      estado as status, fecha_creacion as "createdAt", fecha_actualizacion as "updatedAt"
      FROM estudiantes WHERE grado_id = $1`;

    // sectionId ya no se usa - las secciones están en el nombre del grado

    const { rows } = await query<any>(sql, params);

    return rows.map((row) => ({
      id: row.id,
      codigo: row.codigo,
      dpi: row.dpi,
      name: row.name,
      birthDate: row.birthDate,
      gender: row.gender,
      address: row.address,
      phone: row.phone,
      email: row.email,
      avatarUrl: row.avatarUrl,
      gradeId: row.gradeId,
      enrollmentDate: row.enrollmentDate,
      status: row.status,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt
    }));
  }
}
