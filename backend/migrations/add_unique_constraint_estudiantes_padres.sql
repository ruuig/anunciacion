-- Agregar restricción UNIQUE para evitar duplicados en estudiantes_padres
-- Solo puede haber una relación única entre un padre y un estudiante

ALTER TABLE estudiantes_padres 
ADD CONSTRAINT IF NOT EXISTS estudiantes_padres_unique 
UNIQUE (padre_id, estudiante_id);

-- Verificar la restricción
SELECT conname, contype 
FROM pg_constraint 
WHERE conrelid = 'estudiantes_padres'::regclass;
