import { Seccion } from "../entities/Seccion";

export interface SeccionesRepository {
  findByGradeId(gradeId: number): Promise<Seccion[]>;
}
