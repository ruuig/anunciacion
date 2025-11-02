import { EstudiantesRepository } from "../../domain/repositories/EstudiantesRepository";

export class CreateEstudiante {
  constructor(private readonly repo: EstudiantesRepository) {}

  async execute(input: {
    codigo: string;
    dpi: string;
    name: string;
    birthDate: string;
    gender?: string | null;
    address?: string | null;
    phone?: string | null;
    email?: string | null;
    avatarUrl?: string | null;
    gradeId: number;
    enrollmentDate?: string;
    status?: string;
  }) {
    const enrollment = input.enrollmentDate ? new Date(input.enrollmentDate) : new Date();

    return this.repo.create({
      codigo: input.codigo,
      dpi: input.dpi,
      name: input.name,
      birthDate: new Date(input.birthDate),
      gender: input.gender ?? null,
      address: input.address ?? null,
      phone: input.phone ?? null,
      email: input.email ?? null,
      avatarUrl: input.avatarUrl ?? null,
      gradeId: input.gradeId,
      enrollmentDate: enrollment,
      status: input.status ?? "activo"
    });
  }
}
