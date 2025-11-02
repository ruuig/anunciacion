import { query } from "../../config/database";
import { EstudiantesRepository } from "../../domain/repositories/EstudiantesRepository";
import { Estudiante } from "../../domain/entities/Estudiante";

export class PostgresEstudiantesRepository implements EstudiantesRepository {
  async create(student: Omit<Estudiante, "id" | "createdAt" | "updatedAt">): Promise<Estudiante> {
    const { rows } = await query<any>(
      `INSERT INTO estudiantes (
        codigo,
        dpi,
        nombre,
        fecha_nacimiento,
        genero,
        direccion,
        telefono,
        email,
        url_avatar,
        grado_id,
        fecha_inscripcion,
        estado
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
      RETURNING
        id,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"`,
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

  async findAll(): Promise<Estudiante[]> {
    const { rows } = await query<any>(
      `SELECT 
        id,
        codigo,
        dpi,
        nombre AS name,
        fecha_nacimiento AS "birthDate",
        genero AS gender,
        direccion AS address,
        telefono AS phone,
        email,
        url_avatar AS "avatarUrl",
        grado_id AS "gradeId",
        fecha_inscripcion AS "enrollmentDate",
        estado AS status,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"
      FROM estudiantes
      ORDER BY nombre`
    );
    return rows;
  }

  async findById(id: number): Promise<Estudiante | null> {
    const { rows } = await query<any>(
      `SELECT 
        id,
        codigo,
        dpi,
        nombre AS name,
        fecha_nacimiento AS "birthDate",
        genero AS gender,
        direccion AS address,
        telefono AS phone,
        email,
        url_avatar AS "avatarUrl",
        grado_id AS "gradeId",
        fecha_inscripcion AS "enrollmentDate",
        estado AS status,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"
      FROM estudiantes
      WHERE id = $1`,
      [id]
    );
    return rows[0] || null;
  }

  async update(id: number, student: Estudiante): Promise<Estudiante> {
    const { rows } = await query<any>(
      `UPDATE estudiantes SET
        codigo = $1,
        dpi = $2,
        nombre = $3,
        fecha_nacimiento = $4,
        genero = $5,
        direccion = $6,
        telefono = $7,
        email = $8,
        url_avatar = $9,
        grado_id = $10,
        fecha_inscripcion = $11,
        estado = $12,
        fecha_actualizacion = NOW()
      WHERE id = $13
      RETURNING
        id,
        codigo,
        dpi,
        nombre AS name,
        fecha_nacimiento AS "birthDate",
        genero AS gender,
        direccion AS address,
        telefono AS phone,
        email,
        url_avatar AS "avatarUrl",
        grado_id AS "gradeId",
        fecha_inscripcion AS "enrollmentDate",
        estado AS status,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"`,
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
        student.status,
        id
      ]
    );
    return rows[0];
  }

  async delete(id: number): Promise<void> {
    await query("DELETE FROM estudiantes WHERE id = $1", [id]);
  }
}
