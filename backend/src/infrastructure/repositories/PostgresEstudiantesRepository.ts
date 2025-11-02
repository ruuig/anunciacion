import { query } from "../../config/database";
import { EstudiantesRepository } from "../../domain/repositories/EstudiantesRepository";
import { Estudiante } from "../../domain/entities/Estudiante";

export class PostgresEstudiantesRepository implements EstudiantesRepository {
  async create(student: Omit<Estudiante, "id" | "createdAt" | "updatedAt">): Promise<Estudiante> {
    const { rows } = await query<any>(
      `INSERT INTO estudiantes (
        nombre,
        fecha_nacimiento,
        genero,
        direccion,
        telefono,
        email,
        url_avatar,
        grado_id,
        seccion_id,
        fecha_inscripcion,
        estado
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
      RETURNING
        id,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"`,
      [
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
}
