-- =====================================================================
-- 04_magnolia_triggers.sql
-- Triggers sobre el esquema normalizado
-- =====================================================================

-- =====================================================================
-- TRIGGER 1: tr_valida_banco
-- Si el método de pago NO es efectivo, exige que se registre el banco.
-- Evita ventas con datos incompletos (ej. pago con tarjeta sin banco).
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_valida_banco()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.metodo_pago <> 'efectivo' AND
       (NEW.banco IS NULL OR TRIM(NEW.banco) = '') THEN
        RAISE EXCEPTION
            'Debe indicar el banco cuando el método de pago es "%"',
            NEW.metodo_pago;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_valida_banco
BEFORE INSERT OR UPDATE ON venta
FOR EACH ROW
EXECUTE FUNCTION fn_valida_banco();

-- Prueba (debe fallar):
-- INSERT INTO venta(cliente_documento, vendedor_documento, metodo_pago, banco)
-- VALUES ('CC123', 'V001', 'transferencia', NULL);

-- =====================================================================
-- TABLA DE APOYO: auditoria_venta
-- Guarda un rastro de cada cambio hecho sobre "venta", para que si se
-- elimina o modifica una venta, no se pierda la información histórica
-- (este era justamente el problema del diseño original).
-- =====================================================================
CREATE TABLE IF NOT EXISTS auditoria_venta (
    id_auditoria   SERIAL PRIMARY KEY,
    accion         VARCHAR(10) NOT NULL,     -- INSERT / UPDATE / DELETE
    id_venta       INTEGER NOT NULL,
    fecha_venta    TIMESTAMP,
    cliente_documento  VARCHAR(20),
    vendedor_documento VARCHAR(20),
    metodo_pago    VARCHAR(60),
    banco          VARCHAR(50),
    fecha_accion   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario_db     VARCHAR(50) DEFAULT CURRENT_USER
);

-- =====================================================================
-- TRIGGER 2: tr_auditoria_venta
-- Registra en auditoria_venta cada INSERT, UPDATE o DELETE sobre venta
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_auditoria_venta()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria_venta(accion, id_venta, fecha_venta,
            cliente_documento, vendedor_documento, metodo_pago, banco)
        VALUES ('DELETE', OLD.id_venta, OLD.fecha,
            OLD.cliente_documento, OLD.vendedor_documento,
            OLD.metodo_pago::VARCHAR, OLD.banco);
        RETURN OLD;
    ELSE
        INSERT INTO auditoria_venta(accion, id_venta, fecha_venta,
            cliente_documento, vendedor_documento, metodo_pago, banco)
        VALUES (TG_OP, NEW.id_venta, NEW.fecha,
            NEW.cliente_documento, NEW.vendedor_documento,
            NEW.metodo_pago::VARCHAR, NEW.banco);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_auditoria_venta
AFTER INSERT OR UPDATE OR DELETE ON venta
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_venta();

-- Prueba: inserta, actualiza o borra una venta y luego revisa
-- SELECT * FROM auditoria_venta ORDER BY fecha_accion DESC LIMIT 5;
