import { Estudiante } from "../entities/Estudiante";

export interface EstudiantesRepository {
  create(student: Omit<Estudiante, "id" | "createdAt" | "updatedAt">): Promise<Estudiante>;
}
