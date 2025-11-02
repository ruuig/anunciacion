import { query } from "../../config/database.js";
import { SectionRepository } from "../../domain/repositories/SectionRepository.js";
import { Section } from "../../domain/entities/Section.js";

export class PostgresSectionRepository implements SectionRepository {
  async findByGradeId(gradeId: number): Promise<Section[]> {
    const { rows } = await query<any>(
      "SELECT id, grado_id as \"gradeId\", nombre as name, capacidad as capacity, estudiantes_count as \"studentCount\", activo as active, fecha_creacion as \"createdAt\" FROM secciones WHERE grado_id = $1 ORDER BY nombre",
      [gradeId]
    );
    return rows.map((row) => ({
      id: row.id,
      gradeId: row.gradeId,
      name: row.name,
      capacity: row.capacity,
      studentCount: row.studentCount,
      active: row.active,
      createdAt: row.createdAt
    }));
  }
}
