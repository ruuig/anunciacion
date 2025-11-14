-- Crear tabla de pagos
CREATE TABLE IF NOT EXISTS pagos (
  id SERIAL PRIMARY KEY,
  estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
  monto DECIMAL(10, 2) NOT NULL,
  mes VARCHAR(50) NOT NULL, -- Ej: "Enero 2025", "Febrero 2025"
  fecha_pago DATE NOT NULL DEFAULT CURRENT_DATE,
  metodo_pago VARCHAR(50), -- Ej: "Efectivo", "Transferencia", "Cheque"
  referencia VARCHAR(255), -- No. boleta, banco, nota, etc.
  comprobante_url VARCHAR(500), -- URL del comprobante si se sube
  estado VARCHAR(20) NOT NULL DEFAULT 'activo', -- 'activo', 'eliminado'
  notas TEXT,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  creado_por INTEGER REFERENCES usuarios(id),
  actualizado_por INTEGER REFERENCES usuarios(id)
);

-- Índices para mejorar rendimiento
CREATE INDEX idx_pagos_estudiante ON pagos(estudiante_id);
CREATE INDEX idx_pagos_fecha ON pagos(fecha_pago);
CREATE INDEX idx_pagos_mes ON pagos(mes);
CREATE INDEX idx_pagos_estado ON pagos(estado);

-- Comentarios descriptivos
COMMENT ON TABLE pagos IS 'Registro de pagos de mensualidades y otros conceptos';
COMMENT ON COLUMN pagos.estudiante_id IS 'ID del estudiante que realizó el pago';
COMMENT ON COLUMN pagos.monto IS 'Monto del pago en quetzales';
COMMENT ON COLUMN pagos.mes IS 'Mes o periodo al que corresponde el pago';
COMMENT ON COLUMN pagos.metodo_pago IS 'Método utilizado para el pago';
COMMENT ON COLUMN pagos.referencia IS 'Referencia del pago (boleta, banco, etc.)';
COMMENT ON COLUMN pagos.estado IS 'Estado del pago: activo o eliminado (soft delete)';
