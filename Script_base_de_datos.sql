-- aquí va el mismo schema que te pasé antes, lo dejé igual que la versión larga
-- =====================================================
-- SISTEMA DE GESTIÓN ESCOLAR - ESQUEMA COMPLETO
-- (versión sin password_hash, usando password plano)
-- =====================================================

-- Por si quieres que sea repetible
-- CREATE SCHEMA IF NOT EXISTS public;

-- =====================================================
-- 1. TABLAS BÁSICAS (ROLES / PERMISOS / USUARIOS)
-- =====================================================

-- Tabla de roles
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    nivel INTEGER NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de permisos
CREATE TABLE IF NOT EXISTS permisos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(100) UNIQUE NOT NULL,
    modulo VARCHAR(50) NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla intermedia roles_permisos
CREATE TABLE IF NOT EXISTS roles_permisos (
    id SERIAL PRIMARY KEY,
    rol_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permiso_id INTEGER NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (rol_id, permiso_id)
);

-- Tabla de usuarios
-- 👇 OJO: aquí ya NO usamos password_hash
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password TEXT NOT NULL,              -- <- password plano
    telefono VARCHAR(20),
    rol_id INTEGER NOT NULL REFERENCES roles(id),
    estado VARCHAR(20) DEFAULT 'activo',
    url_avatar VARCHAR(500),
    ultimo_acceso TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 2. ESTRUCTURA ACADÉMICA
-- =====================================================

-- Niveles educativos
CREATE TABLE IF NOT EXISTS niveles_educativos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    orden INTEGER NOT NULL,
    color_hex VARCHAR(7),
    activo BOOLEAN DEFAULT true
);

-- Grados
-- Nota: en tu script usabas "ano_academico" así lo dejamos
CREATE TABLE IF NOT EXISTS grados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nivel_educativo_id INTEGER NOT NULL REFERENCES niveles_educativos(id),
    rango_edad VARCHAR(50),
    ano_academico VARCHAR(9) NOT NULL,
    activo BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (nombre, ano_academico)
);

-- Secciones
CREATE TABLE IF NOT EXISTS secciones (
    id SERIAL PRIMARY KEY,
    grado_id INTEGER NOT NULL REFERENCES grados(id) ON DELETE CASCADE,
    nombre VARCHAR(10) NOT NULL,
    capacidad INTEGER,
    cantidad_estudiantes INTEGER DEFAULT 0,
    activo BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (grado_id, nombre)
);

-- Materias
CREATE TABLE IF NOT EXISTS materias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    codigo VARCHAR(20) UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. PERSONAS (ESTUDIANTES / PADRES / RELACIÓN)
-- =====================================================

-- Estudiantes
CREATE TABLE IF NOT EXISTS estudiantes (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE NOT NULL,  -- Código único del estudiante (ej: C716KYD)
    dpi VARCHAR(20) UNIQUE NOT NULL,     -- DPI/CUI del estudiante
    nombre VARCHAR(200) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero VARCHAR(20),
    direccion VARCHAR(500),
    telefono VARCHAR(20),
    email VARCHAR(150),
    url_avatar VARCHAR(500),
    grado_id INTEGER NOT NULL REFERENCES grados(id),
    seccion_id INTEGER NOT NULL REFERENCES secciones(id),
    fecha_inscripcion DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'activo',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Padres / encargados
CREATE TABLE IF NOT EXISTS padres (
    id SERIAL PRIMARY KEY,
    dpi VARCHAR(20) UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    relacion VARCHAR(50) NOT NULL,  -- padre, madre, tutor, etc.
    telefono VARCHAR(20) NOT NULL,
    telefono_secundario VARCHAR(20),
    email VARCHAR(150),
    direccion VARCHAR(500),
    ocupacion VARCHAR(100),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Relación estudiante - padre
CREATE TABLE IF NOT EXISTS estudiantes_padres (
    id SERIAL PRIMARY KEY,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    padre_id INTEGER NOT NULL REFERENCES padres(id) ON DELETE RESTRICT,
    es_contacto_principal BOOLEAN DEFAULT false,
    es_contacto_emergencia BOOLEAN DEFAULT false,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (estudiante_id, padre_id)
);

-- =====================================================
-- 4. PERIODOS / ACTIVIDADES / CALIFICACIONES
-- =====================================================

-- Periodos académicos
CREATE TABLE IF NOT EXISTS periodos_academicos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    ano_academico VARCHAR(9) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    orden INTEGER NOT NULL,
    activo BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (nombre, ano_academico)
);

-- Actividades (tareas, exámenes, proyectos)
CREATE TABLE IF NOT EXISTS actividades (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    docente_id INTEGER NOT NULL REFERENCES usuarios(id),
    materia_id INTEGER NOT NULL REFERENCES materias(id),
    grado_id INTEGER NOT NULL REFERENCES grados(id),
    seccion_id INTEGER NOT NULL REFERENCES secciones(id),
    periodo_id INTEGER NOT NULL REFERENCES periodos_academicos(id),
    tipo VARCHAR(20) NOT NULL, -- tarea, examen, proyecto...
    puntos_maximos DECIMAL(5,2) NOT NULL,
    ponderacion_porcentaje DECIMAL(5,2),
    fecha_entrega DATE,
    estado VARCHAR(20) DEFAULT 'pendiente',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Calificaciones de actividades
CREATE TABLE IF NOT EXISTS calificaciones_actividades (
    id SERIAL PRIMARY KEY,
    actividad_id INTEGER NOT NULL REFERENCES actividades(id) ON DELETE CASCADE,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    puntos_obtenidos DECIMAL(5,2),
    porcentaje_calificacion DECIMAL(5,2),
    comentarios TEXT,
    calificado_por INTEGER NOT NULL REFERENCES usuarios(id),
    fecha_calificacion TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (actividad_id, estudiante_id)
);

-- =====================================================
-- 5. PAGOS / FINANZAS
-- =====================================================

-- Conceptos de pago
CREATE TABLE IF NOT EXISTS conceptos_pago (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    monto_por_defecto DECIMAL(10,2),
    tipo VARCHAR(20), -- mensual, anual, opcional
    activo BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pagos
CREATE TABLE IF NOT EXISTS pagos (
    id SERIAL PRIMARY KEY,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id),
    concepto_id INTEGER NOT NULL REFERENCES conceptos_pago(id),
    monto DECIMAL(10,2) NOT NULL,
    fecha_pago DATE NOT NULL,
    metodo_pago VARCHAR(20),
    numero_referencia VARCHAR(100),
    numero_recibo VARCHAR(100) UNIQUE NOT NULL,
    estado VARCHAR(20) DEFAULT 'pendiente',
    comentarios TEXT,
    registrado_por INTEGER NOT NULL REFERENCES usuarios(id),
    verificado_por INTEGER REFERENCES usuarios(id),
    fecha_verificacion TIMESTAMP,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Estado de cuenta de estudiante
CREATE TABLE IF NOT EXISTS estado_cuenta_estudiante (
    id SERIAL PRIMARY KEY,
    estudiante_id INTEGER UNIQUE NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    total_cargado DECIMAL(10,2) DEFAULT 0,
    total_pagado DECIMAL(10,2) DEFAULT 0,
    saldo DECIMAL(10,2) DEFAULT 0,
    fecha_ultimo_pago DATE,
    estado_pago VARCHAR(20) DEFAULT 'al_dia',
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 6. ASISTENCIAS
-- =====================================================

CREATE TABLE IF NOT EXISTS asistencias (
    id SERIAL PRIMARY KEY,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    hora_entrada INTEGER,
    hora_salida INTEGER,
    estado VARCHAR(20) DEFAULT 'presente', -- presente, ausente, tarde
    metodo_entrada VARCHAR(20) DEFAULT 'manual',
    metodo_salida VARCHAR(20) DEFAULT 'manual',
    autorizado_por INTEGER REFERENCES usuarios(id),
    notas TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (estudiante_id, fecha)
);

-- =====================================================
-- 7. AUDITORÍA
-- =====================================================

CREATE TABLE IF NOT EXISTS auditoria (
    id BIGSERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    accion VARCHAR(100) NOT NULL,
    tabla_afectada VARCHAR(100) NOT NULL,
    registro_id INTEGER,
    valores_anteriores JSONB,
    valores_nuevos JSONB,
    direccion_ip VARCHAR(45),
    user_agent VARCHAR(500),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agregar columna codigo a la tabla estudiantes
-- El código es único y obligatorio (ejemplo: C716KYD)

ALTER TABLE estudiantes 
ADD COLUMN codigo VARCHAR(20) UNIQUE;


ALTER TABLE estudiantes 
ALTER COLUMN codigo SET NOT NULL;

-- Crear índice para búsquedas rápidas por código
CREATE INDEX idx_estudiantes_codigo ON estudiantes(codigo);

-- Comentario descriptivo
COMMENT ON COLUMN estudiantes.codigo IS 'Código único del estudiante asignado por el gobierno (ejemplo: C716KYD)';


-- =====================================================
-- 8. DATOS INICIALES
-- =====================================================

-- Roles
INSERT INTO roles (nombre, descripcion, nivel)
VALUES
('Administrador General', 'Acceso total a todo', 1),
('Docente', 'Acceso a clases y estudiantes', 2),
('Director/Secretaria', 'Acceso administrativo', 3),
('Padre', 'Acceso a hijos', 4)
ON CONFLICT (nombre) DO NOTHING;

-- Usuarios iniciales (SIN HASH, password plano)
INSERT INTO usuarios (nombre, username, telefono, rol_id, password)
SELECT 'Administrador del Sistema', 'admin', '50212345678', r.id, 'admin123'
FROM roles r
WHERE r.nombre = 'Administrador General'
ON CONFLICT (username) DO UPDATE
SET password = EXCLUDED.password;

INSERT INTO usuarios (nombre, username, telefono, rol_id, password)
SELECT 'Docente Ejemplo', 'docente1', '50223456789', r.id, 'docente123'
FROM roles r
WHERE r.nombre = 'Docente'
ON CONFLICT (username) DO UPDATE
SET password = EXCLUDED.password;

INSERT INTO usuarios (nombre, username, telefono, rol_id, password)
SELECT 'Directora Ejemplo', 'directora1', '50234567890', r.id, 'directora123'
FROM roles r
WHERE r.nombre = 'Director/Secretaria'
ON CONFLICT (username) DO UPDATE
SET password = EXCLUDED.password;

INSERT INTO usuarios (nombre, username, telefono, rol_id, password)
SELECT 'Padre Ejemplo', 'padre1', '50245678901', r.id, 'padre123'
FROM roles r
WHERE r.nombre = 'Padre'
ON CONFLICT (username) DO UPDATE
SET password = EXCLUDED.password;

-- Niveles educativos
INSERT INTO niveles_educativos (nombre, orden, color_hex)
VALUES
('Preprimaria', 1, '#EC4899'),
('Primaria', 2, '#3B82F6'),
('Secundaria', 3, '#10B981')
ON CONFLICT (nombre) DO NOTHING;

-- Materias básicas
INSERT INTO materias (nombre, codigo, descripcion)
VALUES
('Matemáticas', 'MAT', 'Matemáticas básicas y avanzadas'),
('Español', 'ESP', 'Lenguaje y comunicación'),
('Ciencias Naturales', 'CN', 'Biología, Física y Química'),
('Estudios Sociales', 'ES', 'Historia, Geografía y Civismo'),
('Inglés', 'ING', 'Idioma inglés'),
('Educación Física', 'EF', 'Actividad física y deporte'),
('Arte', 'ART', 'Expresión artística'),
('Computación', 'COMP', 'Tecnología e informática')
ON CONFLICT (nombre) DO NOTHING;

-- Conceptos de pago básicos
INSERT INTO conceptos_pago (nombre, descripcion, monto_por_defecto, tipo)
VALUES
('Colegiatura Mensual', 'Pago mensual por servicios educativos', 500.00, 'mensual'),
('Inscripción Anual', 'Pago de inscripción al inicio del año', 200.00, 'anual'),
('Materiales Escolares', 'Materiales y útiles escolares', 100.00, 'anual'),
('Eventos Especiales', 'Actividades extracurriculares', NULL, 'opcional'),
('Seguro Estudiantil', 'Seguro médico estudiantil', 50.00, 'anual')
ON CONFLICT (nombre) DO NOTHING;
