import { StudentRepository } from "../../domain/repositories/StudentRepository";
import { Student } from "../../domain/entities/Student";

export class CreateStudent {
  constructor(private readonly studentRepo: StudentRepository) {}

  async execute(input: {
    codigo: string;
    dpi: string;
    name: string;
    birthDate: string;
    gender?: string | null;
    address?: string | null;
    phone?: string | null;
    email?: string | null;
    gradeId: number;
  }): Promise<Student> {
    return this.studentRepo.create({
      codigo: input.codigo,
      dpi: input.dpi,
      name: input.name,
      birthDate: new Date(input.birthDate),
      gender: input.gender ?? null,
      address: input.address ?? null,
      phone: input.phone ?? null,
      email: input.email ?? null,
      avatarUrl: null,
      gradeId: input.gradeId,
      enrollmentDate: new Date(),
      status: "activo"
    });
  }
}
