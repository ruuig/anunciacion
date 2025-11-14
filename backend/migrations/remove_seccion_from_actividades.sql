-- Script para eliminar la columna seccion_id de la tabla actividades
-- Ya no se usa porque las actividades son por grado completo, no por sección

-- Hacer la columna nullable primero (por si hay datos)
ALTER TABLE actividades 
ALTER COLUMN seccion_id DROP NOT NULL;

-- Opcional: Si quieres eliminar la columna completamente
-- ALTER TABLE actividades DROP COLUMN IF EXISTS seccion_id;

-- Verificar la estructura
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'actividades' 
ORDER BY ordinal_position;
