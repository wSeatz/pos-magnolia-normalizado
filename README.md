# pos-magnolia-normalizado

Rediseño y normalización (3FN) de la base de datos POS de la tienda
de doña Magnolia. El sistema original usaba una sola tabla plana
(`pos_general`) que generaba anomalías de inserción, actualización y
eliminación. Este proyecto migra ese esquema a un modelo relacional
normalizado, preservando toda la información histórica.

## Estructura del repositorio

| Archivo | Descripción |
|---|---|
| `01_magnolia_minimarket.ddl.sql` | Esquema original (desnormalizado), tal como estaba en producción |
| `02_magnolia_normalizado.sql` | DDL del esquema normalizado (3FN) + migración automática de datos desde `pos_general` |
| `03_magnolia_functions.sql` | 2 funciones y 1 procedimiento almacenado |
| `04_magnolia_triggers.sql` | 2 triggers (validación de banco y auditoría de ventas) |
| `05_magnolia_index.sql` | Índices para optimizar las consultas sobre tablas de gran volumen |
| `06_magnolia_queries.sql` | Consultas SQL para los 6 requisitos de información del negocio |
| `07_magnolia_test.sql` | Pruebas de interacción: INSERT, UPDATE, DELETE |
| `docker-compose.yml` | Despliegue de PostgreSQL + pgAdmin en contenedores |
| `restricciones_y_reflexion.md` | Restricciones de integridad del diseño + justificación del rediseño |
| `guion_video.md` | Guion de la sustentación en video |

## Modelo de datos

El esquema normalizado tiene 8 entidades:

`cliente`, `vendedor`, `sucursal`, `categoria`, `proveedor`,
`producto`, `venta`, `detalle_venta`

Cada entidad tiene su propia llave primaria y las relaciones se
resuelven mediante llaves foráneas, eliminando la repetición de
datos que tenía la tabla original.

## Problemas resueltos respecto al diseño original

- **Insertar un proveedor sin ventas**: ahora es posible, porque
  `proveedor` es una entidad independiente
- **Eliminar una venta sin perder información**: el trigger
  `tr_auditoria_venta` conserva un rastro en `auditoria_venta`
- **Actualizar la ciudad de un cliente**: ahora es un único
  `UPDATE` sobre un solo registro en `cliente`, sin riesgo de
  inconsistencias

## Cómo desplegar con Docker

```bash
git clone https://github.com/wSeatz/pos-magnolia-normalizado.git
cd pos-magnolia-normalizado
mkdir sql
mv *.sql sql/
docker compose up -d
```

> **Nota:** los archivos `.sql` de este repositorio están en la raíz.
> Antes de ejecutar `docker compose up -d`, muévelos a una carpeta
> llamada `sql/` (así lo espera `docker-compose.yml`):
>
> ```bash
> mkdir sql
> mv *.sql sql/
> docker compose up -d
> ```

Esto levanta:
- **PostgreSQL** en `localhost:5432` (usuario `magnolia`,
  contraseña `magnolia123`, base de datos `tienda`)
- **pgAdmin** en `http://localhost:5050` (usuario
  `admin@admin.com`, contraseña `admin123`)

Los scripts dentro de `sql/` se ejecutan automáticamente en orden
alfabético la primera vez que se crea el contenedor.

## Requisitos de información resueltos

1. Monto total vendido por cada ciudad donde hay sede
2. Proveedores con mayor facturación
3. Producto que más vende, en general y por ciudad
4. Clientes que compran todos los productos de un proveedor
5. Ciudad donde cada proveedor vende más
6. Mejor vendedor por sucursal

Todas las consultas están en `06_magnolia_queries.sql`.

## Funciones, procedimiento y triggers

**Funciones:**
- `fn_total_ciudad(ciudad)` — total vendido a clientes de una ciudad
- `fn_producto_mas_vendido(ciudad)` — producto más vendido, general o por ciudad

**Procedimiento:**
- `sp_registrar_venta(...)` — registra una venta completa (encabezado + detalle)

**Triggers:**
- `tr_valida_banco` — exige banco si el método de pago no es efectivo
- `tr_auditoria_venta` — registra cada INSERT/UPDATE/DELETE sobre `venta`

## Autor

wSeatz — Proyecto de Bases de Datos
