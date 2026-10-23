-- Estas consultas son controles de diagnóstico. Cada consulta de hallazgos debe devolver cero filas,
-- excepto los resúmenes de conteo explícitos. Ejecutar después de cargar los datos.

-- 1) Referencias de país huérfanas.
SELECT da.id_declaracion FROM declaracion_aduanera da LEFT JOIN pais p ON p.id_pais=da.id_pais_origen WHERE p.id_pais IS NULL;

-- 2) Declaraciones sin detalle.
SELECT da.id_declaracion FROM declaracion_aduanera da LEFT JOIN detalle_declaracion dd ON dd.id_declaracion=da.id_declaracion WHERE dd.id_detalle IS NULL;

-- 3) Movimientos incompatibles con las reglas de origen/destino.
SELECT id_movimiento FROM movimiento_inventario
WHERE cantidad<=0 OR
 (tipo_movimiento='entrada' AND (id_bodega_origen IS NOT NULL OR id_bodega_destino IS NULL)) OR
 (tipo_movimiento='salida' AND (id_bodega_origen IS NULL OR id_bodega_destino IS NOT NULL)) OR
 (tipo_movimiento='traslado' AND (id_bodega_origen IS NULL OR id_bodega_destino IS NULL OR id_bodega_origen=id_bodega_destino));

-- 4) Cantidades o valores negativos/cero (los CHECK también deben rechazarlos al insertar).
SELECT 'detalle_declaracion' tabla, id_detalle id FROM detalle_declaracion WHERE cantidad<=0 OR valor_unitario_declarado<0
UNION ALL SELECT 'inventario_bodega', id_inventario FROM inventario_bodega WHERE cantidad<=0
UNION ALL SELECT 'movimiento_inventario', id_movimiento FROM movimiento_inventario WHERE cantidad<=0;

-- 5) Duplicados de producto en la misma declaración (debe ser imposible por UNIQUE).
SELECT id_declaracion,id_producto,COUNT(*) repeticiones FROM detalle_declaracion GROUP BY id_declaracion,id_producto HAVING COUNT(*)>1;

-- 6) Reconciliación por declaración/producto/bodega: entradas + traslados recibidos - salidas - traslados enviados = stock actual.
WITH mov AS (
 SELECT id_declaracion,id_producto,id_bodega_destino id_bodega,
   SUM(CASE WHEN tipo_movimiento='entrada' THEN cantidad ELSE 0 END) entradas,
   SUM(CASE WHEN tipo_movimiento='traslado' THEN cantidad ELSE 0 END) recibidos, 0 salidas, 0 enviados
 FROM movimiento_inventario WHERE tipo_movimiento='entrada' GROUP BY id_declaracion,id_producto,id_bodega_destino
 UNION ALL
 SELECT id_declaracion,id_producto,id_bodega_origen id_bodega,0,0,
   SUM(CASE WHEN tipo_movimiento='salida' THEN cantidad ELSE 0 END),
   SUM(CASE WHEN tipo_movimiento='traslado' THEN cantidad ELSE 0 END)
 FROM movimiento_inventario WHERE tipo_movimiento IN ('salida','traslado') GROUP BY id_declaracion,id_producto,id_bodega_origen
), saldo AS (
 SELECT id_declaracion,id_producto,id_bodega,SUM(entradas) entradas,SUM(recibidos) recibidos,SUM(salidas) salidas,SUM(enviados) enviados
 FROM mov GROUP BY id_declaracion,id_producto,id_bodega
)
SELECT ib.id_inventario, ib.cantidad cantidad_actual,
 COALESCE(s.entradas,0)+COALESCE(s.recibidos,0)-COALESCE(s.salidas,0)-COALESCE(s.enviados,0) saldo_calculado
FROM inventario_bodega ib LEFT JOIN saldo s USING(id_declaracion,id_producto,id_bodega)
WHERE ib.cantidad <> COALESCE(s.entradas,0)+COALESCE(s.recibidos,0)-COALESCE(s.salidas,0)-COALESCE(s.enviados,0);

-- 7) Conteo de filas por tabla (16 tablas base, cada una debe tener al menos 15 registros).
SELECT 'pais' tabla,COUNT(*) filas FROM pais UNION ALL
SELECT 'importador',COUNT(*) FROM importador UNION ALL
SELECT 'exportador',COUNT(*) FROM exportador UNION ALL
SELECT 'agente_aduanal',COUNT(*) FROM agente_aduanal UNION ALL
SELECT 'categoria_arancelaria',COUNT(*) FROM categoria_arancelaria UNION ALL
SELECT 'producto',COUNT(*) FROM producto UNION ALL
SELECT 'declaracion_aduanera',COUNT(*) FROM declaracion_aduanera UNION ALL
SELECT 'detalle_declaracion',COUNT(*) FROM detalle_declaracion UNION ALL
SELECT 'contenedor',COUNT(*) FROM contenedor UNION ALL
SELECT 'bodega',COUNT(*) FROM bodega UNION ALL
SELECT 'inventario_bodega',COUNT(*) FROM inventario_bodega UNION ALL
SELECT 'movimiento_inventario',COUNT(*) FROM movimiento_inventario UNION ALL
SELECT 'funcionario',COUNT(*) FROM funcionario UNION ALL
SELECT 'inspeccion',COUNT(*) FROM inspeccion UNION ALL
SELECT 'transportista',COUNT(*) FROM transportista UNION ALL
SELECT 'evento_declaracion',COUNT(*) FROM evento_declaracion;
