import { SectionRepository } from "../../domain/repositories/SectionRepository";
import { Section } from "../../domain/entities/Section";

export class GetSectionsByGrade {
  constructor(private readonly sectionRepo: SectionRepository) {}

  async execute(gradeId: number): Promise<Section[]> {
    return this.sectionRepo.findByGradeId(gradeId);
  }
}
