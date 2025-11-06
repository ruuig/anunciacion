-- Tabla de calificaciones
-- Almacena las notas de los estudiantes por materia, grado y período
-- Permite nota manual o calculada automáticamente desde actividades

CREATE TABLE IF NOT EXISTS calificaciones (
    id SERIAL PRIMARY KEY,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    materia_id INTEGER NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
    grado_id INTEGER NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
    docente_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    periodo VARCHAR(50) NOT NULL, -- 'Primer Bimestre', 'Segundo Bimestre', etc.
    nota_final DECIMAL(5,2) CHECK (nota_final >= 0 AND nota_final <= 100),
    nota_manual DECIMAL(5,2) CHECK (nota_manual >= 0 AND nota_manual <= 100), -- Nota ingresada directamente
    usar_nota_manual BOOLEAN DEFAULT false, -- Si es true, usa nota_manual; si es false, calcula desde actividades
    ano_academico INTEGER NOT NULL, -- Solo el año: 2025, 2026, etc.
    observaciones TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Un estudiante solo puede tener una nota por materia, grado, período y año
    UNIQUE (estudiante_id, materia_id, grado_id, periodo, ano_academico)
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_calificaciones_estudiante ON calificaciones(estudiante_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_materia ON calificaciones(materia_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_grado ON calificaciones(grado_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_docente ON calificaciones(docente_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_ano ON calificaciones(ano_academico);
CREATE INDEX IF NOT EXISTS idx_calificaciones_periodo ON calificaciones(periodo);

-- Trigger para actualizar fecha_actualizacion
CREATE OR REPLACE FUNCTION update_calificaciones_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_calificaciones_timestamp
    BEFORE UPDATE ON calificaciones
    FOR EACH ROW
    EXECUTE FUNCTION update_calificaciones_timestamp();

-- ============================================
-- TABLA DE ACTIVIDADES
-- ============================================
-- Define las actividades/tareas que el docente crea para evaluar

CREATE TABLE IF NOT EXISTS actividades (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    materia_id INTEGER NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
    grado_id INTEGER NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
    docente_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    periodo VARCHAR(50) NOT NULL,
    ano_academico INTEGER NOT NULL,
    ponderacion DECIMAL(5,2) NOT NULL DEFAULT 100.00 CHECK (ponderacion > 0), -- Peso de la actividad (ej: 20%)
    fecha_entrega DATE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_actividades_materia ON actividades(materia_id);
CREATE INDEX IF NOT EXISTS idx_actividades_grado ON actividades(grado_id);
CREATE INDEX IF NOT EXISTS idx_actividades_docente ON actividades(docente_id);
CREATE INDEX IF NOT EXISTS idx_actividades_periodo ON actividades(periodo);

-- ============================================
-- TABLA DE CALIFICACIONES POR ACTIVIDAD
-- ============================================
-- Almacena la nota de cada estudiante en cada actividad

CREATE TABLE IF NOT EXISTS calificaciones_actividad (
    id SERIAL PRIMARY KEY,
    actividad_id INTEGER NOT NULL REFERENCES actividades(id) ON DELETE CASCADE,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    nota DECIMAL(5,2) NOT NULL CHECK (nota >= 0 AND nota <= 100),
    observaciones TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Un estudiante solo puede tener una nota por actividad
    UNIQUE (actividad_id, estudiante_id)
);

CREATE INDEX IF NOT EXISTS idx_calificaciones_actividad_actividad ON calificaciones_actividad(actividad_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_actividad_estudiante ON calificaciones_actividad(estudiante_id);

-- Trigger para actualizar fecha_actualizacion
CREATE OR REPLACE FUNCTION update_calificaciones_actividad_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_calificaciones_actividad_timestamp
    BEFORE UPDATE ON calificaciones_actividad
    FOR EACH ROW
    EXECUTE FUNCTION update_calificaciones_actividad_timestamp();

-- ============================================
-- FUNCIÓN PARA CALCULAR NOTA FINAL DESDE ACTIVIDADES
-- ============================================
-- Calcula el promedio ponderado de las actividades de un estudiante

CREATE OR REPLACE FUNCTION calcular_nota_desde_actividades(
    p_estudiante_id INTEGER,
    p_materia_id INTEGER,
    p_grado_id INTEGER,
    p_periodo VARCHAR,
    p_ano_academico INTEGER
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_nota_calculada DECIMAL(5,2);
BEGIN
    -- Calcular promedio ponderado
    SELECT 
        COALESCE(
            SUM(ca.nota * a.ponderacion) / NULLIF(SUM(a.ponderacion), 0),
            0
        )
    INTO v_nota_calculada
    FROM calificaciones_actividad ca
    INNER JOIN actividades a ON ca.actividad_id = a.id
    WHERE ca.estudiante_id = p_estudiante_id
      AND a.materia_id = p_materia_id
      AND a.grado_id = p_grado_id
      AND a.periodo = p_periodo
      AND a.ano_academico = p_ano_academico
      AND a.activo = true;
    
    RETURN ROUND(v_nota_calculada, 2);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGER PARA ACTUALIZAR NOTA_FINAL AUTOMÁTICAMENTE
-- ============================================
-- Cuando se inserta/actualiza una calificación de actividad,
-- recalcula la nota_final en la tabla calificaciones

CREATE OR REPLACE FUNCTION actualizar_nota_final_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_materia_id INTEGER;
    v_grado_id INTEGER;
    v_periodo VARCHAR;
    v_ano_academico INTEGER;
    v_docente_id INTEGER;
    v_nota_calculada DECIMAL(5,2);
BEGIN
    -- Obtener datos de la actividad
    SELECT materia_id, grado_id, periodo, ano_academico, docente_id
    INTO v_materia_id, v_grado_id, v_periodo, v_ano_academico, v_docente_id
    FROM actividades
    WHERE id = NEW.actividad_id;
    
    -- Calcular la nota desde actividades
    v_nota_calculada := calcular_nota_desde_actividades(
        NEW.estudiante_id,
        v_materia_id,
        v_grado_id,
        v_periodo,
        v_ano_academico
    );
    
    -- Insertar o actualizar en calificaciones (solo si NO usa nota manual)
    INSERT INTO calificaciones (
        estudiante_id, materia_id, grado_id, docente_id, periodo, 
        ano_academico, nota_final, usar_nota_manual
    )
    VALUES (
        NEW.estudiante_id, v_materia_id, v_grado_id, v_docente_id, v_periodo,
        v_ano_academico, v_nota_calculada, false
    )
    ON CONFLICT (estudiante_id, materia_id, grado_id, periodo, ano_academico)
    DO UPDATE SET
        nota_final = CASE 
            WHEN calificaciones.usar_nota_manual = false THEN v_nota_calculada
            ELSE calificaciones.nota_final
        END,
        fecha_actualizacion = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_nota_final
    AFTER INSERT OR UPDATE ON calificaciones_actividad
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_nota_final_trigger();

-- Datos de ejemplo (opcional)
-- INSERT INTO calificaciones (estudiante_id, materia_id, grado_id, docente_id, periodo, nota_manual, usar_nota_manual, ano_academico)
-- VALUES (1, 1, 1, 5, 'Primer Bimestre', 90.0, true, 2025);
