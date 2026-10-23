-- Consultas de negocio. Valores esperados calculados con el conjunto de prueba ficticio.
-- Nota de verificación: los resultados se calcularon con una base SQLite de compatibilidad; la ejecución contra MySQL 8.0 sigue pendiente.

-- Q1: Declaraciones de importación durante octubre de 2026
-- Resultado de referencia calculado: total_importaciones_octubre=6
SELECT COUNT(*) AS total_importaciones_octubre
FROM declaracion_aduanera
WHERE regimen = 'importacion'
  AND fecha >= '2026-10-01' AND fecha < '2026-11-01';

-- Q2: Mercancías retenidas originarias de China en bodega 2
-- Resultado de referencia calculado: 2 filas; primera fila: numero_declaracion=DA-2026-0001; producto=Computadora portátil empresarial; cantidad=72; unidad_medida=unidad; bodega=Bodega de Inspección 2; pais_origen=China
SELECT da.numero_declaracion, pr.descripcion AS producto, ib.cantidad, pr.unidad_medida,
       b.nombre AS bodega, pa.nombre AS pais_origen
FROM inventario_bodega ib
JOIN producto pr ON pr.id_producto = ib.id_producto
JOIN bodega b ON b.id_bodega = ib.id_bodega
JOIN declaracion_aduanera da ON da.id_declaracion = ib.id_declaracion
JOIN pais pa ON pa.id_pais = da.id_pais_origen
WHERE ib.estado = 'retenido' AND pa.codigo_iso = 'CN' AND b.id_bodega = 2
ORDER BY da.fecha, pr.descripcion;

-- Q3: País de origen con más contenedores asociados a declaraciones
-- Resultado de referencia calculado: pais_origen=China; total_contenedores=3
SELECT pa.nombre AS pais_origen, COUNT(DISTINCT c.id_contenedor) AS total_contenedores
FROM pais pa
JOIN declaracion_aduanera da ON da.id_pais_origen = pa.id_pais AND da.regimen = 'importacion'
JOIN contenedor c ON c.id_declaracion = da.id_declaracion
GROUP BY pa.id_pais, pa.nombre
ORDER BY total_contenedores DESC, pa.nombre ASC
LIMIT 1;

-- Q4: Importador con mayor valor declarado
-- Resultado de referencia calculado: importador=Distribuciones Bahía Verde Ltda.; valor_total_declarado=53298.63
SELECT i.razon_social AS importador,
       ROUND(SUM(dd.cantidad * dd.valor_unitario_declarado),2) AS valor_total_declarado
FROM importador i
JOIN declaracion_aduanera da ON da.id_importador = i.id_importador AND da.regimen = 'importacion'
JOIN detalle_declaracion dd ON dd.id_declaracion = da.id_declaracion
GROUP BY i.id_importador, i.razon_social
ORDER BY valor_total_declarado DESC, i.razon_social ASC
LIMIT 1;

-- Q5: Inspecciones con observaciones y funcionario responsable
-- Resultado de referencia calculado: 6 filas; primera fila: id_inspeccion=3; numero_declaracion=DA-2026-0021; fecha=2026-10-24 09:21:00; observaciones=Se solicita ampliar evidencia del valor declarado.; funcionario=Valentina Ruiz; cargo=Inspector aduanero
SELECT ins.id_inspeccion, da.numero_declaracion, ins.fecha,
       ins.observaciones, f.nombre AS funcionario, f.cargo
FROM inspeccion ins
JOIN declaracion_aduanera da ON da.id_declaracion = ins.id_declaracion
JOIN funcionario f ON f.id_funcionario = ins.id_funcionario
WHERE ins.resultado = 'Con observaciones'
ORDER BY ins.fecha DESC;

-- Q6: Stock actual por producto en todas las bodegas
-- Resultado de referencia calculado: 30 filas; primera fila: id_producto=12; producto=Aire acondicionado compacto; unidad_medida=unidad; stock_total=235
SELECT p.id_producto, p.descripcion AS producto, p.unidad_medida,
       SUM(ib.cantidad) AS stock_total
FROM inventario_bodega ib
JOIN producto p ON p.id_producto = ib.id_producto
GROUP BY p.id_producto, p.descripcion, p.unidad_medida
ORDER BY p.descripcion;

-- Q7: Declaraciones que todavía no están liberadas o cerradas
-- Resultado de referencia calculado: 16 filas; primera fila: numero_declaracion=DA-2026-0024; fecha=2026-09-03; regimen=deposito; estado=pendiente; importador=Textiles Prisma S.R.L.; exportador=NULL; parte_comercial=Textiles Prisma S.R.L.; pais_origen=Vietnam
SELECT da.numero_declaracion, da.fecha, da.regimen, da.estado,
       i.razon_social AS importador, e.razon_social AS exportador,
       COALESCE(i.razon_social,e.razon_social) AS parte_comercial, pa.nombre AS pais_origen
FROM declaracion_aduanera da
LEFT JOIN importador i ON i.id_importador = da.id_importador
LEFT JOIN exportador e ON e.id_exportador = da.id_exportador
JOIN pais pa ON pa.id_pais = da.id_pais_origen
WHERE da.estado IN ('pendiente','en_revision','retenida')
ORDER BY da.fecha, da.numero_declaracion;

-- Q8: Bodegas ordenadas por ocupación física respecto de capacidad
-- Resultado de referencia calculado: 15 filas; primera fila: id_bodega=5; nombre=Bodega de Alto Valor; capacidad_kg=3471; ocupacion_kg=3367.17; porcentaje_ocupacion=97.01
SELECT b.id_bodega, b.nombre, b.capacidad_kg,
       ROUND(SUM(ib.cantidad * p.peso_unitario_kg),2) AS ocupacion_kg,
       ROUND(100 * SUM(ib.cantidad * p.peso_unitario_kg) / b.capacidad_kg,2) AS porcentaje_ocupacion
FROM bodega b
JOIN inventario_bodega ib ON ib.id_bodega = b.id_bodega
JOIN producto p ON p.id_producto = ib.id_producto
GROUP BY b.id_bodega, b.nombre, b.capacidad_kg
ORDER BY porcentaje_ocupacion DESC, b.nombre;

-- Auditoría A1: declaraciones con país de origen inexistente. Debe devolver cero filas.
SELECT da.id_declaracion FROM declaracion_aduanera da LEFT JOIN pais p ON p.id_pais=da.id_pais_origen WHERE p.id_pais IS NULL;

-- Auditoría A2: declaraciones sin detalles. Debe devolver cero filas.
SELECT da.id_declaracion, da.numero_declaracion FROM declaracion_aduanera da LEFT JOIN detalle_declaracion dd ON dd.id_declaracion=da.id_declaracion WHERE dd.id_detalle IS NULL;

-- Auditoría A3: movimientos inválidos. Debe devolver cero filas.
SELECT id_movimiento FROM movimiento_inventario WHERE cantidad <= 0 OR (tipo_movimiento='entrada' AND (id_bodega_origen IS NOT NULL OR id_bodega_destino IS NULL)) OR (tipo_movimiento='salida' AND (id_bodega_origen IS NULL OR id_bodega_destino IS NOT NULL)) OR (tipo_movimiento='traslado' AND (id_bodega_origen IS NULL OR id_bodega_destino IS NULL OR id_bodega_origen=id_bodega_destino));

-- Auditoría A4: valores/cantidades negativos o cero. Debe devolver cero filas.
SELECT id_detalle FROM detalle_declaracion WHERE cantidad<=0 OR valor_unitario_declarado<0 UNION ALL SELECT id_inventario FROM inventario_bodega WHERE cantidad<=0 UNION ALL SELECT id_movimiento FROM movimiento_inventario WHERE cantidad<=0;

-- Auditoría A5: detalles duplicados por declaración/producto. Debe devolver cero filas.
SELECT id_declaracion,id_producto,COUNT(*) AS n FROM detalle_declaracion GROUP BY id_declaracion,id_producto HAVING COUNT(*)>1;
