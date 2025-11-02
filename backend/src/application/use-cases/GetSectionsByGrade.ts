import { SectionRepository } from "../../domain/repositories/SectionRepository.js";
import { Section } from "../../domain/entities/Section.js";

export class GetSectionsByGrade {
  constructor(private readonly sectionRepo: SectionRepository) {}

  async execute(gradeId: number): Promise<Section[]> {
    return this.sectionRepo.findByGradeId(gradeId);
  }
}
