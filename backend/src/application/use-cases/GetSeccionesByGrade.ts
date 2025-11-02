import { SeccionesRepository } from "../../domain/repositories/SeccionesRepository";

export class GetSeccionesByGrade {
  constructor(private readonly repo: SeccionesRepository) {}

  async execute(gradeId: number) {
    return this.repo.findByGradeId(gradeId);
  }
}
