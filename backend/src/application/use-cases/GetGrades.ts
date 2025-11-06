import { GradeRepository } from "../../domain/repositories/GradeRepository";
import { Grade } from "../../domain/entities/Grade";

export class GetGrades {
  constructor(private readonly gradeRepo: GradeRepository) {}

  async execute(): Promise<Grade[]> {
    return this.gradeRepo.findAll();
  }
}
