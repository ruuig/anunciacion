-- Script para actualizar la tabla calificaciones existente
-- Agrega soporte para notas manuales y actividades

-- 1. Agregar nuevas columnas a calificaciones (si no existen)
ALTER TABLE calificaciones 
ADD COLUMN IF NOT EXISTS nota_manual DECIMAL(5,2) CHECK (nota_manual >= 0 AND nota_manual <= 100);

ALTER TABLE calificaciones 
ADD COLUMN IF NOT EXISTS usar_nota_manual BOOLEAN DEFAULT false;

-- Renombrar columna 'nota' a 'nota_final' si existe
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'calificaciones' AND column_name = 'nota'
    ) THEN
        ALTER TABLE calificaciones RENAME COLUMN nota TO nota_final;
    END IF;
END $$;

-- Agregar columna nota_final si no existe (por si acaso)
ALTER TABLE calificaciones 
ADD COLUMN IF NOT EXISTS nota_final DECIMAL(5,2) CHECK (nota_final >= 0 AND nota_final <= 100);

-- 2. Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS trigger_update_calificaciones_timestamp ON calificaciones;

-- Recrear el trigger
CREATE TRIGGER trigger_update_calificaciones_timestamp
    BEFORE UPDATE ON calificaciones
    FOR EACH ROW
    EXECUTE FUNCTION update_calificaciones_timestamp();

-- ============================================
-- 3. CREAR TABLA DE ACTIVIDADES
-- ============================================

CREATE TABLE IF NOT EXISTS actividades (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    materia_id INTEGER NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
    grado_id INTEGER NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
    docente_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    periodo VARCHAR(50) NOT NULL,
    ano_academico INTEGER NOT NULL,
    ponderacion DECIMAL(5,2) NOT NULL DEFAULT 100.00 CHECK (ponderacion > 0),
    fecha_entrega DATE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_actividades_materia ON actividades(materia_id);
CREATE INDEX IF NOT EXISTS idx_actividades_grado ON actividades(grado_id);
CREATE INDEX IF NOT EXISTS idx_actividades_docente ON actividades(docente_id);
CREATE INDEX IF NOT EXISTS idx_actividades_periodo ON actividades(periodo);

-- ============================================
-- 4. CREAR TABLA DE CALIFICACIONES POR ACTIVIDAD
-- ============================================

CREATE TABLE IF NOT EXISTS calificaciones_actividad (
    id SERIAL PRIMARY KEY,
    actividad_id INTEGER NOT NULL REFERENCES actividades(id) ON DELETE CASCADE,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    nota DECIMAL(5,2) NOT NULL CHECK (nota >= 0 AND nota <= 100),
    observaciones TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (actividad_id, estudiante_id)
);

CREATE INDEX IF NOT EXISTS idx_calificaciones_actividad_actividad ON calificaciones_actividad(actividad_id);
CREATE INDEX IF NOT EXISTS idx_calificaciones_actividad_estudiante ON calificaciones_actividad(estudiante_id);

-- Trigger para calificaciones_actividad
DROP TRIGGER IF EXISTS trigger_update_calificaciones_actividad_timestamp ON calificaciones_actividad;

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
-- 5. FUNCIÓN PARA CALCULAR NOTA DESDE ACTIVIDADES
-- ============================================

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
-- 6. TRIGGER PARA ACTUALIZAR NOTA_FINAL AUTOMÁTICAMENTE
-- ============================================

DROP TRIGGER IF EXISTS trigger_actualizar_nota_final ON calificaciones_actividad;

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

-- ============================================
-- 7. VERIFICAR LAS TABLAS
-- ============================================

SELECT 'Columnas de calificaciones:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'calificaciones' 
ORDER BY ordinal_position;

SELECT 'Tablas creadas:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('calificaciones', 'actividades', 'calificaciones_actividad');
