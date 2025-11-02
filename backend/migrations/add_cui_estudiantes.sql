-- Agregar columna dpi (CUI) a la tabla estudiantes
-- CUI = Código Único de Identificación (13 dígitos en Guatemala)

ALTER TABLE estudiantes 
ADD COLUMN IF NOT EXISTS dpi VARCHAR(20) UNIQUE;

-- Actualizar registros existentes con un CUI temporal si hay datos
-- Puedes cambiar estos CUIs manualmente después
UPDATE estudiantes 
SET dpi = '0000000' || LPAD(id::TEXT, 6, '0')
WHERE dpi IS NULL;

-- Hacer la columna NOT NULL después de llenar los datos existentes
ALTER TABLE estudiantes 
ALTER COLUMN dpi SET NOT NULL;

-- Crear índice para búsquedas rápidas por CUI
CREATE INDEX IF NOT EXISTS idx_estudiantes_dpi ON estudiantes(dpi);

-- Comentario descriptivo
COMMENT ON COLUMN estudiantes.dpi IS 'CUI del estudiante - Código Único de Identificación (13 dígitos)';

-- Verificar que la columna se agregó correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'estudiantes' 
AND column_name = 'dpi';
