-- Ejecutar solo con una cuenta administradora autorizada, después del script principal.
-- Sustituya CAMBIAR_POR_UNA_CONTRASENA_LARGA por un secreto único fuera del repositorio.
-- Arquitectura Docker local: MySQL no publica 3306 en el host y solo participa en la red privada.
-- El host '%' se usa para resolver direcciones dinámicas de los contenedores en la red privada;
-- no publique el puerto MySQL. En un entorno estable, restrinja el host a la IP/subred de n8n.
CREATE USER IF NOT EXISTS 'agente_aduana_ro'@'%' IDENTIFIED BY 'CAMBIAR_POR_UNA_CONTRASENA_LARGA';
ALTER USER 'agente_aduana_ro'@'%' WITH MAX_QUERIES_PER_HOUR 600 MAX_USER_CONNECTIONS 8;
GRANT SELECT ON inventario_aduanero_lab3.pais TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.importador TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.exportador TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.agente_aduanal TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.categoria_arancelaria TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.producto TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.declaracion_aduanera TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.detalle_declaracion TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.contenedor TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.bodega TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.inventario_bodega TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.movimiento_inventario TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.funcionario TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.inspeccion TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.transportista TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.evento_declaracion TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.vw_inventario_consulta TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.vw_declaraciones_consulta TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.vw_inspecciones_consulta TO 'agente_aduana_ro'@'%';
GRANT SELECT ON inventario_aduanero_lab3.vw_ocupacion_bodega TO 'agente_aduana_ro'@'%';
-- Verificación administrativa: SHOW GRANTS FOR 'agente_aduana_ro'@'%';
-- Una prueba controlada de UPDATE/DELETE debe fallar con ERROR 1142 (privilegio insuficiente).
