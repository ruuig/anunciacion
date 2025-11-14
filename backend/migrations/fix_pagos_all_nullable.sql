-- Corregir tabla pagos: hacer todas las columnas opcionales nullable
ALTER TABLE pagos ALTER COLUMN numero_recibo DROP NOT NULL;
ALTER TABLE pagos ALTER COLUMN registrado_por DROP NOT NULL;
ALTER TABLE pagos ALTER COLUMN concepto_id DROP NOT NULL;
ALTER TABLE pagos ALTER COLUMN comprobante_url DROP NOT NULL;
ALTER TABLE pagos ALTER COLUMN notas DROP NOT NULL;
