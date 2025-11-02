import { Estudiante } from "../entities/Estudiante";

export interface EstudiantesRepository {
  create(student: Omit<Estudiante, "id" | "createdAt" | "updatedAt">): Promise<Estudiante>;
  findAll(): Promise<Estudiante[]>;
  findById(id: number): Promise<Estudiante | null>;
  update(id: number, student: Estudiante): Promise<Estudiante>;
  delete(id: number): Promise<void>;
}
