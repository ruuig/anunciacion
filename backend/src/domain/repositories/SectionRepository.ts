import { Section } from "../entities/Section.js";

export interface SectionRepository {
  findByGradeId(gradeId: number): Promise<Section[]>;
}
