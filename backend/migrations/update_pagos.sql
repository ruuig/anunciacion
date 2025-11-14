-- Agregar columnas faltantes a la tabla pagos
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS mes VARCHAR(50);
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(50);
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS referencia VARCHAR(255);
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS comprobante_url VARCHAR(500);
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS notas TEXT;
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS creado_por INTEGER REFERENCES usuarios(id);
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS actualizado_por INTEGER REFERENCES usuarios(id);

-- Eliminar índices existentes y recrearlos
DROP INDEX IF EXISTS idx_pagos_estudiante;
DROP INDEX IF EXISTS idx_pagos_fecha;
DROP INDEX IF EXISTS idx_pagos_mes;
DROP INDEX IF EXISTS idx_pagos_estado;

-- Crear índices
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
