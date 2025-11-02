import { ParentRepository } from "../../domain/repositories/ParentRepository";

export class UpdateParent {
  constructor(private readonly repo: ParentRepository) {}

  async execute(id: number, input: {
    dpi?: string | null;
    nombre?: string;
    relacion?: string;
    telefono?: string;
    telefonoSecundario?: string | null;
    email?: string | null;
    direccion?: string | null;
    ocupacion?: string | null;
  }) {
    const existing = await this.repo.findById(id);
    if (!existing) {
      throw new Error("Padre no encontrado");
    }

    const updated = {
      ...existing,
      dpi: input.dpi !== undefined ? input.dpi : existing.dpi,
      nombre: input.nombre ?? existing.nombre,
      relacion: input.relacion ?? existing.relacion,
      telefono: input.telefono ?? existing.telefono,
      telefonoSecundario: input.telefonoSecundario !== undefined ? input.telefonoSecundario : existing.telefonoSecundario,
      email: input.email !== undefined ? input.email : existing.email,
      direccion: input.direccion !== undefined ? input.direccion : existing.direccion,
      ocupacion: input.ocupacion !== undefined ? input.ocupacion : existing.ocupacion,
    };

    return this.repo.update(id, updated);
  }
}
