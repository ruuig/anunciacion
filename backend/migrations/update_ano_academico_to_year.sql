-- Script para cambiar el formato de año académico de "2024-2025" a solo "2025"
-- IMPORTANTE: Ejecuta esto solo si quieres cambiar el formato en las tablas existentes

-- 1. Actualizar grados_docentes
-- Cambiar "2024-2025" a "2025"
UPDATE grados_docentes 
SET ano_academico = SPLIT_PART(ano_academico, '-', 2)
WHERE ano_academico LIKE '%-%';

-- Cambiar el tipo de columna a INTEGER
ALTER TABLE grados_docentes 
ALTER COLUMN ano_academico TYPE INTEGER USING ano_academico::INTEGER;

-- 2. Actualizar grados_materias_docentes (si existe y tiene datos)
UPDATE grados_materias_docentes 
SET ano_academico = SPLIT_PART(ano_academico, '-', 2)
WHERE ano_academico LIKE '%-%';

ALTER TABLE grados_materias_docentes 
ALTER COLUMN ano_academico TYPE INTEGER USING ano_academico::INTEGER;

-- 3. Verificar los cambios
SELECT 'grados_docentes' as tabla, docente_id, grado_id, ano_academico 
FROM grados_docentes
UNION ALL
SELECT 'grados_materias_docentes' as tabla, docente_id, grado_id, ano_academico 
FROM grados_materias_docentes;
