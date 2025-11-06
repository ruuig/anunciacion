import { Grade } from "../entities/Grade";

export interface GradeRepository {
  findAll(): Promise<Grade[]>;
}
