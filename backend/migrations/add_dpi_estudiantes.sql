-- Agregar columna dpi a la tabla estudiantes
-- El DPI/CUI es único y obligatorio (13 dígitos)

ALTER TABLE estudiantes 
ADD COLUMN IF NOT EXISTS dpi VARCHAR(20) UNIQUE;

-- Actualizar registros existentes con un DPI temporal si hay datos
-- Puedes cambiar estos DPIs manualmente después
UPDATE estudiantes 
SET dpi = '0000000' || LPAD(id::TEXT, 6, '0')
WHERE dpi IS NULL;

-- Hacer la columna NOT NULL después de llenar los datos existentes
ALTER TABLE estudiantes 
ALTER COLUMN dpi SET NOT NULL;

-- Crear índice para búsquedas rápidas por DPI
CREATE INDEX IF NOT EXISTS idx_estudiantes_dpi ON estudiantes(dpi);

-- Comentario descriptivo
COMMENT ON COLUMN estudiantes.dpi IS 'DPI/CUI del estudiante (13 dígitos)';
