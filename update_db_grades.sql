-- =====================================================
-- ACTUALIZACIÓN DE BASE DE DATOS - AGREGAR FUNCIONALIDAD DE CALIFICACIONES
-- =====================================================

-- 1. Agregar campo group_id a estudiantes (calculado como grado_id * 1000 + seccion_id)
ALTER TABLE estudiantes ADD COLUMN IF NOT EXISTS group_id INTEGER GENERATED ALWAYS AS (grado_id * 1000 + seccion_id) STORED;

-- 2. Crear tabla de periodos académicos
CREATE TABLE IF NOT EXISTS periodos_academicos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    ano_academico VARCHAR(9) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    orden INTEGER NOT NULL,
    activo BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(nombre, ano_academico)
);

-- 3. Crear tabla de calificaciones de estudiantes por materia y período
CREATE TABLE IF NOT EXISTS student_grades (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    subject_id INTEGER NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
    period_id INTEGER NOT NULL REFERENCES periodos_academicos(id) ON DELETE CASCADE,
    value DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, subject_id, period_id)
);

-- 4. Insertar datos de ejemplo para periodos académicos
INSERT INTO periodos_academicos (nombre, ano_academico, fecha_inicio, fecha_fin, orden)
VALUES
('Primer Trimestre', '2024', '2024-01-15', '2024-04-15', 1),
('Segundo Trimestre', '2024', '2024-04-16', '2024-07-15', 2),
('Tercer Trimestre', '2024', '2024-07-16', '2024-10-15', 3),
('Cuarto Trimestre', '2024', '2024-10-16', '2024-12-15', 4)
ON CONFLICT (nombre, ano_academico) DO NOTHING;

-- 5. Crear algunos datos de ejemplo para estudiantes (si no existen)
-- Nota: Ajusta estos IDs según los datos que tengas en tu base de datos

-- 6. Insertar algunas calificaciones de ejemplo (ajusta los IDs según tu base de datos)
-- INSERT INTO student_grades (student_id, subject_id, period_id, value)
-- VALUES
-- (1, 1, 1, 85.5),  -- Estudiante 1, Matemáticas, Primer Trimestre
-- (1, 2, 1, 92.0),  -- Estudiante 1, Español, Primer Trimestre
-- (2, 1, 1, 78.5),  -- Estudiante 2, Matemáticas, Primer Trimestre
-- (2, 2, 1, 88.0)   -- Estudiante 2, Español, Primer Trimestre
-- ON CONFLICT (student_id, subject_id, period_id) DO NOTHING;

COMMIT;
