-- Migración para simplificar el modelo: eliminar secciones como tabla separada
-- Los grados ahora incluyen la sección en el nombre (ej: "Primero A", "Primero B")

-- 1. Eliminar la restricción de foreign key de estudiantes a secciones
ALTER TABLE estudiantes 
DROP CONSTRAINT IF EXISTS estudiantes_seccion_id_fkey;

-- 2. Eliminar la columna seccion_id de estudiantes (ya no se usa)
ALTER TABLE estudiantes 
DROP COLUMN IF EXISTS seccion_id;

-- 3. Comentar que ahora el grado incluye la sección
COMMENT ON COLUMN estudiantes.grado_id IS 'ID del grado que incluye la sección (ej: Primero A, Primero B)';

-- 4. Opcional: Puedes eliminar la tabla secciones si no la usas para nada más
-- DROP TABLE IF EXISTS secciones CASCADE;

-- 5. Crear algunos grados de ejemplo con secciones incluidas
-- Ajusta según tus necesidades
INSERT INTO grados (nombre, nivel_educativo_id, ano_academico, activo, fecha_creacion, fecha_actualizacion)
VALUES 
  ('Primero A', 1, '2024-2025', true, NOW(), NOW()),
  ('Primero B', 1, '2024-2025', true, NOW(), NOW()),
  ('Segundo A', 1, '2024-2025', true, NOW(), NOW()),
  ('Segundo B', 1, '2024-2025', true, NOW(), NOW()),
  ('Tercero A', 1, '2024-2025', true, NOW(), NOW()),
  ('Tercero B', 1, '2024-2025', true, NOW(), NOW()),
  ('Cuarto A', 1, '2024-2025', true, NOW(), NOW()),
  ('Cuarto B', 1, '2024-2025', true, NOW(), NOW()),
  ('Quinto A', 1, '2024-2025', true, NOW(), NOW()),
  ('Quinto B', 1, '2024-2025', true, NOW(), NOW()),
  ('Sexto A', 1, '2024-2025', true, NOW(), NOW()),
  ('Sexto B', 1, '2024-2025', true, NOW(), NOW())
ON CONFLICT (nombre, ano_academico) DO NOTHING;

-- Verificar los grados creados
SELECT id, nombre, ano_academico, activo FROM grados ORDER BY nombre;
