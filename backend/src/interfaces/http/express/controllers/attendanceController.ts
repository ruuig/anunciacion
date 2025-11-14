import { Request, Response, NextFunction } from "express";
import { query } from "../../../../config/database";

// Registrar entrada de un estudiante
export async function registerEntry(req: Request, res: Response, next: NextFunction) {
  try {
    const { codigo } = req.body; // Código QR del estudiante (ej: C762KYD)
    
    if (!codigo) {
      return res.status(400).json({ error: "El código es requerido" });
    }

    // Buscar estudiante por código
    const studentResult = await query(
      `SELECT id, nombre, grado_id FROM estudiantes WHERE codigo = $1`,
      [codigo]
    );

    if (studentResult.rows.length === 0) {
      return res.status(404).json({ error: "Estudiante no encontrado" });
    }

    const student = studentResult.rows[0];
    const today = new Date().toISOString().split('T')[0];

    // Registrar entrada
    // Si ya existe registro: actualiza hora_entrada y limpia hora_salida (permite re-entrada)
    // Si no existe: crea nuevo registro
    const result = await query(
      `INSERT INTO asistencia (estudiante_id, fecha, hora_entrada, hora_salida, estado)
       VALUES ($1, $2, NOW(), NULL, 'presente')
       ON CONFLICT (estudiante_id, fecha) 
       DO UPDATE SET hora_entrada = NOW(), hora_salida = NULL, estado = 'presente'
       RETURNING id, hora_entrada`,
      [student.id, today]
    );

    res.json({
      success: true,
      message: "Entrada registrada",
      student: {
        id: student.id,
        nombre: student.nombre,
        gradoId: student.grado_id,
        horaEntrada: result.rows[0].hora_entrada
      }
    });
  } catch (error) {
    next(error);
  }
}

// Registrar salida de un estudiante
export async function registerExit(req: Request, res: Response, next: NextFunction) {
  try {
    const { codigo } = req.body;
    
    if (!codigo) {
      return res.status(400).json({ error: "El código es requerido" });
    }

    // Buscar estudiante por código
    const studentResult = await query(
      `SELECT id, nombre, grado_id FROM estudiantes WHERE codigo = $1`,
      [codigo]
    );

    if (studentResult.rows.length === 0) {
      return res.status(404).json({ error: "Estudiante no encontrado" });
    }

    const student = studentResult.rows[0];
    const today = new Date().toISOString().split('T')[0];

    // Verificar si tiene registro de entrada hoy
    const existingResult = await query(
      `SELECT id, hora_entrada FROM asistencia 
       WHERE estudiante_id = $1 AND fecha = $2 AND hora_entrada IS NOT NULL`,
      [student.id, today]
    );

    if (existingResult.rows.length === 0) {
      return res.status(400).json({ 
        error: "El estudiante no ha registrado entrada hoy",
        student: { id: student.id, nombre: student.nombre }
      });
    }

    // Registrar salida (actualiza la hora aunque ya haya salido antes)
    const result = await query(
      `UPDATE asistencia 
       SET hora_salida = NOW()
       WHERE estudiante_id = $1 AND fecha = $2
       RETURNING id, hora_salida`,
      [student.id, today]
    );

    res.json({
      success: true,
      message: "Salida registrada",
      student: {
        id: student.id,
        nombre: student.nombre,
        gradoId: student.grado_id,
        horaSalida: result.rows[0].hora_salida
      }
    });
  } catch (error) {
    next(error);
  }
}

// Obtener asistencia del día con filtros
export async function getTodayAttendance(req: Request, res: Response, next: NextFunction) {
  try {
    const { gradoId, nombre, tipo } = req.query; // tipo: 'entrada' o 'salida'
    const today = new Date().toISOString().split('T')[0];

    let sql = `
      SELECT 
        a.id,
        a.estudiante_id as "estudianteId",
        e.nombre,
        e.grado_id as "gradoId",
        g.nombre as "gradoNombre",
        a.hora_entrada as "horaEntrada",
        a.hora_salida as "horaSalida",
        a.estado
      FROM asistencia a
      INNER JOIN estudiantes e ON a.estudiante_id = e.id
      INNER JOIN grados g ON e.grado_id = g.id
      WHERE a.fecha = $1
    `;

    const params: any[] = [today];
    let paramIndex = 2;

    if (gradoId) {
      sql += ` AND e.grado_id = $${paramIndex}`;
      params.push(parseInt(gradoId as string));
      paramIndex++;
    }

    if (nombre) {
      sql += ` AND e.nombre ILIKE $${paramIndex}`;
      params.push(`%${nombre}%`);
      paramIndex++;
    }

    if (tipo === 'entrada') {
      // Solo mostrar estudiantes que entraron pero NO han salido (siguen en el colegio)
      sql += ` AND a.hora_entrada IS NOT NULL AND a.hora_salida IS NULL`;
    } else if (tipo === 'salida') {
      // Mostrar estudiantes que ya salieron
      sql += ` AND a.hora_salida IS NOT NULL`;
    }

    sql += ` ORDER BY a.hora_entrada DESC, a.hora_salida DESC`;

    const result = await query(sql, params);
    res.json(result.rows);
  } catch (error) {
    next(error);
  }
}

// Obtener estadísticas del día
export async function getTodayStats(req: Request, res: Response, next: NextFunction) {
  try {
    const today = new Date().toISOString().split('T')[0];

    // Total de estudiantes activos
    const totalResult = await query(
      `SELECT COUNT(*) as total FROM estudiantes WHERE estado = 'activo'`
    );

    // Estudiantes que están EN EL COLEGIO (tienen entrada pero NO salida)
    const inSchoolResult = await query(
      `SELECT COUNT(*) as in_school FROM asistencia 
       WHERE fecha = $1 AND hora_entrada IS NOT NULL AND hora_salida IS NULL`,
      [today]
    );

    // Estudiantes que salieron hoy
    const exitedResult = await query(
      `SELECT COUNT(*) as exited FROM asistencia 
       WHERE fecha = $1 AND hora_salida IS NOT NULL`,
      [today]
    );

    const total = parseInt(totalResult.rows[0].total);
    const inSchool = parseInt(inSchoolResult.rows[0].in_school);
    const exited = parseInt(exitedResult.rows[0].exited);

    res.json({
      total,           // Total de estudiantes activos
      entered: inSchool, // Estudiantes actualmente en el colegio
      exited,          // Estudiantes que ya salieron
      pending: total - inSchool - exited // Faltan por llegar
    });
  } catch (error) {
    next(error);
  }
}
