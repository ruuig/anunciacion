import { query } from "../../config/database.js";
import { GradeRepository } from "../../domain/repositories/GradeRepository.js";
import { Grade } from "../../domain/entities/Grade.js";

export class PostgresGradeRepository implements GradeRepository {
  async findAll(): Promise<Grade[]> {
    const { rows } = await query<any>(
      "SELECT id, nombre as name, nivel_educativo_id as \"educationalLevelId\", rango_edad as \"ageRange\", anio_academico as \"academicYear\", activo as active, fecha_creacion as \"createdAt\", fecha_actualizacion as \"updatedAt\" FROM grados ORDER BY id"
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
