-- =====================================================================
-- 05_magnolia_index.sql
-- Índices para acelerar las consultas más frecuentes sobre el
-- esquema normalizado (venta/detalle_venta tienen 3.3M+ filas)
-- =====================================================================

-- venta: se filtra/agrupa muy seguido por cliente, vendedor y fecha
CREATE INDEX idx_venta_cliente   ON venta(cliente_documento);
CREATE INDEX idx_venta_vendedor  ON venta(vendedor_documento);
CREATE INDEX idx_venta_fecha     ON venta(fecha);

-- detalle_venta: se agrupa muy seguido por producto (para ranking
-- de más vendidos) y se hace JOIN constante con venta
CREATE INDEX idx_detalle_producto  ON detalle_venta(producto_codigo);
CREATE INDEX idx_detalle_venta_id  ON detalle_venta(venta_id);

-- producto: se filtra/agrupa por proveedor y categoría
CREATE INDEX idx_producto_proveedor  ON producto(proveedor_id);
CREATE INDEX idx_producto_categoria  ON producto(categoria_id);

-- vendedor: se agrupa por sucursal (requisito 6: mejor vendedor por sede)
CREATE INDEX idx_vendedor_sucursal  ON vendedor(sucursal_id);

-- cliente: se filtra/agrupa por ciudad (requisito 1: monto por ciudad)
CREATE INDEX idx_cliente_ciudad  ON cliente(ciudad);

-- Verificación: lista los índices creados
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('venta','detalle_venta','producto','vendedor','cliente')
ORDER BY tablename, indexname;
