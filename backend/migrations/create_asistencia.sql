-- Tabla de asistencia
-- Registra entrada y salida de estudiantes por día

CREATE TABLE IF NOT EXISTS asistencia (
    id SERIAL PRIMARY KEY,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_entrada TIMESTAMP,
    hora_salida TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'presente', -- 'presente', 'ausente', 'tarde'
    observaciones TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Un estudiante solo puede tener un registro de asistencia por día
    UNIQUE (estudiante_id, fecha)
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_asistencia_estudiante ON asistencia(estudiante_id);
CREATE INDEX IF NOT EXISTS idx_asistencia_fecha ON asistencia(fecha);
CREATE INDEX IF NOT EXISTS idx_asistencia_estado ON asistencia(estado);

-- Trigger para actualizar fecha_actualizacion
CREATE OR REPLACE FUNCTION update_asistencia_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_asistencia_timestamp
    BEFORE UPDATE ON asistencia
    FOR EACH ROW
    EXECUTE FUNCTION update_asistencia_timestamp();
