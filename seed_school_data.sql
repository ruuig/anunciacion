-- =====================================================
-- SISTEMA DE GESTIÓN ESCOLAR - DATOS DE PRUEBA MASIVOS
-- =====================================================
-- Este script asume que las tablas ya fueron creadas utilizando el esquema
-- proporcionado en el archivo de migraciones principal.
-- Ejecuta este archivo en un entorno de desarrollo para poblar la base
-- de datos con información de ejemplo.

BEGIN;

-- Limpiar datos previos (opcional en entornos de prueba)
TRUNCATE TABLE auditoria RESTART IDENTITY CASCADE;
TRUNCATE TABLE asistencias RESTART IDENTITY CASCADE;
TRUNCATE TABLE estado_cuenta_estudiante RESTART IDENTITY CASCADE;
TRUNCATE TABLE pagos RESTART IDENTITY CASCADE;
TRUNCATE TABLE calificaciones_actividades RESTART IDENTITY CASCADE;
TRUNCATE TABLE actividades RESTART IDENTITY CASCADE;
TRUNCATE TABLE periodos_academicos RESTART IDENTITY CASCADE;
TRUNCATE TABLE estudiantes_padres RESTART IDENTITY CASCADE;
TRUNCATE TABLE padres RESTART IDENTITY CASCADE;
TRUNCATE TABLE estudiantes RESTART IDENTITY CASCADE;
TRUNCATE TABLE materias RESTART IDENTITY CASCADE;
TRUNCATE TABLE secciones RESTART IDENTITY CASCADE;
TRUNCATE TABLE grados RESTART IDENTITY CASCADE;
TRUNCATE TABLE niveles_educativos RESTART IDENTITY CASCADE;
TRUNCATE TABLE usuarios RESTART IDENTITY CASCADE;
TRUNCATE TABLE roles_permisos RESTART IDENTITY CASCADE;
TRUNCATE TABLE permisos RESTART IDENTITY CASCADE;
TRUNCATE TABLE roles RESTART IDENTITY CASCADE;

-- Roles
INSERT INTO roles (nombre, descripcion, nivel) VALUES
    ('Administrador', 'Gestión total del sistema', 1),
    ('Director', 'Dirección académica y administrativa', 2),
    ('Docente', 'Responsable de impartir clases y calificar', 3),
    ('Orientador', 'Soporte académico y conductual', 4),
    ('Secretaría', 'Gestión de trámites y atención a padres', 5);

-- Permisos
INSERT INTO permisos (codigo, modulo, descripcion) VALUES
    ('USR_VIEW', 'usuarios', 'Visualizar usuarios'),
    ('USR_EDIT', 'usuarios', 'Editar usuarios'),
    ('GRD_VIEW', 'calificaciones', 'Visualizar calificaciones'),
    ('GRD_EDIT', 'calificaciones', 'Modificar calificaciones'),
    ('ACT_VIEW', 'actividades', 'Visualizar actividades'),
    ('ACT_EDIT', 'actividades', 'Gestionar actividades'),
    ('PAY_VIEW', 'pagos', 'Visualizar pagos'),
    ('PAY_EDIT', 'pagos', 'Gestionar pagos'),
    ('AST_VIEW', 'asistencias', 'Visualizar asistencias'),
    ('AST_EDIT', 'asistencias', 'Registrar asistencias'),
    ('RPT_VIEW', 'reportes', 'Generar reportes'),
    ('RPT_EXPORT', 'reportes', 'Exportar reportes');

-- Asignaciones de permisos por rol
INSERT INTO roles_permisos (rol_id, permiso_id)
SELECT r.id, p.id
FROM roles r
JOIN permisos p ON
    (r.nombre = 'Administrador') OR
    (r.nombre = 'Director' AND p.modulo IN ('usuarios', 'calificaciones', 'actividades', 'reportes')) OR
    (r.nombre = 'Docente' AND p.codigo IN ('GRD_VIEW', 'GRD_EDIT', 'ACT_VIEW', 'ACT_EDIT', 'AST_VIEW', 'AST_EDIT')) OR
    (r.nombre = 'Orientador' AND p.codigo IN ('GRD_VIEW', 'ACT_VIEW', 'AST_VIEW', 'RPT_VIEW')) OR
    (r.nombre = 'Secretaría' AND p.codigo IN ('PAY_VIEW', 'PAY_EDIT', 'ACT_VIEW', 'AST_VIEW'));

-- Usuarios (administrativos y docentes)
INSERT INTO usuarios (nombre, username, password, telefono, rol_id, estado, url_avatar, ultimo_acceso)
VALUES
    ('Ana Morales', 'amorales', '$2a$10$examplehash1', '+50255501000', 1, 'activo', NULL, NOW() - INTERVAL '1 day'),
    ('Carlos Pérez', 'cperez', '$2a$10$examplehash2', '+50255501001', 2, 'activo', NULL, NOW() - INTERVAL '2 hours'),
    ('María Gómez', 'mgomez', '$2a$10$examplehash3', '+50255501002', 3, 'activo', NULL, NOW() - INTERVAL '3 hours'),
    ('Luis Rodríguez', 'lrodriguez', '$2a$10$examplehash4', '+50255501003', 3, 'activo', NULL, NOW() - INTERVAL '30 minutes'),
    ('Patricia Ramírez', 'pramirez', '$2a$10$examplehash5', '+50255501004', 3, 'activo', NULL, NOW() - INTERVAL '50 minutes'),
    ('José Castillo', 'jcastillo', '$2a$10$examplehash6', '+50255501005', 4, 'activo', NULL, NOW() - INTERVAL '2 days'),
    ('Elena López', 'elopez', '$2a$10$examplehash7', '+50255501006', 5, 'activo', NULL, NOW() - INTERVAL '5 hours'),
    ('Ricardo Méndez', 'rmendez', '$2a$10$examplehash8', '+50255501007', 3, 'activo', NULL, NOW() - INTERVAL '4 hours'),
    ('Silvia Torres', 'storres', '$2a$10$examplehash9', '+50255501008', 3, 'activo', NULL, NOW() - INTERVAL '7 hours'),
    ('Hugo Díaz', 'hdiaz', '$2a$10$examplehash10', '+50255501009', 3, 'activo', NULL, NOW() - INTERVAL '9 hours');

-- Niveles educativos
INSERT INTO niveles_educativos (nombre, orden, color_hex)
VALUES
    ('Preprimaria', 1, '#FFC857'),
    ('Primaria', 2, '#8ECAE6'),
    ('Secundaria', 3, '#219EBC');

-- Grados
INSERT INTO grados (nombre, nivel_educativo_id, rango_edad, ano_academico, activo)
VALUES
    ('Preparatoria', 1, '4-5', '2024-2025', true),
    ('Kindergarten', 1, '5-6', '2024-2025', true),
    ('Primero Primaria', 2, '6-7', '2024-2025', true),
    ('Segundo Primaria', 2, '7-8', '2024-2025', true),
    ('Tercero Primaria', 2, '8-9', '2024-2025', true),
    ('Cuarto Primaria', 2, '9-10', '2024-2025', true),
    ('Quinto Primaria', 2, '10-11', '2024-2025', true),
    ('Sexto Primaria', 2, '11-12', '2024-2025', true),
    ('Primero Básico', 3, '12-13', '2024-2025', true),
    ('Segundo Básico', 3, '13-14', '2024-2025', true),
    ('Tercero Básico', 3, '14-15', '2024-2025', true);

-- Secciones (dos por grado)
INSERT INTO secciones (grado_id, nombre, capacidad, cantidad_estudiantes)
SELECT g.id, s.nombre, s.capacidad, s.cantidad_estudiantes
FROM grados g
CROSS JOIN (
    VALUES ('A', 30, 0), ('B', 30, 0)
) AS s(nombre, capacidad, cantidad_estudiantes);

-- Materias
INSERT INTO materias (nombre, codigo, descripcion)
VALUES
    ('Comunicación y Lenguaje', 'LEN101', 'Desarrollo de habilidades comunicativas'),
    ('Matemática', 'MAT101', 'Pensamiento lógico y resolución de problemas'),
    ('Ciencias Naturales', 'CNA101', 'Exploración del entorno natural'),
    ('Ciencias Sociales', 'CSO101', 'Historia y civismo'),
    ('Inglés', 'ING101', 'Idioma extranjero'),
    ('Educación Artística', 'ART101', 'Expresión creativa'),
    ('Educación Física', 'EFI101', 'Actividad física y salud'),
    ('Tecnología', 'TEC101', 'Pensamiento computacional'),
    ('Música', 'MUS101', 'Apreciación musical'),
    ('Valores', 'VAL101', 'Formación en valores humanos');

-- Periodos académicos
INSERT INTO periodos_academicos (nombre, ano_academico, fecha_inicio, fecha_fin, orden)
VALUES
    ('Primer Bimestre', '2024-2025', '2024-01-08', '2024-03-29', 1),
    ('Segundo Bimestre', '2024-2025', '2024-04-08', '2024-06-21', 2),
    ('Tercer Bimestre', '2024-2025', '2024-07-08', '2024-09-20', 3),
    ('Cuarto Bimestre', '2024-2025', '2024-10-07', '2024-11-29', 4);

-- Generar 120 padres de familia
INSERT INTO padres (dpi, nombre, relacion, telefono, telefono_secundario, email, direccion, ocupacion)
SELECT
    LPAD((100000000000 + s)::text, 13, '0') AS dpi,
    'Padre/Madre ' || s AS nombre,
    CASE WHEN s % 2 = 0 THEN 'Madre' ELSE 'Padre' END AS relacion,
    '+502444' || LPAD((1000 + s)::text, 4, '0') AS telefono,
    '+502555' || LPAD((2000 + s)::text, 4, '0') AS telefono_secundario,
    'familia' || s || '@correo.com' AS email,
    'Zona ' || (s % 25 + 1) || ', Ciudad' AS direccion,
    CASE WHEN s % 3 = 0 THEN 'Comerciante' WHEN s % 3 = 1 THEN 'Ingeniero' ELSE 'Docente' END AS ocupacion
FROM generate_series(1, 120) AS s;

-- Generar 240 estudiantes distribuidos en los grados y secciones disponibles
WITH secciones_asignadas AS (
    SELECT s.id AS seccion_id,
           s.grado_id,
           ROW_NUMBER() OVER (PARTITION BY s.grado_id ORDER BY s.id) AS idx
    FROM secciones s
),
fechas AS (
    SELECT generate_series(DATE '2012-01-01', DATE '2018-12-31', INTERVAL '15 day') AS fecha
)
INSERT INTO estudiantes (nombre, fecha_nacimiento, genero, direccion, telefono, email, url_avatar, grado_id, seccion_id, fecha_inscripcion, estado)
SELECT
    'Estudiante ' || gs.numero AS nombre,
    (SELECT fecha FROM fechas ORDER BY random() LIMIT 1) AS fecha_nacimiento,
    CASE WHEN gs.numero % 2 = 0 THEN 'Femenino' ELSE 'Masculino' END AS genero,
    'Colonia ' || (gs.numero % 40 + 1) || ', Zona ' || (gs.numero % 25 + 1) AS direccion,
    '+502333' || LPAD((4000 + gs.numero)::text, 4, '0') AS telefono,
    'estudiante' || gs.numero || '@correo.com' AS email,
    NULL AS url_avatar,
    sa.grado_id,
    sa.seccion_id,
    DATE '2024-01-08' + (gs.numero % 20) * INTERVAL '1 day' AS fecha_inscripcion,
    'activo'
FROM (
    SELECT generate_series(1, 240) AS numero
) AS gs
JOIN secciones_asignadas sa ON sa.idx = ((gs.numero - 1) % 2) + 1 AND sa.grado_id = ((gs.numero - 1) % 11) + 1;

-- Relacionar estudiantes con padres (dos por estudiante)
WITH padres_base AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
    FROM padres
),
repetidos AS (
    SELECT e.id AS estudiante_id,
           pb1.id AS padre_id
    FROM estudiantes e
    JOIN padres_base pb1 ON pb1.rn = ((e.id - 1) % 120) + 1
    UNION ALL
    SELECT e.id AS estudiante_id,
           pb2.id AS padre_id
    FROM estudiantes e
    JOIN padres_base pb2 ON pb2.rn = ((e.id + 59) % 120) + 1
)
INSERT INTO estudiantes_padres (estudiante_id, padre_id, es_contacto_principal, es_contacto_emergencia)
SELECT estudiante_id, padre_id,
       (ROW_NUMBER() OVER (PARTITION BY estudiante_id ORDER BY padre_id)) = 1 AS es_contacto_principal,
       true AS es_contacto_emergencia
FROM repetidos;

-- Estado de cuenta inicial
INSERT INTO estado_cuenta_estudiante (estudiante_id, total_cargado, total_pagado, saldo, fecha_ultimo_pago, estado_pago)
SELECT e.id,
       1500 + (e.id % 3) * 250 AS total_cargado,
       1000 + (e.id % 4) * 200 AS total_pagado,
       (1500 + (e.id % 3) * 250) - (1000 + (e.id % 4) * 200) AS saldo,
       CURRENT_DATE - (e.id % 30) AS fecha_ultimo_pago,
       CASE WHEN ((1500 + (e.id % 3) * 250) - (1000 + (e.id % 4) * 200)) > 0 THEN 'pendiente' ELSE 'al_dia' END AS estado_pago
FROM estudiantes e;

-- Pagos de colegiaturas recientes
INSERT INTO pagos (estudiante_id, concepto_id, monto, fecha_pago, metodo_pago, numero_referencia, numero_recibo, estado, comentarios, registrado_por)
SELECT e.id,
       ((e.id - 1) % 5) + 1 AS concepto_id,
       500 + (e.id % 3) * 50 AS monto,
       CURRENT_DATE - (e.id % 25) AS fecha_pago,
       CASE WHEN e.id % 2 = 0 THEN 'tarjeta' ELSE 'efectivo' END AS metodo_pago,
       'REF' || LPAD(e.id::text, 6, '0') AS numero_referencia,
       'REC' || LPAD((e.id + 2000)::text, 6, '0') AS numero_recibo,
       CASE WHEN e.id % 4 = 0 THEN 'pendiente' ELSE 'completado' END AS estado,
       'Pago mensualidad ' || ((e.id - 1) % 12 + 1) AS comentarios,
       7
FROM estudiantes e
WHERE e.id <= 180;

-- Asistencias
INSERT INTO asistencias (estudiante_id, fecha, hora_entrada, hora_salida, estado, metodo_entrada, metodo_salida, autorizado_por, notas)
SELECT e.id,
       CURRENT_DATE - (gs.dia % 20) AS fecha,
       730,
       1230,
       CASE WHEN gs.dia % 15 = 0 THEN 'ausente' WHEN gs.dia % 7 = 0 THEN 'tarde' ELSE 'presente' END AS estado,
       'manual',
       'manual',
       3,
       CASE WHEN gs.dia % 15 = 0 THEN 'Ausencia justificada' ELSE NULL END
FROM estudiantes e
JOIN LATERAL generate_series(1, 10) AS gs(dia) ON true
WHERE e.id <= 120;

-- Actividades académicas
WITH docentes AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM usuarios WHERE rol_id = 3
),
secciones_docentes AS (
    SELECT s.id AS seccion_id,
           s.grado_id,
           d.id AS docente_id,
           ROW_NUMBER() OVER (PARTITION BY s.grado_id ORDER BY s.id) AS idx
    FROM secciones s
    JOIN docentes d ON d.rn = ((s.id - 1) % (SELECT COUNT(*) FROM docentes)) + 1
)
INSERT INTO actividades (nombre, descripcion, docente_id, materia_id, grado_id, seccion_id, periodo_id, tipo, puntos_maximos, ponderacion_porcentaje, fecha_entrega, estado)
SELECT
    'Actividad ' || ROW_NUMBER() OVER (ORDER BY s.seccion_id, m.id, p.id) AS nombre,
    'Actividad evaluada para el grado ' || g.nombre,
    s.docente_id,
    m.id AS materia_id,
    g.id AS grado_id,
    s.seccion_id,
    p.id AS periodo_id,
    CASE WHEN m.id % 2 = 0 THEN 'Examen' ELSE 'Proyecto' END AS tipo,
    100,
    25,
    CURRENT_DATE + (ROW_NUMBER() OVER (ORDER BY s.seccion_id, m.id, p.id) % 30) AS fecha_entrega,
    CASE WHEN (ROW_NUMBER() OVER (ORDER BY s.seccion_id, m.id, p.id)) % 3 = 0 THEN 'cerrada' ELSE 'pendiente' END AS estado
FROM secciones_docentes s
JOIN grados g ON g.id = s.grado_id
JOIN materias m ON m.id <= 6
JOIN periodos_academicos p ON p.id <= 2
WHERE g.id <= 11;

-- Calificaciones de actividades (mas de 1,200 registros)
WITH actividades_list AS (
    SELECT id, grado_id, seccion_id FROM actividades
),
estudiantes_filtrados AS (
    SELECT e.id, e.grado_id, e.seccion_id
    FROM estudiantes e
)
INSERT INTO calificaciones_actividades (actividad_id, estudiante_id, puntos_obtenidos, porcentaje_calificacion, comentarios, calificado_por, fecha_calificacion)
SELECT
    a.id,
    e.id,
    ROUND(60 + random() * 40, 2) AS puntos_obtenidos,
    ROUND((60 + random() * 40), 2) AS porcentaje_calificacion,
    CASE WHEN random() < 0.15 THEN 'Requiere refuerzo' WHEN random() > 0.95 THEN 'Excelente participación' ELSE NULL END AS comentarios,
    3,
    CURRENT_TIMESTAMP - (e.id % 15) * INTERVAL '1 day'
FROM actividades_list a
JOIN estudiantes_filtrados e ON e.grado_id = a.grado_id AND e.seccion_id = a.seccion_id
WHERE a.id <= (SELECT MAX(id) FROM actividades)
LIMIT 1200;

-- Registros de auditoría
INSERT INTO auditoria (usuario_id, accion, tabla_afectada, registro_id, valores_anteriores, valores_nuevos, direccion_ip, user_agent)
SELECT
    ((gs % 5) + 1) AS usuario_id,
    CASE WHEN gs % 4 = 0 THEN 'UPDATE' WHEN gs % 4 = 1 THEN 'INSERT' WHEN gs % 4 = 2 THEN 'DELETE' ELSE 'LOGIN' END AS accion,
    (ARRAY['usuarios','estudiantes','actividades','pagos','calificaciones_actividades'])[((gs % 5) + 1)],
    gs,
    NULL,
    jsonb_build_object('detalle', 'Entrada de auditoría ' || gs),
    '192.168.1.' || (gs % 200 + 1),
    'Mozilla/5.0 (X11; Linux x86_64)'
FROM generate_series(1, 300) AS gs;

COMMIT;

-- =====================================================
-- RESUMEN DE DATOS INSERTADOS
-- =====================================================
-- Roles: 5 registros
-- Permisos: 12 registros
-- Roles por permiso: asignación completa según rol
-- Usuarios: 10 registros (administrativos y docentes)
-- Niveles educativos: 3 registros
-- Grados: 11 registros
-- Secciones: 22 registros (dos por grado)
-- Materias: 10 registros
-- Periodos académicos: 4 registros
-- Padres: 120 registros
-- Estudiantes: 240 registros distribuidos por grado/sección
-- Relaciones estudiante-padre: 480 registros
-- Estados de cuenta: 240 registros
-- Pagos: 180 registros
-- Asistencias: 1,200 registros (10 por 120 estudiantes)
-- Actividades: 264 registros (6 materias x 2 periodos x 22 secciones)
-- Calificaciones de actividades: 1,200 registros
-- Auditoría: 300 registros
-- Ajusta los límites o filtros del script según las necesidades de tu entorno.
