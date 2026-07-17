-- =====================================================================
-- 06_magnolia_queries.sql
-- Consultas SQL para los 6 requisitos de información de doña Magnolia
-- =====================================================================

-- =====================================================================
-- REQUISITO 1: Monto total vendido por cada ciudad donde hay sede
-- (se usa la ciudad de la SUCURSAL, tal como pide el enunciado)
-- =====================================================================
SELECT s.nombre AS ciudad_sede,
       SUM(dv.cantidad * dv.precio_unitario) AS total_vendido
FROM sucursal s
JOIN vendedor v        ON v.sucursal_id = s.id
JOIN venta ve           ON ve.vendedor_documento = v.documento
JOIN detalle_venta dv   ON dv.venta_id = ve.id_venta
GROUP BY s.nombre
ORDER BY total_vendido DESC;


-- =====================================================================
-- REQUISITO 2: Proveedores con mayor facturación
-- =====================================================================
SELECT pr.nombre AS proveedor,
       SUM(dv.cantidad * dv.precio_unitario) AS facturacion
FROM proveedor pr
JOIN producto p        ON p.proveedor_id = pr.id
JOIN detalle_venta dv  ON dv.producto_codigo = p.codigo
GROUP BY pr.nombre
ORDER BY facturacion DESC;


-- =====================================================================
-- REQUISITO 3a: Producto que más vende, EN GENERAL
-- =====================================================================
SELECT p.codigo, p.nombre,
       SUM(dv.cantidad) AS total_unidades
FROM detalle_venta dv
JOIN producto p ON p.codigo = dv.producto_codigo
GROUP BY p.codigo, p.nombre
ORDER BY total_unidades DESC
LIMIT 1;

-- REQUISITO 3b: Producto que más vende, POR CADA CIUDAD (sede)
SELECT DISTINCT ON (s.nombre)
       s.nombre AS ciudad_sede, p.codigo, p.nombre,
       SUM(dv.cantidad) AS total_unidades
FROM detalle_venta dv
JOIN producto p         ON p.codigo = dv.producto_codigo
JOIN venta ve            ON ve.id_venta = dv.venta_id
JOIN vendedor v          ON v.documento = ve.vendedor_documento
JOIN sucursal s          ON s.id = v.sucursal_id
GROUP BY s.nombre, p.codigo, p.nombre
ORDER BY s.nombre, total_unidades DESC;


-- =====================================================================
-- REQUISITO 4: Clientes que "prefieren" a un proveedor, es decir,
-- que han comprado TODOS los productos de ese proveedor
-- (división relacional: el cliente debe tener tantos productos
-- distintos comprados de ese proveedor como productos tiene el
-- proveedor en total)
-- =====================================================================
SELECT pr.nombre AS proveedor, c.documento, c.nombre AS cliente
FROM proveedor pr
JOIN producto p         ON p.proveedor_id = pr.id
JOIN detalle_venta dv   ON dv.producto_codigo = p.codigo
JOIN venta ve            ON ve.id_venta = dv.venta_id
JOIN cliente c           ON c.documento = ve.cliente_documento
GROUP BY pr.id, pr.nombre, c.documento, c.nombre
HAVING COUNT(DISTINCT p.codigo) = (
    SELECT COUNT(*) FROM producto p2 WHERE p2.proveedor_id = pr.id
)
ORDER BY pr.nombre, c.nombre;


-- =====================================================================
-- REQUISITO 5: Ciudad donde cada proveedor vende más
-- (se usa la ciudad del CLIENTE: dónde hay más demanda de sus productos)
-- =====================================================================
SELECT DISTINCT ON (pr.nombre)
       pr.nombre AS proveedor, c.ciudad,
       SUM(dv.cantidad * dv.precio_unitario) AS total_vendido
FROM proveedor pr
JOIN producto p         ON p.proveedor_id = pr.id
JOIN detalle_venta dv   ON dv.producto_codigo = p.codigo
JOIN venta ve            ON ve.id_venta = dv.venta_id
JOIN cliente c           ON c.documento = ve.cliente_documento
WHERE c.ciudad IS NOT NULL
GROUP BY pr.nombre, c.ciudad
ORDER BY pr.nombre, total_vendido DESC;


-- =====================================================================
-- REQUISITO 6: Mejor vendedor por cada sucursal/sede
-- =====================================================================
SELECT DISTINCT ON (s.nombre)
       s.nombre AS sucursal, v.documento, v.nombre AS vendedor,
       SUM(dv.cantidad * dv.precio_unitario) AS total_vendido
FROM sucursal s
JOIN vendedor v          ON v.sucursal_id = s.id
JOIN venta ve             ON ve.vendedor_documento = v.documento
JOIN detalle_venta dv    ON dv.venta_id = ve.id_venta
GROUP BY s.nombre, v.documento, v.nombre
ORDER BY s.nombre, total_vendido DESC;
