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
}
