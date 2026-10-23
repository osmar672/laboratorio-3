# Modelo relacional - Sistema de Inventario Aduanero

## Inventario y trazabilidad

El modelo utiliza 16 tablas base. `inventario_bodega` representa un lote por combinación de declaración, producto y bodega. La restricción `UNIQUE (id_declaracion, id_producto, id_bodega)` impide registrar dos veces el mismo lote en la misma ubicación. El estado aduanero (`retenido`/`liberado`) se conserva en la fila del lote, de modo que dos partidas distintas no mezclen mercancía con estados diferentes.

Los movimientos registran entrada, salida y traslado con origen/destino coherentes. La restricción `CHECK` exige: entrada = origen nulo y destino informado; salida = origen informado y destino nulo; traslado = ambas bodegas informadas y diferentes. Los datos iniciales están construidos para conciliar, por declaración-producto-bodega, entradas + traslados recibidos - salidas - traslados enviados con el inventario actual. El stock se mantiene como estado actual materializado y se audita contra la bitácora.

## Tablas

| Tabla | Propósito | Clave/relaciones principales |
|---|---|---|
| `pais` | Catálogo de países de origen | PK `id_pais`; `codigo_iso` único |
| `importador` | Empresas importadoras ficticias | PK `id_importador`; identificación fiscal y correo únicos |
| `exportador` | Empresas exportadoras ficticias | PK `id_exportador`; identificación fiscal y correo únicos |
| `agente_aduanal` | Profesionales que tramitan declaraciones | PK `id_agente`; licencia única |
| `categoria_arancelaria` | Códigos HS de seis caracteres | PK `id_categoria`; `codigo_sa` texto único |
| `producto` | Mercancías y peso unitario | PK `id_producto`; FK a categoría |
| `funcionario` | Personal aduanero | PK `id_funcionario`; FK recursiva `id_supervisor` nullable |
| `transportista` | Empresas ficticias de transporte | PK `id_transportista`; código único |
| `bodega` | Ubicaciones y capacidad física en kg | PK `id_bodega`; nombre único |
| `declaracion_aduanera` | Operación aduanera principal | PK `id_declaracion`; FK opcional a importador/exportador según régimen, agente y países de origen/destino |
| `detalle_declaracion` | Productos/cantidades declarados | PK `id_detalle`; FK a declaración y producto; UNIQUE declaración-producto |
| `contenedor` | Unidad logística vinculada a declaración | PK `id_contenedor`; FK a transportista y declaración; número único |
| `inventario_bodega` | Stock actual por declaración, producto y bodega | PK `id_inventario`; FK a bodega, producto y declaración |
| `movimiento_inventario` | Bitácora de entradas, salidas y traslados | PK `id_movimiento`; FK a producto, declaración, bodegas opcionales y funcionario |
| `inspeccion` | Resultados y observaciones de control | PK `id_inspeccion`; FK a declaración y funcionario |
| `evento_declaracion` | Historial de eventos de una declaración | PK `id_evento`; FK a declaración y funcionario |

## Cardinalidades y opcionalidad

- `pais (1) -> (N) declaracion_aduanera` por `id_pais_origen`: un país puede originar muchas declaraciones. La misma entidad `pais` también se referencia opcionalmente por `id_pais_destino`, para representar mercados de destino sin duplicar catálogos.
- `importador (1) -> (N) declaracion_aduanera`: un importador puede registrar varias operaciones; es obligatorio salvo para el régimen de exportación.
- `exportador (1) -> (N) declaracion_aduanera`: un exportador puede aparecer en varias exportaciones; solo se asigna en régimen de exportación. La restricción `CHECK chk_declaracion_parte` impide asignar importador y exportador a la vez o dejar ambos nulos.
- `agente_aduanal (1) -> (N) declaracion_aduanera`: un agente puede tramitar varias declaraciones.
- `categoria_arancelaria (1) -> (N) producto`: una categoría agrupa varios productos; cada producto pertenece a una categoría.
- `declaracion_aduanera (1) -> (N) detalle_declaracion` y `producto (1) -> (N) detalle_declaracion`: resuelve la relación N:M entre declaraciones y productos.
- `declaracion_aduanera (1) -> (N) contenedor`; `transportista (1) -> (N) contenedor`.
- `bodega (1) -> (N) inventario_bodega`, `producto (1) -> (N) inventario_bodega` y `declaracion_aduanera (1) -> (N) inventario_bodega`: el stock conserva su origen y ubicación.
- `declaracion_aduanera (1) -> (N) movimiento_inventario`; `producto (1) -> (N) movimiento_inventario`; cada movimiento tiene un funcionario; el origen y destino son opcionales según el tipo.
- `funcionario (1) -> (N) inspeccion` y `declaracion_aduanera (1) -> (N) inspeccion`.
- `funcionario (1) -> (N) evento_declaracion` y `declaracion_aduanera (1) -> (N) evento_declaracion`.
- Relación recursiva de supervisión: un funcionario puede supervisar a varios funcionarios; cada empleado puede tener cero o un supervisor. La raíz organizacional usa `NULL`.

## Normalización

El modelo se diseña hasta 3FN: cada tabla representa una entidad o relación concreta; los atributos no clave dependen de la clave completa; la razón social del importador, el país, el agente y la categoría no se copian en las filas de detalle. Las vistas `vw_*` son proyecciones de lectura para consultas; no duplican datos almacenados. No se implementó una relación 1:1 artificial: no hay una en este dominio mínimo que aporte valor demostrable.

## Vistas de consulta

- `vw_inventario_consulta`: lote + producto + bodega + declaración + importador + país.
- `vw_declaraciones_consulta`: declaración, parte comercial, países de origen/destino, cantidad de contenedores y valor declarado.
- `vw_inspecciones_consulta`: resultado, observación, declaración y funcionario.
- `vw_ocupacion_bodega`: ocupación en kg calculada usando cantidad por peso unitario.

Los datos son sintéticos y educativos; los porcentajes arancelarios y estados no son asesoría normativa ni una parametrización legal de Costa Rica u otra jurisdicción.
