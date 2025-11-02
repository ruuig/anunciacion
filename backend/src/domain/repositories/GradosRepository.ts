import { Grado } from "../entities/Grado";

export interface GradosRepository {
  findAll(): Promise<Grado[]>;
}
