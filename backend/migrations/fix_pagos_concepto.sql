-- Corregir tabla pagos: hacer concepto_id nullable o eliminarlo
-- Opción 1: Hacer concepto_id nullable (si existe)
ALTER TABLE pagos ALTER COLUMN concepto_id DROP NOT NULL;

-- Opción 2: Si la columna no existe, no hay problema
-- Esta migración solo afecta si la columna existe
