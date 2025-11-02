import { query } from "../../config/database";
import { GradosRepository } from "../../domain/repositories/GradosRepository";
import { Grado } from "../../domain/entities/Grado";

export class PostgresGradosRepository implements GradosRepository {
  async findAll(): Promise<Grado[]> {
    const { rows } = await query<any>(
      `SELECT
         id,
         nombre AS "name",
         nivel_educativo_id AS "educationalLevelId",
         rango_edad AS "ageRange",
         ano_academico AS "academicYear",
         activo AS "active",
         fecha_creacion AS "createdAt",
         fecha_actualizacion AS "updatedAt"
       FROM grados
       ORDER BY id`
    );
    return rows;
  }
}
