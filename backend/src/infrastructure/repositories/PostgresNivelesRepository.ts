import { query } from "../../config/database";
import { NivelesRepository } from "../../domain/repositories/NivelesRepository";
import { NivelEducativo } from "../../domain/entities/NivelEducativo";

export class PostgresNivelesRepository implements NivelesRepository {
  async findAll(): Promise<NivelEducativo[]> {
    const { rows } = await query<any>(
      `SELECT
         id,
         nombre AS "name",
         orden AS "order",
         color_hex AS "colorHex",
         activo AS "active"
       FROM niveles_educativos
       ORDER BY orden`
    );
    return rows;
  }
}
