import { ParentRepository } from "../../domain/repositories/ParentRepository";
import { PostgresUserRepository } from "../../infrastructure/repositories/PostgresUserRepository";

export class CreateParent {
  constructor(
    private readonly repo: ParentRepository,
    private readonly userRepo: PostgresUserRepository = new PostgresUserRepository()
  ) {}

  async execute(input: {
    dpi?: string | null;
    nombre: string;
    relacion: string;
    telefono: string;
    telefonoSecundario?: string | null;
    email?: string | null;
    direccion?: string | null;
    ocupacion?: string | null;
  }) {
    // Crear el padre
    const parent = await this.repo.create({
      dpi: input.dpi ?? null,
      nombre: input.nombre,
      relacion: input.relacion,
      telefono: input.telefono,
      telefonoSecundario: input.telefonoSecundario ?? null,
      email: input.email ?? null,
      direccion: input.direccion ?? null,
      ocupacion: input.ocupacion ?? null,
    });

    // Crear usuario automáticamente
    try {
      // Obtener el primer nombre
      const firstName = input.nombre.trim().split(' ')[0].toLowerCase();
      
      // Generar username único (primer nombre + ID del padre)
      const username = `${firstName}${parent.id}`;
      
      // Obtener el rol de "Padre" (roleId = 4 según el script de base de datos)
      const roleId = 4;
      
      // Verificar si el username ya existe
      const existingUser = await this.userRepo.findByUsername(username);
      
      if (!existingUser) {
        await this.userRepo.create({
          name: input.nombre,
          username: username,
          password: 'changeme1',
          phone: input.telefono,
          roleId: roleId,
          status: 'activo',
          avatarUrl: null
        });
        
        console.log(`Usuario creado automáticamente: ${username} para padre ${parent.nombre}`);
      } else {
        console.log(`Usuario ${username} ya existe, no se creó uno nuevo`);
      }
    } catch (error) {
      console.error('Error al crear usuario para padre:', error);
      // No lanzamos el error para que no falle la creación del padre
      // El padre se crea exitosamente aunque falle la creación del usuario
    }

    return parent;
  }
}
