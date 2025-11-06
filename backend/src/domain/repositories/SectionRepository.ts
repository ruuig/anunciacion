import { Section } from "../entities/Section";

export interface SectionRepository {
  findByGradeId(gradeId: number): Promise<Section[]>;
}
