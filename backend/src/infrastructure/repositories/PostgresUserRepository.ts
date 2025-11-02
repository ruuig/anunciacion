import { query } from "../../config/database";
import { UserRepository } from "../../domain/repositories/UserRepository";
import { User } from "../../domain/entities/User";

export class PostgresUserRepository implements UserRepository {
  async findByUsername(username: string): Promise<User | null> {
    const { rows } = await query<any>(
      `SELECT
         u.id,
         u.nombre AS "name",
         u.username,
         u.password,
         u.telefono AS "phone",
         u.rol_id AS "roleId",
         u.estado AS "status",
         u.url_avatar AS "avatarUrl",
         u.ultimo_acceso AS "lastAccess",
         u.fecha_creacion AS "createdAt",
         u.fecha_actualizacion AS "updatedAt"
       FROM usuarios u
       WHERE u.username = $1`,
      [username]
    );
    return rows[0] ?? null;
  }

  async findById(id: number): Promise<User | null> {
    const { rows } = await query<any>(
      `SELECT
         u.id,
         u.nombre AS "name",
         u.username,
         u.telefono AS "phone",
         u.rol_id AS "roleId",
         u.estado AS "status",
         u.url_avatar AS "avatarUrl",
         u.ultimo_acceso AS "lastAccess",
         u.fecha_creacion AS "createdAt",
         u.fecha_actualizacion AS "updatedAt"
       FROM usuarios u
       WHERE u.id = $1`,
      [id]
    );
    return rows[0] ?? null;
  }

  async updateLastAccess(id: number): Promise<void> {
    await query(
      `UPDATE usuarios
       SET ultimo_acceso = NOW(),
           fecha_actualizacion = NOW()
       WHERE id = $1`,
      [id]
    );
  }

  async findAll(): Promise<User[]> {
    const { rows } = await query<any>(
      `SELECT
         u.id,
         u.nombre AS "name",
         u.username,
         u.telefono AS "phone",
         u.rol_id AS "roleId",
         u.estado AS "status",
         u.url_avatar AS "avatarUrl",
         u.ultimo_acceso AS "lastAccess",
         u.fecha_creacion AS "createdAt",
         u.fecha_actualizacion AS "updatedAt"
       FROM usuarios u
       ORDER BY u.id DESC`
    );
    return rows;
  }

  async create(user: Omit<User, 'id' | 'createdAt' | 'updatedAt'>): Promise<User> {
    const { rows } = await query<any>(
      `INSERT INTO usuarios (nombre, username, password, telefono, rol_id, estado, url_avatar)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING
         id,
         nombre AS "name",
         username,
         telefono AS "phone",
         rol_id AS "roleId",
         estado AS "status",
         url_avatar AS "avatarUrl",
         ultimo_acceso AS "lastAccess",
         fecha_creacion AS "createdAt",
         fecha_actualizacion AS "updatedAt"`,
      [
        user.name,
        user.username,
        user.password,
        user.phone || null,
        user.roleId,
        user.status || 'activo',
        user.avatarUrl || null
      ]
    );
    return rows[0];
  }

  async update(id: number, user: Partial<User>): Promise<User> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (user.name !== undefined) {
      fields.push(`nombre = $${paramIndex++}`);
      values.push(user.name);
    }
    if (user.username !== undefined) {
      fields.push(`username = $${paramIndex++}`);
      values.push(user.username);
    }
    if (user.password !== undefined) {
      fields.push(`password = $${paramIndex++}`);
      values.push(user.password);
    }
    if (user.phone !== undefined) {
      fields.push(`telefono = $${paramIndex++}`);
      values.push(user.phone);
    }
    if (user.roleId !== undefined) {
      fields.push(`rol_id = $${paramIndex++}`);
      values.push(user.roleId);
    }
    if (user.status !== undefined) {
      fields.push(`estado = $${paramIndex++}`);
      values.push(user.status);
    }
    if (user.avatarUrl !== undefined) {
      fields.push(`url_avatar = $${paramIndex++}`);
      values.push(user.avatarUrl);
    }

    fields.push(`fecha_actualizacion = NOW()`);
    values.push(id);

    const { rows } = await query<any>(
      `UPDATE usuarios
       SET ${fields.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING
         id,
         nombre AS "name",
         username,
         telefono AS "phone",
         rol_id AS "roleId",
         estado AS "status",
         url_avatar AS "avatarUrl",
         ultimo_acceso AS "lastAccess",
         fecha_creacion AS "createdAt",
         fecha_actualizacion AS "updatedAt"`,
      values
    );
    return rows[0];
  }

  async delete(id: number): Promise<void> {
    await query(
      `DELETE FROM usuarios WHERE id = $1`,
      [id]
    );
  }
}
