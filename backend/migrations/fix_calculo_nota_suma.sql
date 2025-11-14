-- Cambiar el cálculo de nota final de promedio ponderado a suma simple
-- La nota final será la suma de todas las notas de actividades (máximo 100)

CREATE OR REPLACE FUNCTION calcular_nota_desde_actividades(
    p_estudiante_id INTEGER,
    p_materia_id INTEGER,
    p_grado_id INTEGER,
    p_periodo VARCHAR,
    p_ano_academico INTEGER
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_nota_calculada DECIMAL(5,2);
BEGIN
    -- Sumar todas las notas de actividades (máximo 100)
    SELECT 
        LEAST(
            COALESCE(SUM(ca.nota), 0),
            100
        )
    INTO v_nota_calculada
    FROM calificaciones_actividad ca
    INNER JOIN actividades a ON ca.actividad_id = a.id
    WHERE ca.estudiante_id = p_estudiante_id
      AND a.materia_id = p_materia_id
      AND a.grado_id = p_grado_id
      AND a.periodo = p_periodo
      AND a.ano_academico = p_ano_academico
      AND a.activo = true;
    
    RETURN ROUND(v_nota_calculada, 2);
END;
$$ LANGUAGE plpgsql;

-- Recalcular todas las notas con el nuevo método
UPDATE calificaciones c
SET nota_final = calcular_nota_desde_actividades(
    c.estudiante_id,
    c.materia_id,
    c.grado_id,
    c.periodo,
    c.ano_academico
)
WHERE usar_nota_manual = false;

-- Mostrar resultado
SELECT 
    e.nombre as estudiante,
    m.nombre as materia,
    c.periodo,
    c.nota_final as nota_suma,
    STRING_AGG(ca.nota::text, ' + ') as notas_actividades
FROM calificaciones c
JOIN estudiantes e ON c.estudiante_id = e.id
JOIN materias m ON c.materia_id = m.id
LEFT JOIN actividades a ON a.materia_id = c.materia_id 
    AND a.grado_id = c.grado_id 
    AND a.periodo = c.periodo 
    AND a.ano_academico = c.ano_academico
LEFT JOIN calificaciones_actividad ca ON ca.actividad_id = a.id 
    AND ca.estudiante_id = c.estudiante_id
WHERE c.usar_nota_manual = false
GROUP BY e.nombre, m.nombre, c.periodo, c.nota_final
ORDER BY e.nombre, m.nombre;
