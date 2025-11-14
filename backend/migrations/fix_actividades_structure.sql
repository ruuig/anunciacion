-- Script para arreglar la estructura de la tabla actividades
-- Hacer nullable las columnas que no son necesarias

-- Hacer nullable seccion_id y periodo_id
ALTER TABLE actividades 
ALTER COLUMN seccion_id DROP NOT NULL;

ALTER TABLE actividades 
ALTER COLUMN periodo_id DROP NOT NULL;

-- Ver la estructura actual
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'actividades' 
ORDER BY ordinal_position;
