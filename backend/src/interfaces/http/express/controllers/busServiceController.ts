import { Request, Response } from 'express';
import { pool } from '../../../../config/database';

// Asignar servicio de bus a un estudiante
export const assignBusService = async (req: Request, res: Response) => {
  const {
    estudiante_id,
    monto_mensual,
    ruta,
    parada,
    notas,
  } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO servicio_bus (
        estudiante_id, monto_mensual, ruta, parada, notas, activo
      ) VALUES ($1, $2, $3, $4, $5, true)
      ON CONFLICT (estudiante_id) 
      DO UPDATE SET 
        activo = true,
        monto_mensual = $2,
        ruta = $3,
        parada = $4,
        notas = $5,
        fecha_actualizacion = CURRENT_TIMESTAMP
      RETURNING *`,
      [estudiante_id, monto_mensual || 200, ruta, parada, notas]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error assigning bus service:', error);
    res.status(500).json({ error: 'Error al asignar servicio de bus' });
  }
};

// Desactivar servicio de bus
export const deactivateBusService = async (req: Request, res: Response) => {
  const { estudiante_id } = req.params;

  try {
    const result = await pool.query(
      `UPDATE servicio_bus 
       SET activo = false, fecha_fin = CURRENT_DATE, fecha_actualizacion = CURRENT_TIMESTAMP
       WHERE estudiante_id = $1
       RETURNING *`,
      [estudiante_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Servicio de bus no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error deactivating bus service:', error);
    res.status(500).json({ error: 'Error al desactivar servicio de bus' });
  }
};

// Obtener estudiantes con servicio de bus
export const getBusStudents = async (req: Request, res: Response) => {
  const { activo, grado_id } = req.query;

  try {
    let query = `
      SELECT 
        sb.*,
        e.nombre,
        e.codigo,
        g.nombre as grado
      FROM servicio_bus sb
      JOIN estudiantes e ON sb.estudiante_id = e.id
      LEFT JOIN grados g ON e.grado_id = g.id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (activo !== undefined) {
      params.push(activo === 'true');
      query += ` AND sb.activo = $${params.length}`;
    }

    if (grado_id) {
      params.push(grado_id);
      query += ` AND e.grado_id = $${params.length}`;
    }

    query += ' ORDER BY e.nombre';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Error getting bus students:', error);
    res.status(500).json({ error: 'Error al obtener estudiantes con servicio de bus' });
  }
};

// Crear pago de bus
export const createBusPayment = async (req: Request, res: Response) => {
  const {
    estudiante_id,
    monto,
    mes,
    fecha_pago,
    metodo_pago,
    referencia,
    comprobante_url,
    notas,
  } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO pagos_bus (
        estudiante_id, monto, mes, fecha_pago, metodo_pago, 
        referencia, comprobante_url, notas, estado
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'activo')
      RETURNING *`,
      [
        estudiante_id,
        monto,
        mes,
        fecha_pago || new Date(),
        metodo_pago,
        referencia,
        comprobante_url,
        notas,
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating bus payment:', error);
    res.status(500).json({ error: 'Error al crear pago de bus' });
  }
};

// Obtener pagos de bus
export const getBusPayments = async (req: Request, res: Response) => {
  const { estudiante_id, mes, estado } = req.query;

  try {
    let query = `
      SELECT 
        pb.*,
        e.nombre as estudiante_nombre,
        e.codigo
      FROM pagos_bus pb
      JOIN estudiantes e ON pb.estudiante_id = e.id
      WHERE pb.estado != 'eliminado'
    `;
    const params: any[] = [];

    if (estudiante_id) {
      params.push(estudiante_id);
      query += ` AND pb.estudiante_id = $${params.length}`;
    }

    if (mes) {
      params.push(mes);
      query += ` AND pb.mes = $${params.length}`;
    }

    if (estado) {
      params.push(estado);
      query += ` AND pb.estado = $${params.length}`;
    }

    query += ' ORDER BY pb.fecha_pago DESC';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Error getting bus payments:', error);
    res.status(500).json({ error: 'Error al obtener pagos de bus' });
  }
};

// Eliminar pago de bus (soft delete)
export const deleteBusPayment = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `UPDATE pagos_bus 
       SET estado = 'eliminado', fecha_actualizacion = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pago de bus no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error deleting bus payment:', error);
    res.status(500).json({ error: 'Error al eliminar pago de bus' });
  }
};

export default {};
