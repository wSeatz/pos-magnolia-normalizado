-- =====================================================================
-- 03_magnolia_functions.sql
-- Funciones y procedimiento sobre el esquema normalizado
-- =====================================================================

-- =====================================================================
-- FUNCIÓN 1: fn_total_ciudad
-- Requisito 1: monto total vendido por cada ciudad
-- Recibe una ciudad y devuelve el total facturado a clientes de esa
-- ciudad (cantidad * precio_unitario de todas sus compras)
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_total_ciudad(p_ciudad VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(dv.cantidad * dv.precio_unitario), 0)
    INTO total
    FROM venta v
    JOIN cliente c        ON c.documento = v.cliente_documento
    JOIN detalle_venta dv ON dv.venta_id = v.id_venta
    WHERE c.ciudad = p_ciudad;

    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Prueba:
-- SELECT fn_total_ciudad('Cali');

-- =====================================================================
-- FUNCIÓN 2: fn_producto_mas_vendido
-- Requisito 3: producto que más se vende, en general o por ciudad
-- Si p_ciudad es NULL, calcula el más vendido a nivel general.
-- Si se pasa una ciudad, calcula el más vendido solo en esa ciudad.
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_producto_mas_vendido(p_ciudad VARCHAR DEFAULT NULL)
RETURNS TABLE(codigo VARCHAR, nombre VARCHAR, total_vendido BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT p.codigo, p.nombre, SUM(dv.cantidad)::BIGINT AS total_vendido
    FROM detalle_venta dv
    JOIN producto p  ON p.codigo = dv.producto_codigo
    JOIN venta v     ON v.id_venta = dv.venta_id
    LEFT JOIN cliente c ON c.documento = v.cliente_documento
    WHERE p_ciudad IS NULL OR c.ciudad = p_ciudad
    GROUP BY p.codigo, p.nombre
    ORDER BY total_vendido DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Prueba general:
-- SELECT * FROM fn_producto_mas_vendido();
-- Prueba por ciudad:
-- SELECT * FROM fn_producto_mas_vendido('Cali');

-- =====================================================================
-- PROCEDIMIENTO: sp_registrar_venta
-- Registra una venta completa (encabezado en "venta" + su línea en
-- "detalle_venta") en una sola operación, garantizando que ambas
-- inserciones ocurran juntas.
-- =====================================================================
CREATE OR REPLACE PROCEDURE sp_registrar_venta(
    p_cliente_documento   VARCHAR,
    p_vendedor_documento  VARCHAR,
    p_metodo_pago         mpago,
    p_banco               VARCHAR,
    p_producto_codigo     VARCHAR,
    p_cantidad            INTEGER,
    p_precio_unitario     NUMERIC,
    p_garantia_meses      INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_venta INTEGER;
BEGIN
    INSERT INTO venta (cliente_documento, vendedor_documento, metodo_pago, banco)
    VALUES (p_cliente_documento, p_vendedor_documento, p_metodo_pago, p_banco)
    RETURNING id_venta INTO v_id_venta;

    INSERT INTO detalle_venta (venta_id, producto_codigo, cantidad,
                                precio_unitario, garantia_meses)
    VALUES (v_id_venta, p_producto_codigo, p_cantidad,
            p_precio_unitario, p_garantia_meses);

    RAISE NOTICE 'Venta % registrada correctamente', v_id_venta;
END;
$$;

-- Prueba (usa un cliente/vendedor/producto que ya exista en tu data):
-- CALL sp_registrar_venta('CC123', 'V001', 'efectivo', NULL, 'P001', 2, 15000, 6);
