import { Parent, ParentStudent } from "../entities/Parent";

export interface ParentRepository {
  create(parent: Omit<Parent, "id" | "createdAt" | "updatedAt">): Promise<Parent>;
  findAll(): Promise<Parent[]>;
  findById(id: number): Promise<Parent | null>;
  update(id: number, parent: Parent): Promise<Parent>;
  delete(id: number): Promise<void>;
  
  // Relaciones con estudiantes
  assignStudent(parentId: number, studentId: number, isPrimary?: boolean, isEmergency?: boolean): Promise<ParentStudent>;
  removeStudent(parentId: number, studentId: number): Promise<void>;
  getStudentsByParent(parentId: number): Promise<number[]>;
  getParentsByStudent(studentId: number): Promise<Parent[]>;
}
