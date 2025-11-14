-- Corregir tabla pagos: hacer numero_recibo nullable
ALTER TABLE pagos ALTER COLUMN numero_recibo DROP NOT NULL;
