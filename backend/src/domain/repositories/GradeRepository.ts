import { Grade } from "../entities/Grade.js";

export interface GradeRepository {
  findAll(): Promise<Grade[]>;
}
