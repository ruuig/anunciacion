import { GradeRepository } from "../../domain/repositories/GradeRepository.js";
import { Grade } from "../../domain/entities/Grade.js";

export class GetGrades {
  constructor(private readonly gradeRepo: GradeRepository) {}

  async execute(): Promise<Grade[]> {
    return this.gradeRepo.findAll();
  }
}
