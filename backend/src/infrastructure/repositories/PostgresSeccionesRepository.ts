import { query } from "../../config/database";
import { SeccionesRepository } from "../../domain/repositories/SeccionesRepository";
import { Seccion } from "../../domain/entities/Seccion";

export class PostgresSeccionesRepository implements SeccionesRepository {
  async findByGradeId(gradeId: number): Promise<Seccion[]> {
    const { rows } = await query<any>(
      `SELECT
         id,
         grado_id AS "gradeId",
         nombre AS "name",
         capacidad AS "capacity",
         cantidad_estudiantes AS "studentCount",
         activo AS "active",
         fecha_creacion AS "createdAt"
       FROM secciones
       WHERE grado_id = $1
       ORDER BY nombre`,
      [gradeId]
    );
    return rows;
  }

  async create(seccion: Partial<Seccion>): Promise<Seccion> {
    const { rows } = await query<any>(
      `INSERT INTO secciones (grado_id, nombre, capacidad, activo)
       VALUES ($1, $2, $3, $4)
       RETURNING 
         id,
         grado_id AS "gradeId",
         nombre AS "name",
         capacidad AS "capacity",
         cantidad_estudiantes AS "studentCount",
         activo AS "active",
         fecha_creacion AS "createdAt"`,
      [seccion.gradeId, seccion.name, seccion.capacity, seccion.active ?? true]
    );
    return rows[0];
  }

  async update(id: number, seccion: Partial<Seccion>): Promise<Seccion> {
    const { rows } = await query<any>(
      `UPDATE secciones 
       SET grado_id = $1, 
           nombre = $2, 
           capacidad = $3, 
           activo = $4
       WHERE id = $5
       RETURNING 
         id,
         grado_id AS "gradeId",
         nombre AS "name",
         capacidad AS "capacity",
         cantidad_estudiantes AS "studentCount",
         activo AS "active",
         fecha_creacion AS "createdAt"`,
      [seccion.gradeId, seccion.name, seccion.capacity, seccion.active, id]
    );
    return rows[0];
  }

  async delete(id: number): Promise<void> {
    await query(`DELETE FROM secciones WHERE id = $1`, [id]);
  }
}
