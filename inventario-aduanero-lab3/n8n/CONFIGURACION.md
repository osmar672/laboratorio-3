# Configuración de n8n - Sistema de Inventario Aduanero

## Versión objetivo

- n8n: **2.44.6** (etiqueta estable consultada el 23-10-2026; ver `docker-compose.yml`).
- MySQL: imagen `mysql:8.0` (rama de parches 8.0; confirme la versión exacta con `SELECT VERSION();`).
- Agente: nodo AI Agent moderno / Tools Agent (`@n8n/n8n-nodes-langchain.agent`, versión de nodo 2.2 en la exportación).
- Modelo sugerido: OpenAI Chat Model con `gpt-4o-mini`. Puede sustituirse por otro nodo Chat Model disponible, conservando las conexiones.

El JSON se revisó como estructura JSON y sus nombres/consultas se contrastaron con el esquema del proyecto. Este entorno no tenía n8n instalado ni una instancia a la que importar el flujo, así que la importación/ejecución real queda **pendiente**. Las versiones de nodos pueden cambiar según la instancia; después de importar, compruebe que no haya nodos marcados como desconocidos y actualice desde la interfaz si n8n lo solicita.

## Importación

1. Inicie Docker Compose según `README.md` y abra `http://localhost:5678`.
2. Configure la cuenta inicial de n8n.
3. Entre a **Workflows → Import from File** e importe `Apellido_Nombre_Agente_Lab3.json`.
4. Abra cada nodo `Herramienta - ...`, cree/seleccione la misma credencial MySQL y guarde el workflow. El JSON omite de forma intencional credenciales e IDs reales.
5. Elija la credencial de **OpenAI Chat Model** o cambie el nodo de modelo por el proveedor que realmente tenga disponible.
6. Guarde el flujo y pruebe primero una consulta inocua como “¿Cuántas declaraciones de importación se registraron en octubre de 2026?”.
7. Revise **Executions** para confirmar qué tool se llamó y qué filas devolvió.

## Credencial MySQL

Cree una credencial MySQL en n8n con estos valores para el despliegue Docker del proyecto:

- Host: `mysql` (nombre del servicio Compose, no `localhost`)
- Puerto: `3306`
- Base de datos: `inventario_aduanero_lab3`
- Usuario: `agente_aduana_ro`
- Contraseña: el secreto configurado en MySQL al ejecutar `usuario_solo_lectura.sql`
- SSL: no requerido solo para la red privada local; para conexión remota use TLS y reglas de red apropiadas.

No coloque la contraseña dentro del workflow, el system prompt ni Git. Si MySQL corre fuera de Docker, el host puede ser una IP o DNS del servidor alcanzable desde n8n; si n8n corre en Docker Desktop hacia el host, el destino puede ser `host.docker.internal` según plataforma. `localhost` desde el contenedor n8n se refiere al propio contenedor n8n.

## Arquitectura de seguridad

- Todas las herramientas enlazadas usan SQL predefinido (operación `executeQuery`) con consultas SELECT o vistas autorizadas; el modelo no redacta SQL arbitrario para ejecutarlo.
- La credencial MySQL debe usar `agente_aduana_ro`, no una cuenta administrativa.
- Los nodos consultan tablas/vistas específicas y limitan filas en los listados. Los informes agregados usan un `LIMIT` donde corresponde.
- No habilite herramientas de escritura ni sustituya consultas predefinidas por `{{$fromAI('query')}}` en el campo SQL.
- La memoria Simple Memory conserva contexto corto por `sessionId`; no se utiliza para almacenar datos transaccionales ni secretos.

## Problemas frecuentes

- **Access denied**: verifique el usuario/host en `SHOW GRANTS`, que se ejecutó el script de permisos con administrador, y que la contraseña coincide.
- **Unknown database/table/view**: primero cargue el SQL completo; confirme la base `inventario_aduanero_lab3`.
- **No se resuelve `mysql`**: use el nombre del servicio únicamente dentro de la misma red Docker Compose. Verifique `docker compose ps` y `docker compose logs mysql`.
- **Modelo no responde**: cree una credencial del proveedor y selecciónela en el nodo Chat Model. No basta con importar el JSON.
- **Versión de nodo incompatible**: en n8n, abra el nodo y actualícelo/seleccione su versión actual; revise conexiones AI Agent, memory, model y tool antes de ejecutar.
- **Demasiados resultados**: reduzca el `LIMIT` en el nodo de herramienta; nunca quite el límite sin analizar primero el coste.

## Pruebas requeridas antes de entregar

Importar el workflow en n8n 2.44.6, vincular credenciales, activar modo de prueba y ejecutar todos los casos de `tests/casos_prueba.md`. Guardar capturas y export de ejecuciones reales en `evidencias/`. Las pruebas que no se ejecutaron aquí aparecen como pendientes.
