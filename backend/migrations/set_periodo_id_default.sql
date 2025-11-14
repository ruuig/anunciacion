-- Script para establecer un valor por defecto en periodo_id
-- O hacerlo completamente nullable

-- Opción 1: Establecer un valor por defecto
ALTER TABLE actividades 
ALTER COLUMN periodo_id SET DEFAULT NULL;

-- Opción 2: O simplemente asegurarnos que sea nullable (ya lo es según la imagen)
-- Ya está hecho

-- Verificar
SELECT column_name, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'actividades' 
AND column_name IN ('periodo_id', 'seccion_id', 'periodo');
