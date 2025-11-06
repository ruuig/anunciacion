-- Script para asignar grados al docente de prueba
-- Asume que tienes un docente con ID 5 (ajusta según tu caso)

-- Primero, verifica qué grados existen
SELECT id, nombre FROM grados ORDER BY id;

-- Asignar algunos grados al docente ID 5 para el año 2025
-- Ajusta el docente_id según el ID de tu usuario docente
INSERT INTO grados_docentes (grado_id, docente_id, ano_academico, activo)
SELECT id, 5, '2025', true
FROM grados
WHERE id IN (1, 2, 3) -- Ajusta los IDs según los grados que quieras asignar
ON CONFLICT (grado_id, docente_id, ano_academico) DO NOTHING;

-- Verificar las asignaciones
SELECT 
  gd.id,
  u.nombre as docente,
  g.nombre as grado,
  gd.ano_academico,
  gd.activo
FROM grados_docentes gd
INNER JOIN usuarios u ON u.id = gd.docente_id
INNER JOIN grados g ON g.id = gd.grado_id
WHERE gd.docente_id = 5;
