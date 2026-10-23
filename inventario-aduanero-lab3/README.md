# Sistema de Inventario Aduanero - Laboratorio #3

Proyecto académico con MySQL 8.0, 16 tablas relacionales, datos ficticios relacionados, consultas de negocio, control SQL de solo lectura y un workflow n8n con agente de IA. La base y los registros son ejemplos sintéticos, no datos oficiales. Los permisos son importantes: nunca conecte el agente usando una cuenta administrativa.

## Estado de verificación

- Esquema y datos: generados; 16 tablas base y al menos 15 filas por tabla.
- Consultas de referencia: ejecutadas en una base SQLite de compatibilidad construida desde el SQL del proyecto para calcular resultados de los datos ficticios.
- MySQL 8.0 real, Docker y n8n no estaban instalados/disponibles en el entorno de preparación. Por eso siguen pendientes la importación de MySQL, la prueba real del script de permisos y la ejecución del workflow con credenciales/modelo.
- JSON del workflow: validado sintácticamente como JSON; la importación en n8n real sigue pendiente. Consulte `n8n/CONFIGURACION.md`.

## Requisitos

- Docker Engine y Docker Compose v2.
- Navegador web moderno.
- Una cuenta de n8n local.
- Un proveedor de modelo de lenguaje y su credencial creada dentro de n8n (por ejemplo OpenAI); no se incluye ninguna API key.
- Cliente mysql dentro del contenedor o herramienta gráfica compatible con MySQL 8.0.

## Inicio rápido en Docker

1. Copie `.env.example` a `.env`.
2. Edite `.env` y reemplace todos los marcadores por secretos únicos. `N8N_ENCRYPTION_KEY` debe ser una cadena aleatoria larga y quedar constante entre reinicios; cambiarla puede impedir leer credenciales ya almacenadas.
3. Inicie los servicios:

   ```bash
   docker compose up -d
   docker compose ps
   docker compose logs --tail=100 mysql n8n
   ```

4. Espere a que `mysql` y `n8n` estén sanos. Abra `http://localhost:5678` y cree la cuenta inicial de n8n.
5. Cargue la base de datos ficticia. El siguiente script elimina y vuelve a crear SOLO `inventario_aduanero_lab3`; confirme el nombre antes de usarlo:

   ```bash
   docker compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot' < sql/Apellido_Nombre_Aduana_Lab3.sql
   ```

   El comando pasa la contraseña mediante la variable de entorno dentro del contenedor local y no la incluye en el archivo SQL ni en el repositorio.

6. Cree el usuario de lectura sin escribir la contraseña en el SQL versionado. Genere un secreto aleatorio, guárdelo en un gestor de contraseñas y aplíquelo en memoria al enviar el script a MySQL:

   ```bash
   export AGENTE_DB_PASSWORD="$(openssl rand -hex 32)"
   # Guarde el valor de AGENTE_DB_PASSWORD en su gestor de contraseñas.
   sed "s|CAMBIAR_POR_UNA_CONTRASENA_LARGA|${AGENTE_DB_PASSWORD}|g" sql/usuario_solo_lectura.sql      | docker compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot'
   ```

   Esta sustitución no modifica el archivo fuente y no requiere introducir una contraseña en un prompt de SQL. Luego use el mismo secreto al crear la credencial MySQL de n8n. Ejecute el script únicamente con una cuenta administrativa autorizada; no guarde el secreto en Git ni en `.env.example`.

7. Verifique la carga:

   ```bash
   docker compose exec mysql mysql -uroot -p -D inventario_aduanero_lab3 -e "SHOW TABLES; SELECT COUNT(*) FROM declaracion_aduanera; SELECT COUNT(*) FROM inventario_bodega; SELECT VERSION();"
   ```

8. Revise `SHOW GRANTS FOR 'agente_aduana_ro'@'%';`. Debe mostrar solo privilegios de `SELECT` sobre las tablas/vistas indicadas. Pruebe con cautela que un `UPDATE` de prueba no se ejecuta (se espera ERROR 1142); no cambie datos en la entrega que usará para evidencia.
9. Importe `n8n/Apellido_Nombre_Agente_Lab3.json`. Cree credenciales para MySQL y el proveedor Chat Model desde la interfaz de n8n. En cada nodo `Herramienta - ...`, seleccione la credencial `agente_aduana_ro` con host `mysql`, puerto `3306`, base `inventario_aduanero_lab3`. El JSON intencionalmente no incorpora credenciales.
10. Guarde el workflow y pruebe las preguntas de `tests/casos_prueba.md`. No marque casos aprobados sin mirar la ejecución en n8n y comprobar la salida de la herramienta.

## Docker: conectividad importante

El servicio `mysql` no publica 3306 en el host; el servicio `n8n` y MySQL se comunican en la red privada `aduana_privada`. Por eso, dentro de la credencial n8n el host es **`mysql`**, no `localhost`. El puerto 5678 se publica solo en `127.0.0.1` para uso local. No despliegue esta configuración directamente en una red pública sin HTTPS, gestión de secretos, firewall, backups y revisión adicional de seguridad.

Para revisar la salud y apagar/reiniciar:

```bash
docker compose ps
docker compose logs -f mysql
docker compose logs -f n8n
docker compose restart n8n
docker compose down          # conserva los volúmenes
# ¡No usar down -v si desea conservar los datos persistentes!
```

El script SQL principal elimina y crea la base nombrada al ejecutarse; esa acción reinicia sus datos. `docker compose down` conserva volúmenes; `docker compose down -v` los borra y destruye datos persistidos.

## Archivos principales

- `sql/Apellido_Nombre_Aduana_Lab3.sql`: base, esquema, restricciones, datos y vistas.
- `sql/usuario_solo_lectura.sql`: permisos mínimos.
- `sql/consultas_prueba.sql`: 8 consultas de negocio y auditorías.
- `docs/investigacion.md` y `docs/investigacion.pdf`: investigación y bibliografía oficial.
- `docs/diagrama_erd.mmd`, `.png`, `.pdf`: fuente y representaciones del DER.
- `docs/modelo_relacional.md`: cardinalidades, restricciones y normalización.
- `n8n/Apellido_Nombre_Agente_Lab3.json`: workflow importable como export estructural, pendiente de importación real en la versión local.
- `n8n/SYSTEM_PROMPT.md`: instrucciones completas del agente.
- `n8n/CONFIGURACION.md`: credenciales, nodos y resolución de errores.
- `tests/validar_datos.sql`, `tests/casos_prueba.md`: controles y pruebas.
- `tests/resultados_referencia.json`: conteos/resultados calculados desde el dataset de compatibilidad.
- `evidencias/README.md`: guía para guardar capturas reales después de ejecutar el sistema.

## Personalización académica

Busque `[Apellido Nombre]`, `Apellido_Nombre` y los campos de curso/sección. Renombre los cuatro entregables finales solo después de sustituir el marcador por el nombre real del estudiante. Revise el SQL, explique las decisiones del modelo y registre qué pruebas ejecutó personalmente antes de subir a Classroom.

## Diagrama editable en draw.io

El archivo `Apellido_Nombre_DER_Lab3.drawio` es el diagrama nativo editable para diagrams.net. Ábrelo desde https://app.diagrams.net/ mediante **Archivo → Abrir desde → Dispositivo**, o arrastra el archivo al lienzo. También está disponible como `docs/diagrama_erd.drawio`. La guía está en `docs/IMPORTAR_DRAWIO.md`.
