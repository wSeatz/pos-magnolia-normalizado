# Restricciones de integridad del diseño

## 1. Integridad de entidad (llaves primarias)
Cada tabla tiene una PK que garantiza que no hay dos registros idénticos:
cliente.documento, vendedor.documento, producto.codigo, proveedor.id,
categoria.id, sucursal.id, venta.id_venta, y la PK compuesta
(venta_id, producto_codigo) en detalle_venta.

## 2. Integridad referencial (llaves foráneas)
- vendedor.sucursal_id -> sucursal.id
- producto.categoria_id -> categoria.id
- producto.proveedor_id -> proveedor.id (ON DELETE RESTRICT: no se
  puede borrar un proveedor mientras tenga productos asociados)
- venta.cliente_documento -> cliente.documento
- venta.vendedor_documento -> vendedor.documento
- detalle_venta.venta_id -> venta.id_venta (ON DELETE CASCADE: si se
  borra una venta, se borran sus líneas de detalle)
- detalle_venta.producto_codigo -> producto.codigo (ON DELETE RESTRICT)

## 3. Integridad de dominio (CHECK, NOT NULL, tipos)
- detalle_venta.cantidad > 0
- detalle_venta.precio_unitario >= 0
- detalle_venta.garantia_meses >= 0
- venta.metodo_pago usa el tipo ENUM "mpago" (solo acepta los 5
  valores válidos: efectivo, tarjeta crédito, tarjeta débito,
  transferencia, transferencia bolsillo)
- Campos obligatorios (nombre, documento, código) marcados NOT NULL

## 4. Reglas de negocio (triggers)
- tr_valida_banco: si el método de pago no es "efectivo", exige
  que se registre el banco (regla que ningún CHECK simple podía
  cubrir, porque depende de una comparación condicional entre dos
  columnas)
- tr_auditoria_venta: garantiza que ninguna venta se pierda para
  siempre al ser modificada o eliminada, quedando registrada en
  auditoria_venta

## 5. Unicidad
- sucursal.nombre UNIQUE, categoria.nombre UNIQUE,
  proveedor.nombre UNIQUE: evita duplicar la misma sede, categoría
  o proveedor con nombres repetidos por error de digitación


# Punto 7: ¿Por qué el diseño inicial fue útil pero no pertinente?

El diseño original (pos_general) fue **útil** porque cumplió su
propósito inicial: permitió que el negocio operara, registrara
ventas y funcionara sin problemas durante tres años, con un
desarrollo simple y rápido de construir para un sobrino sin
experiencia formal en bases de datos.

Sin embargo, dejó de ser **pertinente** cuando el negocio creció y
surgieron nuevas necesidades de análisis (proveedores, mejores
vendedores, preferencias de clientes, etc.), porque:

- No estaba preparado para responder preguntas analíticas sin
  escanear millones de filas repetidas
- No permitía gestionar entidades (proveedores, productos) de forma
  independiente de las ventas
- Generaba anomalías de inserción, actualización y eliminación que
  ponían en riesgo la integridad de los datos históricos
- No escalaba: cualquier cambio de estructura (agregar un campo del
  cliente, por ejemplo) implicaba modificar millones de filas

En resumen: un diseño puede ser correcto para el problema que
resolvía en su momento, pero volverse inadecuado cuando el negocio
evoluciona y exige capacidades que el diseño original nunca
contempló.
