-- Tabla para asignar docentes a grados
-- Un grado puede tener varios docentes, un docente puede estar en varios grados
-- Los docentes ya tienen sus materias asignadas en materias_docentes

CREATE TABLE IF NOT EXISTS grados_docentes (
    id SERIAL PRIMARY KEY,
    grado_id INTEGER NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
    docente_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    ano_academico VARCHAR(9) NOT NULL,
    activo BOOLEAN DEFAULT true,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (grado_id, docente_id, ano_academico)
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_grados_docentes_grado ON grados_docentes(grado_id);
CREATE INDEX IF NOT EXISTS idx_grados_docentes_docente ON grados_docentes(docente_id);
CREATE INDEX IF NOT EXISTS idx_grados_docentes_ano ON grados_docentes(ano_academico);

COMMENT ON TABLE grados_docentes IS 'Asignación de docentes a grados. Los docentes ya tienen sus materias asignadas en materias_docentes';
COMMENT ON COLUMN grados_docentes.grado_id IS 'Grado al que se asigna el docente';
COMMENT ON COLUMN grados_docentes.docente_id IS 'Docente asignado al grado';
COMMENT ON COLUMN grados_docentes.ano_academico IS 'Año académico de la asignación';
