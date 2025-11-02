import { EstudiantesRepository } from "../../domain/repositories/EstudiantesRepository";

export class UpdateEstudiante {
  constructor(private readonly repo: EstudiantesRepository) {}

  async execute(id: number, input: {
    codigo?: string;
    dpi?: string;
    name?: string;
    birthDate?: string;
    gender?: string | null;
    address?: string | null;
    phone?: string | null;
    email?: string | null;
    avatarUrl?: string | null;
    gradeId?: number;
    enrollmentDate?: string;
    status?: string;
  }) {
    const existing = await this.repo.findById(id);
    if (!existing) {
      throw new Error("Estudiante no encontrado");
    }

    const updated = {
      ...existing,
      codigo: input.codigo ?? existing.codigo,
      dpi: input.dpi ?? existing.dpi,
      name: input.name ?? existing.name,
      birthDate: input.birthDate ? new Date(input.birthDate) : existing.birthDate,
      gender: input.gender !== undefined ? input.gender : existing.gender,
      address: input.address !== undefined ? input.address : existing.address,
      phone: input.phone !== undefined ? input.phone : existing.phone,
      email: input.email !== undefined ? input.email : existing.email,
      avatarUrl: input.avatarUrl !== undefined ? input.avatarUrl : existing.avatarUrl,
      gradeId: input.gradeId ?? existing.gradeId,
      enrollmentDate: input.enrollmentDate ? new Date(input.enrollmentDate) : existing.enrollmentDate,
      status: input.status ?? existing.status,
    };

    return this.repo.update(id, updated);
  }
}
