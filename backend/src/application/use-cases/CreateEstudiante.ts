import { EstudiantesRepository } from "../../domain/repositories/EstudiantesRepository";

export class CreateEstudiante {
  constructor(private readonly repo: EstudiantesRepository) {}

  async execute(input: {
    name: string;
    birthDate: string;
    gender?: string | null;
    address?: string | null;
    phone?: string | null;
    email?: string | null;
    gradeId: number;
    sectionId: number;
    enrollmentDate?: string;
  }) {
    const now = new Date();
    const enrollment = input.enrollmentDate ? new Date(input.enrollmentDate) : now;

    return this.repo.create({
      id: 0,
      name: input.name,
      birthDate: new Date(input.birthDate),
      gender: input.gender ?? null,
      address: input.address ?? null,
      phone: input.phone ?? null,
      email: input.email ?? null,
      avatarUrl: null,
      gradeId: input.gradeId,
      sectionId: input.sectionId,
      enrollmentDate: enrollment,
      status: "activo",
      createdAt: now,
      updatedAt: now
    });
  }
}
