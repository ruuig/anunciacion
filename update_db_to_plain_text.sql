-- Script para cambiar a contraseñas en texto plano
-- Ejecuta esto en PostgreSQL para actualizar la tabla usuarios

-- Renombrar columna de password a password (si no está ya)
-- ALTER TABLE public.usuarios RENAME COLUMN password_hash TO password;

-- Actualizar contraseñas a texto plano (usa las contraseñas hasheadas actuales como referencia)
UPDATE public.usuarios SET password = 'admin123' WHERE username = 'admin';
UPDATE public.usuarios SET password = 'docente123' WHERE username = 'docente1';
UPDATE public.usuarios SET password = 'directora123' WHERE username = 'directora1';
UPDATE public.usuarios SET password = 'padre123' WHERE username = 'padre1';

-- Verificar cambios
SELECT username, password FROM public.usuarios;
