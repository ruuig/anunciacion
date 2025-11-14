import { Request, Response } from 'express';
import { pool } from '../../../../config/database';

// Crear un nuevo pago
export const createPayment = async (req: Request, res: Response) => {
  const {
    estudiante_id,
    monto,
    mes,
    fecha_pago,
    metodo_pago,
    referencia,
    comprobante_url,
    notas,
    concepto_id,
  } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO pagos (
        estudiante_id, monto, mes, fecha_pago, metodo_pago, 
        referencia, comprobante_url, notas, estado, concepto_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'activo', $9)
      RETURNING *`,
      [
        estudiante_id,
        monto,
        mes,
        fecha_pago || new Date().toISOString().split('T')[0],
        metodo_pago,
        referencia,
        comprobante_url,
        notas,
        concepto_id || 1, // 1 = Mensualidad, 2 = Bus
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating payment:', error);
    res.status(500).json({ error: 'Error al crear el pago' });
  }
};

// Obtener todos los pagos con filtros opcionales
export const getPayments = async (req: Request, res: Response) => {
  const { estudiante_id, grado_id, mes, estado } = req.query;

  try {
    let query = `
      SELECT 
        p.*,
        e.nombre as estudiante_nombre,
        e.grado_id,
        g.nombre as grado_nombre
      FROM pagos p
      INNER JOIN estudiantes e ON p.estudiante_id = e.id
      LEFT JOIN grados g ON e.grado_id = g.id
      WHERE p.estado = $1
    `;
    const params: any[] = [estado || 'activo'];
    let paramIndex = 2;

    if (estudiante_id) {
      query += ` AND p.estudiante_id = $${paramIndex}`;
      params.push(estudiante_id);
      paramIndex++;
    }

    if (grado_id) {
      query += ` AND e.grado_id = $${paramIndex}`;
      params.push(grado_id);
      paramIndex++;
    }

    if (mes) {
      query += ` AND p.mes = $${paramIndex}`;
      params.push(mes);
      paramIndex++;
    }

    query += ' ORDER BY p.fecha_pago DESC, p.id DESC';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Error getting payments:', error);
    res.status(500).json({ error: 'Error al obtener los pagos' });
  }
};

// Obtener un pago por ID
export const getPaymentById = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `SELECT 
        p.*,
        e.nombre as estudiante_nombre,
        e.grado_id,
        g.nombre as grado_nombre
      FROM pagos p
      INNER JOIN estudiantes e ON p.estudiante_id = e.id
      LEFT JOIN grados g ON e.grado_id = g.id
      WHERE p.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pago no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error getting payment:', error);
    res.status(500).json({ error: 'Error al obtener el pago' });
  }
};

// Actualizar un pago
export const updatePayment = async (req: Request, res: Response) => {
  const { id } = req.params;
  const {
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
      `UPDATE pagos SET
        monto = COALESCE($1, monto),
        mes = COALESCE($2, mes),
        fecha_pago = COALESCE($3, fecha_pago),
        metodo_pago = COALESCE($4, metodo_pago),
        referencia = COALESCE($5, referencia),
        comprobante_url = COALESCE($6, comprobante_url),
        notas = COALESCE($7, notas),
        fecha_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $8 AND estado = 'activo'
      RETURNING *`,
      [monto, mes, fecha_pago, metodo_pago, referencia, comprobante_url, notas, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pago no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating payment:', error);
    res.status(500).json({ error: 'Error al actualizar el pago' });
  }
};

// Eliminar un pago (soft delete)
export const deletePayment = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `UPDATE pagos SET
        estado = 'eliminado',
        fecha_actualizacion = CURRENT_TIMESTAMP
      WHERE id = $1 AND estado = 'activo'
      RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pago no encontrado' });
    }

    res.json({ message: 'Pago eliminado correctamente', payment: result.rows[0] });
  } catch (error) {
    console.error('Error deleting payment:', error);
    res.status(500).json({ error: 'Error al eliminar el pago' });
  }
};

// Obtener estadísticas de pagos por grado
export const getPaymentStats = async (req: Request, res: Response) => {
  const { grado_id } = req.query;

  try {
    let query = `
      SELECT 
        COUNT(DISTINCT e.id) as total_estudiantes,
        COUNT(DISTINCT CASE WHEN p.id IS NOT NULL THEN e.id END) as estudiantes_con_pagos,
        COUNT(DISTINCT CASE WHEN p.id IS NULL THEN e.id END) as estudiantes_sin_pagos,
        COALESCE(SUM(p.monto), 0) as total_recaudado
      FROM estudiantes e
      LEFT JOIN pagos p ON e.id = p.estudiante_id AND p.estado = 'activo'
      WHERE e.estado = 'activo'
    `;
    const params: any[] = [];

    if (grado_id) {
      query += ' AND e.grado_id = $1';
      params.push(grado_id);
    }

    const result = await pool.query(query, params);
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error getting payment stats:', error);
    res.status(500).json({ error: 'Error al obtener estadísticas' });
  }
};

// Obtener historial de pagos de un estudiante
export const getStudentPaymentHistory = async (req: Request, res: Response) => {
  const { estudiante_id } = req.params;

  try {
    const result = await pool.query(
      `SELECT * FROM pagos
      WHERE estudiante_id = $1 AND estado = 'activo'
      ORDER BY fecha_pago DESC`,
      [estudiante_id]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error getting student payment history:', error);
    res.status(500).json({ error: 'Error al obtener historial de pagos' });
  }
};

export default {};
