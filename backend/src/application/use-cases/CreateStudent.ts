import { StudentRepository } from "../../domain/repositories/StudentRepository.js";
import { Student } from "../../domain/entities/Student.js";

export class CreateStudent {
  constructor(private readonly studentRepo: StudentRepository) {}

  async execute(input: {
    dpi: string;
    name: string;
    birthDate: string;
    gender?: string | null;
    address?: string | null;
    phone?: string | null;
    email?: string | null;
    gradeId: number;
    sectionId: number;
  }): Promise<Student> {
    const now = new Date();
    return this.studentRepo.create({
      id: 0,
      dpi: input.dpi,
      name: input.name,
      birthDate: new Date(input.birthDate),
      gender: input.gender ?? null,
      address: input.address ?? null,
      phone: input.phone ?? null,
      email: input.email ?? null,
      avatarUrl: null,
      gradeId: input.gradeId,
      sectionId: input.sectionId,
      enrollmentDate: now,
      status: "activo",
      createdAt: now,
      updatedAt: now
    });
  }
}
