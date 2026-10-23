# Informe de validación local

Fecha: 2026-10-23

- Tablas base: 16.
- Filas por tabla: {"agente_aduanal": 15, "bodega": 15, "categoria_arancelaria": 18, "contenedor": 30, "declaracion_aduanera": 30, "detalle_declaracion": 60, "evento_declaracion": 45, "exportador": 18, "funcionario": 18, "importador": 18, "inspeccion": 24, "inventario_bodega": 72, "movimiento_inventario": 92, "pais": 18, "producto": 30, "transportista": 15}.
- Consultas funcionales documentadas: 8.
- Vistas de lectura: 4.
- Herramientas MySQL en workflow exportado: 10.
- JSON parseable: sí.
- Referencias a tablas en consultas conocidas: sí.
- Claves foráneas huérfanas en harness SQLite: 0.
- Declaraciones sin detalles: 0.
- Movimientos inválidos: 0.
- Duplicados declaración/producto: 0.
- Valores/cantidades inválidos: 0.
- Diferencias libro de movimientos vs existencias: 0.

**Limitación:** la validación de SQL/datos usó SQLite como motor de compatibilidad para ejecutar las consultas del conjunto; no reemplaza la prueba real con MySQL 8.0. No se encontró Docker, MySQL ni n8n instalados en el entorno. El workflow fue parseado como JSON, pero su importación y ejecución dentro de n8n quedan pendientes. No hay capturas reales adjuntas ni pruebas del agente marcadas como aprobadas.
