-- Tabla intermedia para asignar docentes a materias
-- Un docente puede dar varias materias, una materia puede ser dada por varios docentes

CREATE TABLE IF NOT EXISTS materias_docentes (
    id SERIAL PRIMARY KEY,
    materia_id INTEGER NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
    docente_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT true,
    UNIQUE (materia_id, docente_id)
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_materias_docentes_materia ON materias_docentes(materia_id);
CREATE INDEX IF NOT EXISTS idx_materias_docentes_docente ON materias_docentes(docente_id);

-- Tabla para asignar materias y docentes a grados específicos
-- Esto permite que un grado tenga múltiples materias, cada una con su docente asignado
CREATE TABLE IF NOT EXISTS grados_materias_docentes (
    id SERIAL PRIMARY KEY,
    grado_id INTEGER NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
    materia_id INTEGER NOT NULL REFERENCES materias(id) ON DELETE CASCADE,
    docente_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    ano_academico VARCHAR(9) NOT NULL,
    activo BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (grado_id, materia_id, ano_academico)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_grados_materias_docentes_grado ON grados_materias_docentes(grado_id);
CREATE INDEX IF NOT EXISTS idx_grados_materias_docentes_materia ON grados_materias_docentes(materia_id);
CREATE INDEX IF NOT EXISTS idx_grados_materias_docentes_docente ON grados_materias_docentes(docente_id);
CREATE INDEX IF NOT EXISTS idx_grados_materias_docentes_ano ON grados_materias_docentes(ano_academico);
