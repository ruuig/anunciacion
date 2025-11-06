import { query } from "../../config/database";
import { ParentRepository } from "../../domain/repositories/ParentRepository";
import { Parent, ParentStudent } from "../../domain/entities/Parent";

export class PostgresParentRepository implements ParentRepository {
  async create(parent: Omit<Parent, "id" | "createdAt" | "updatedAt">): Promise<Parent> {
    const { rows } = await query<any>(
      `INSERT INTO padres (
        dpi, nombre, relacion, telefono, telefono_secundario, email, direccion, ocupacion,
        fecha_creacion, fecha_actualizacion
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW(),NOW())
      RETURNING 
        id,
        dpi,
        nombre,
        relacion,
        telefono,
        telefono_secundario AS "telefonoSecundario",
        email,
        direccion,
        ocupacion,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"`,
      [
        parent.dpi,
        parent.nombre,
        parent.relacion,
        parent.telefono,
        parent.telefonoSecundario,
        parent.email,
        parent.direccion,
        parent.ocupacion
      ]
    );
    return rows[0];
  }

  async findAll(): Promise<Parent[]> {
    const { rows } = await query<any>(
      `SELECT 
        id,
        dpi,
        nombre,
        relacion,
        telefono,
        telefono_secundario AS "telefonoSecundario",
        email,
        direccion,
        ocupacion,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"
      FROM padres
      ORDER BY nombre`
    );
    return rows;
  }

  async findById(id: number): Promise<Parent | null> {
    const { rows } = await query<any>(
      `SELECT 
        id,
        dpi,
        nombre,
        relacion,
        telefono,
        telefono_secundario AS "telefonoSecundario",
        email,
        direccion,
        ocupacion,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"
      FROM padres
      WHERE id = $1`,
      [id]
    );
    return rows[0] || null;
  }

  async update(id: number, parent: Parent): Promise<Parent> {
    const { rows } = await query<any>(
      `UPDATE padres SET
        dpi = $1,
        nombre = $2,
        relacion = $3,
        telefono = $4,
        telefono_secundario = $5,
        email = $6,
        direccion = $7,
        ocupacion = $8,
        fecha_actualizacion = NOW()
      WHERE id = $9
      RETURNING
        id,
        dpi,
        nombre,
        relacion,
        telefono,
        telefono_secundario AS "telefonoSecundario",
        email,
        direccion,
        ocupacion,
        fecha_creacion AS "createdAt",
        fecha_actualizacion AS "updatedAt"`,
      [
        parent.dpi,
        parent.nombre,
        parent.relacion,
        parent.telefono,
        parent.telefonoSecundario,
        parent.email,
        parent.direccion,
        parent.ocupacion,
        id
      ]
    );
    return rows[0];
  }

  async delete(id: number): Promise<void> {
    await query("DELETE FROM padres WHERE id = $1", [id]);
  }

  async assignStudent(parentId: number, studentId: number, isPrimary = false, isEmergency = false): Promise<ParentStudent> {
    const { rows } = await query<any>(
      `INSERT INTO estudiantes_padres (
        padre_id, estudiante_id, es_contacto_principal, es_contacto_emergencia, fecha_creacion
      ) VALUES ($1, $2, $3, $4, NOW())
      ON CONFLICT (padre_id, estudiante_id) 
      DO UPDATE SET
        es_contacto_principal = $3,
        es_contacto_emergencia = $4
      RETURNING
        id,
        padre_id AS "parentId",
        estudiante_id AS "studentId",
        es_contacto_principal AS "esContactoPrincipal",
        es_contacto_emergencia AS "esContactoEmergencia",
        fecha_creacion AS "createdAt"`,
      [parentId, studentId, isPrimary, isEmergency]
    );
    return rows[0];
  }

  async removeStudent(parentId: number, studentId: number): Promise<void> {
    await query(
      "DELETE FROM estudiantes_padres WHERE padre_id = $1 AND estudiante_id = $2",
      [parentId, studentId]
    );
  }

  async getStudentsByParent(parentId: number): Promise<number[]> {
    const { rows } = await query<any>(
      "SELECT estudiante_id FROM estudiantes_padres WHERE padre_id = $1",
      [parentId]
    );
    return rows.map((r: any) => r.estudiante_id);
  }

  async getParentsByStudent(studentId: number): Promise<Parent[]> {
    const { rows } = await query<any>(
      `SELECT 
        p.id,
        p.dpi,
        p.nombre,
        p.relacion,
        p.telefono,
        p.telefono_secundario AS "telefonoSecundario",
        p.email,
        p.direccion,
        p.ocupacion,
        p.fecha_creacion AS "createdAt",
        p.fecha_actualizacion AS "updatedAt"
      FROM padres p
      INNER JOIN estudiantes_padres ep ON p.id = ep.padre_id
      WHERE ep.estudiante_id = $1
      ORDER BY p.nombre`,
      [studentId]
    );
    return rows;
  }
}
