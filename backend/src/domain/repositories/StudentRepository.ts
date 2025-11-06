import { Student } from "../entities/Student";

export interface StudentRepository {
  create(student: Omit<Student, "id" | "createdAt" | "updatedAt">): Promise<Student>;
  findByGradeAndSection(gradeId: number, sectionId?: number): Promise<Student[]>;
}
