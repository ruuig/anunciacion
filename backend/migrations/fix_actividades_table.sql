-- Script para actualizar la tabla actividades existente
-- Agrega las columnas faltantes

-- 1. Agregar columnas faltantes a actividades
ALTER TABLE actividades 
ADD COLUMN IF NOT EXISTS periodo VARCHAR(50);

ALTER TABLE actividades 
ADD COLUMN IF NOT EXISTS ano_academico INTEGER;

ALTER TABLE actividades 
ADD COLUMN IF NOT EXISTS ponderacion DECIMAL(5,2) DEFAULT 100.00 CHECK (ponderacion > 0);

ALTER TABLE actividades 
ADD COLUMN IF NOT EXISTS fecha_entrega DATE;

ALTER TABLE actividades 
ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true;

-- 2. Actualizar registros existentes con valores por defecto
UPDATE actividades 
SET periodo = 'Primer Bimestre' 
WHERE periodo IS NULL;

UPDATE actividades 
SET ano_academico = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE ano_academico IS NULL;

UPDATE actividades 
SET ponderacion = 100.00 
WHERE ponderacion IS NULL;

UPDATE actividades 
SET activo = true 
WHERE activo IS NULL;

-- 3. Hacer las columnas NOT NULL después de agregar valores por defecto
ALTER TABLE actividades 
ALTER COLUMN periodo SET NOT NULL;

ALTER TABLE actividades 
ALTER COLUMN ano_academico SET NOT NULL;

ALTER TABLE actividades 
ALTER COLUMN ponderacion SET NOT NULL;

-- 4. Crear índices si no existen
CREATE INDEX IF NOT EXISTS idx_actividades_materia ON actividades(materia_id);
CREATE INDEX IF NOT EXISTS idx_actividades_grado ON actividades(grado_id);
CREATE INDEX IF NOT EXISTS idx_actividades_docente ON actividades(docente_id);
CREATE INDEX IF NOT EXISTS idx_actividades_periodo ON actividades(periodo);

-- 5. Verificar la estructura
SELECT 'Columnas de actividades:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'actividades' 
ORDER BY ordinal_position;
