-- Script para ejecutar todas las migraciones necesarias
-- Ejecuta este archivo en tu base de datos PostgreSQL

-- 1. Agregar columna codigo
ALTER TABLE estudiantes 
ADD COLUMN IF NOT EXISTS codigo VARCHAR(20) UNIQUE;

-- Actualizar registros existentes con un código temporal
UPDATE estudiantes 
SET codigo = 'TEMP' || LPAD(id::TEXT, 6, '0')
WHERE codigo IS NULL;

-- Hacer la columna NOT NULL
ALTER TABLE estudiantes 
ALTER COLUMN codigo SET NOT NULL;

-- Crear índice
CREATE INDEX IF NOT EXISTS idx_estudiantes_codigo ON estudiantes(codigo);

-- 2. Agregar columna dpi
ALTER TABLE estudiantes 
ADD COLUMN IF NOT EXISTS dpi VARCHAR(20) UNIQUE;

-- Actualizar registros existentes con un DPI temporal
UPDATE estudiantes 
SET dpi = '0000000' || LPAD(id::TEXT, 6, '0')
WHERE dpi IS NULL;

-- Hacer la columna NOT NULL
ALTER TABLE estudiantes 
ALTER COLUMN dpi SET NOT NULL;

-- Crear índice
CREATE INDEX IF NOT EXISTS idx_estudiantes_dpi ON estudiantes(dpi);

-- Comentarios
COMMENT ON COLUMN estudiantes.codigo IS 'Código único del estudiante asignado por el gobierno (ejemplo: C716KYD)';
COMMENT ON COLUMN estudiantes.dpi IS 'DPI/CUI del estudiante (13 dígitos)';

-- Verificar que las columnas se agregaron correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'estudiantes' 
AND column_name IN ('codigo', 'dpi');
