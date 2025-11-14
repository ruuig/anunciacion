-- Crear tabla de servicio de bus
CREATE TABLE IF NOT EXISTS servicio_bus (
  id SERIAL PRIMARY KEY,
  estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
  activo BOOLEAN NOT NULL DEFAULT true,
  monto_mensual DECIMAL(10, 2) NOT NULL DEFAULT 200.00,
  ruta VARCHAR(255),
  parada VARCHAR(255),
  notas TEXT,
  fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
  fecha_fin DATE,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  creado_por INTEGER REFERENCES usuarios(id),
  actualizado_por INTEGER REFERENCES usuarios(id),
  UNIQUE(estudiante_id)
);

-- Crear tabla de pagos de bus
CREATE TABLE IF NOT EXISTS pagos_bus (
  id SERIAL PRIMARY KEY,
  estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
  monto DECIMAL(10, 2) NOT NULL,
  mes VARCHAR(50) NOT NULL,
  fecha_pago DATE NOT NULL DEFAULT CURRENT_DATE,
  metodo_pago VARCHAR(50),
  referencia VARCHAR(255),
  comprobante_url VARCHAR(500),
  estado VARCHAR(20) NOT NULL DEFAULT 'activo',
  notas TEXT,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  creado_por INTEGER REFERENCES usuarios(id),
  actualizado_por INTEGER REFERENCES usuarios(id)
);

-- Índices para servicio_bus
CREATE INDEX idx_servicio_bus_estudiante ON servicio_bus(estudiante_id);
CREATE INDEX idx_servicio_bus_activo ON servicio_bus(activo);

-- Índices para pagos_bus
CREATE INDEX idx_pagos_bus_estudiante ON pagos_bus(estudiante_id);
CREATE INDEX idx_pagos_bus_fecha ON pagos_bus(fecha_pago);
CREATE INDEX idx_pagos_bus_mes ON pagos_bus(mes);
CREATE INDEX idx_pagos_bus_estado ON pagos_bus(estado);

-- Comentarios descriptivos
COMMENT ON TABLE servicio_bus IS 'Registro de estudiantes con servicio de bus activo';
COMMENT ON COLUMN servicio_bus.estudiante_id IS 'ID del estudiante';
COMMENT ON COLUMN servicio_bus.activo IS 'Si el servicio está activo o no';
COMMENT ON COLUMN servicio_bus.monto_mensual IS 'Monto mensual del servicio de bus';

COMMENT ON TABLE pagos_bus IS 'Registro de pagos de servicio de bus';
COMMENT ON COLUMN pagos_bus.estudiante_id IS 'ID del estudiante que realizó el pago';
COMMENT ON COLUMN pagos_bus.monto IS 'Monto del pago en quetzales';
COMMENT ON COLUMN pagos_bus.mes IS 'Mes o periodo al que corresponde el pago';
COMMENT ON COLUMN pagos_bus.estado IS 'Estado del pago: activo o eliminado (soft delete)';
