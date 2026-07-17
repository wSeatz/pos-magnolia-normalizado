-- =====================================================================
-- 07_magnolia_test.sql
-- Pruebas de interacción: INSERT, UPDATE, DELETE
-- Demuestra que las anomalías del diseño original ya no ocurren
-- =====================================================================

-- =====================================================================
-- PRUEBA 1 (INSERT): insertar un proveedor SIN ventas todavía
-- En el diseño viejo esto era IMPOSIBLE (el proveedor solo existía
-- dentro de una fila de venta). Ahora sí se puede.
-- =====================================================================
INSERT INTO proveedor (nombre, ciudad, departamento)
VALUES ('Distribuidora Nueva SAS', 'Palmira', 'Valle del Cauca');

-- Verificar que quedó creado, sin necesidad de ninguna venta:
SELECT * FROM proveedor WHERE nombre = 'Distribuidora Nueva SAS';


-- =====================================================================
-- PRUEBA 2 (INSERT): registrar una venta nueva usando el procedimiento
-- Reemplaza <CLIENTE>, <VENDEDOR> y <PRODUCTO> por documentos/códigos
-- reales que ya existan en tu base (revisa con los SELECT de abajo).
-- =====================================================================
SELECT documento, nombre FROM cliente LIMIT 5;
SELECT documento, nombre FROM vendedor LIMIT 5;
SELECT codigo, nombre FROM producto LIMIT 5;

-- Ejemplo (ajusta los valores con datos reales de tu base):
-- CALL sp_registrar_venta('CC123', 'V001', 'efectivo', NULL, 'P0001', 3, 5000, 6);

-- Verificar la venta más reciente creada:
SELECT * FROM venta ORDER BY id_venta DESC LIMIT 1;
SELECT * FROM detalle_venta ORDER BY venta_id DESC LIMIT 1;


-- =====================================================================
-- PRUEBA 3 (UPDATE): cambiar de ciudad a un cliente
-- En el diseño viejo esto requería un UPDATE masivo sobre todas sus
-- filas de venta, con riesgo de inconsistencia. Ahora es un solo
-- UPDATE sobre un solo registro en "cliente".
-- =====================================================================
-- Primero mira un cliente cualquiera:
SELECT documento, nombre, ciudad FROM cliente LIMIT 1;

-- Cambia su ciudad (ajusta el documento con uno real):
-- UPDATE cliente SET ciudad = 'Bogotá' WHERE documento = '<DOCUMENTO_AQUI>';

-- Confirma que solo cambió una fila, y que todas sus ventas pasadas
-- ahora "ven" la nueva ciudad automáticamente (porque ciudad vive
-- en cliente, no repetida en cada venta):
-- SELECT * FROM cliente WHERE documento = '<DOCUMENTO_AQUI>';


-- =====================================================================
-- PRUEBA 4 (DELETE): eliminar la última venta registrada
-- En el diseño viejo, borrar la fila borraba también toda la
-- información asociada sin dejar rastro. Ahora, gracias al trigger
-- tr_auditoria_venta, el borrado queda registrado en auditoria_venta.
-- =====================================================================
-- Identifica la última venta:
SELECT * FROM venta ORDER BY id_venta DESC LIMIT 1;

-- Bórrala (ajusta el id_venta con el que viste arriba):
-- DELETE FROM venta WHERE id_venta = <ID_AQUI>;

-- Verifica que quedó el rastro en la auditoría a pesar del borrado:
SELECT * FROM auditoria_venta
WHERE accion = 'DELETE'
ORDER BY fecha_accion DESC
LIMIT 5;


-- =====================================================================
-- PRUEBA 5: verificar que el trigger de validación de banco funciona
-- Esto DEBE fallar con un error controlado (no un error genérico):
-- =====================================================================
-- INSERT INTO venta(cliente_documento, vendedor_documento, metodo_pago, banco)
-- VALUES (
--     (SELECT documento FROM cliente LIMIT 1),
--     (SELECT documento FROM vendedor LIMIT 1),
--     'transferencia',
--     NULL
-- );
-- Resultado esperado: ERROR: Debe indicar el banco cuando el método
-- de pago es "transferencia"
