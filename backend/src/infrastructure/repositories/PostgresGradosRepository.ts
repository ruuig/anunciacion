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

  async create(grado: Partial<Grado>): Promise<Grado> {
    const { rows } = await query<any>(
      `INSERT INTO grados (nombre, nivel_educativo_id, rango_edad, ano_academico, activo)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING 
         id,
         nombre AS "name",
         nivel_educativo_id AS "educationalLevelId",
         rango_edad AS "ageRange",
         ano_academico AS "academicYear",
         activo AS "active",
         fecha_creacion AS "createdAt",
         fecha_actualizacion AS "updatedAt"`,
      [grado.name, grado.educationalLevelId, grado.ageRange, grado.academicYear, grado.active ?? true]
    );
    return rows[0];
  }

  async update(id: number, grado: Partial<Grado>): Promise<Grado> {
    const { rows } = await query<any>(
      `UPDATE grados 
       SET nombre = $1, 
           nivel_educativo_id = $2, 
           rango_edad = $3, 
           ano_academico = $4, 
           activo = $5,
           fecha_actualizacion = NOW()
       WHERE id = $6
       RETURNING 
         id,
         nombre AS "name",
         nivel_educativo_id AS "educationalLevelId",
         rango_edad AS "ageRange",
         ano_academico AS "academicYear",
         activo AS "active",
         fecha_creacion AS "createdAt",
         fecha_actualizacion AS "updatedAt"`,
      [grado.name, grado.educationalLevelId, grado.ageRange, grado.academicYear, grado.active, id]
    );
    return rows[0];
  }

  async delete(id: number): Promise<void> {
    await query(`DELETE FROM grados WHERE id = $1`, [id]);
  }
}
