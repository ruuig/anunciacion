-- Verificar qué usuario está entrando
SELECT id, nombre, username, rol_id FROM usuarios WHERE rol_id = 2;

-- Asignar grados al docente con ID 1 para el año académico 2024-2025
INSERT INTO grados_docentes (grado_id, docente_id, ano_academico, activo)
VALUES 
  (2, 1, '2024-2025', true)
ON CONFLICT (grado_id, docente_id, ano_academico) 
DO UPDATE SET activo = true;

-- Verificar las asignaciones
SELECT 
  gd.id,
  u.nombre as docente,
  u.id as docente_id,
  g.nombre as grado,
  gd.ano_academico,
  gd.activo
FROM grados_docentes gd
INNER JOIN usuarios u ON u.id = gd.docente_id
INNER JOIN grados g ON g.id = gd.grado_id
WHERE gd.docente_id = 1;
