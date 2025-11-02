-- Agregar columna codigo a la tabla estudiantes
-- El código es único y obligatorio (ejemplo: C716KYD)

ALTER TABLE estudiantes 
ADD COLUMN codigo VARCHAR(20) UNIQUE;

-- Actualizar registros existentes con un código temporal si hay datos
-- Puedes cambiar estos códigos manualmente después
UPDATE estudiantes 
SET codigo = 'TEMP' || LPAD(id::TEXT, 6, '0')
WHERE codigo IS NULL;

-- Hacer la columna NOT NULL después de llenar los datos existentes
ALTER TABLE estudiantes 
ALTER COLUMN codigo SET NOT NULL;

-- Crear índice para búsquedas rápidas por código
CREATE INDEX idx_estudiantes_codigo ON estudiantes(codigo);

-- Comentario descriptivo
COMMENT ON COLUMN estudiantes.codigo IS 'Código único del estudiante asignado por el gobierno (ejemplo: C716KYD)';
