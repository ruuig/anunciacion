-- Arreglar registros existentes para que usen cálculo automático
-- Esto permite que el trigger actualice las notas automáticamente

-- 1. Actualizar todos los registros existentes para que NO usen nota manual
UPDATE calificaciones 
SET usar_nota_manual = false
WHERE usar_nota_manual = true;

-- 2. Recalcular todas las notas finales desde las actividades
UPDATE calificaciones c
SET nota_final = calcular_nota_desde_actividades(
    c.estudiante_id,
    c.materia_id,
    c.grado_id,
    c.periodo,
    c.ano_academico
)
WHERE usar_nota_manual = false;

-- 3. Verificar que el trigger funciona
-- El trigger se dispara automáticamente cuando se inserta/actualiza una calificación de actividad
SELECT 'Trigger verificado: ' || tgname as status
FROM pg_trigger 
WHERE tgname = 'trigger_actualizar_nota_final';

-- 4. Mostrar resumen de calificaciones actualizadas
SELECT 
    e.nombre as estudiante,
    m.nombre as materia,
    c.periodo,
    c.nota_final,
    c.usar_nota_manual,
    COUNT(ca.id) as actividades_calificadas
FROM calificaciones c
JOIN estudiantes e ON c.estudiante_id = e.id
JOIN materias m ON c.materia_id = m.id
LEFT JOIN actividades a ON a.materia_id = c.materia_id 
    AND a.grado_id = c.grado_id 
    AND a.periodo = c.periodo 
    AND a.ano_academico = c.ano_academico
LEFT JOIN calificaciones_actividad ca ON ca.actividad_id = a.id 
    AND ca.estudiante_id = c.estudiante_id
GROUP BY e.nombre, m.nombre, c.periodo, c.nota_final, c.usar_nota_manual
ORDER BY e.nombre, m.nombre, c.periodo;
