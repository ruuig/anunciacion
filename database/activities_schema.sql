-- Esquema y migraciones para gestionar actividades y calificaciones.
-- Ejecutar en PostgreSQL.

BEGIN;

-- Tabla de actividades académicas
CREATE TABLE IF NOT EXISTS actividades (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    docente_id INTEGER NOT NULL REFERENCES usuarios(id),
    materia_id INTEGER NOT NULL REFERENCES materias(id),
    grado_id INTEGER NOT NULL REFERENCES grados(id),
    seccion_id INTEGER NOT NULL REFERENCES secciones(id),
    periodo_id INTEGER NOT NULL REFERENCES periodos_academicos(id),
    tipo VARCHAR(30) NOT NULL,
    puntos_maximos DECIMAL(6,2) NOT NULL,
    estado VARCHAR(20) DEFAULT 'pendiente',
    fecha_programada DATE,
    fecha_entrega DATE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migraciones para asegurar columnas nuevas en instalaciones existentes
ALTER TABLE actividades
    ADD COLUMN IF NOT EXISTS fecha_programada DATE,
    ADD COLUMN IF NOT EXISTS fecha_entrega DATE,
    ADD COLUMN IF NOT EXISTS estado VARCHAR(20) DEFAULT 'pendiente';

-- Índices útiles para filtros en la aplicación
CREATE INDEX IF NOT EXISTS idx_actividades_grado ON actividades(grado_id);
CREATE INDEX IF NOT EXISTS idx_actividades_seccion ON actividades(seccion_id);
CREATE INDEX IF NOT EXISTS idx_actividades_materia ON actividades(materia_id);
CREATE INDEX IF NOT EXISTS idx_actividades_tipo ON actividades(tipo);

-- Tabla que almacena la calificación de cada estudiante por actividad
CREATE TABLE IF NOT EXISTS calificaciones_actividades (
    id SERIAL PRIMARY KEY,
    actividad_id INTEGER NOT NULL REFERENCES actividades(id) ON DELETE CASCADE,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    puntos_obtenidos DECIMAL(6,2),
    porcentaje_calificacion DECIMAL(6,2),
    comentarios TEXT,
    calificado_por INTEGER NOT NULL REFERENCES usuarios(id),
    fecha_calificacion TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (actividad_id, estudiante_id)
);

-- Asegurar columnas necesarias en instalaciones previas
ALTER TABLE calificaciones_actividades
    ADD COLUMN IF NOT EXISTS porcentaje_calificacion DECIMAL(6,2),
    ADD COLUMN IF NOT EXISTS comentarios TEXT,
    ADD COLUMN IF NOT EXISTS fecha_calificacion TIMESTAMP,
    ADD COLUMN IF NOT EXISTS fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_calificaciones_actividad
    ON calificaciones_actividades(actividad_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_estudiante
    ON calificaciones_actividades(estudiante_id);

-- Tabla que consolida la sumatoria de notas por materia/período
CREATE TABLE IF NOT EXISTS student_grades (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    subject_id INTEGER NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
    period_id INTEGER NOT NULL REFERENCES periodos_academicos(id) ON DELETE CASCADE,
    value DECIMAL(6,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id, subject_id, period_id)
);

COMMIT;
