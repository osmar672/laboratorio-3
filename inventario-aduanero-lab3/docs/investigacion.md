# Investigación: bases de datos, SQL, n8n e inventario aduanero

**Laboratorio #3 de Bases de Datos**  
**Estudiante:** [Apellido Nombre]  
**Curso/sección:** [Completar] · **Fecha:** 23 de octubre de 2026

## 1. Introducción y objetivo

Una operación aduanera produce información conectada: quién importa, desde dónde procede la mercancía, qué productos declara, qué contenedor los transporta, dónde se almacenan, cuáles inspecciones se realizan y qué movimientos cambian su existencia. Si esta información se mantiene en hojas inconexas, es fácil duplicar datos o responder con cifras contradictorias. Este laboratorio propone un modelo relacional y un asistente de consulta que obtiene datos de MySQL a través de n8n. Todo el conjunto cargado es ficticio y tiene una finalidad didáctica; no representa una declaración, un arancel oficial ni un procedimiento legal vigente.

## 2. Bases de datos, SQL y modelado

### 2.1. Conceptos fundamentales

Una **base de datos** es una colección estructurada de datos relacionados. Un **sistema gestor de bases de datos (SGBD)** administra su almacenamiento, acceso concurrente, validación, seguridad, recuperación y consultas. En este proyecto, MySQL es el SGBD y `inventario_aduanero_lab3` es la base de datos que contiene las tablas del dominio.

En una base relacional, una **tabla** representa una entidad o relación; una **fila** es un registro y una **columna** es un atributo. Por ejemplo, `producto` guarda la descripción, unidad, valor y peso unitario. `DECIMAL(12,2)` resulta adecuado para dinero porque conserva una escala decimal; `DATE` expresa una fecha; `DATETIME`, un momento; `VARCHAR` guarda texto variable; e `INT` almacena identificadores. Los códigos arancelarios se tratan como texto de seis caracteres, no como un entero, para conservar ceros iniciales.

Una base **NoSQL** puede organizar información como documentos, pares clave-valor, grafos o familias de columnas. Puede ser útil para esquemas cambiantes o documentos anidados, pero no elimina la necesidad de integridad. En este caso, los documentos aduaneros, líneas de mercancía y movimientos tienen relaciones y restricciones claras, por lo que un modelo relacional es apropiado. Las bases relacionales tampoco son siempre mejores: la elección depende de las consultas, consistencia, volumen y operación esperados.

### 2.2. Claves, integridad y relaciones

La **clave primaria (PK)** identifica una fila, por ejemplo `id_declaracion`. La **clave foránea (FK)** exige que una referencia apunte a una fila existente, como `declaracion_aduanera.id_importador`. Una **clave compuesta** combina columnas; este esquema usa una restricción `UNIQUE (id_declaracion, id_producto)` en `detalle_declaracion` para impedir repetir de manera accidental el mismo producto en una declaración. Puede existir una PK artificial (`id_detalle`) y una restricción única de negocio al mismo tiempo.

Una relación **1:1** asocia una instancia con una sola de otra entidad, normalmente mediante FK única. **1:N** permite que un importador tenga muchas declaraciones, mientras cada declaración pertenece a un importador. **N:M** permite que muchas declaraciones incluyan muchos productos; se representa con la tabla intermedia `detalle_declaracion`. El modelo también incluye una relación recursiva: `funcionario.id_supervisor` se refiere a otro funcionario y admite `NULL` para la jefatura sin supervisor registrado.

La **integridad referencial** evita referencias huérfanas; los `CHECK` validan condiciones de fila. `NOT NULL` obliga a capturar un dato; `UNIQUE` evita duplicados; `DEFAULT` aporta un valor inicial, como el estado `pendiente`. Son reglas complementarias: una FK verifica existencia, no necesariamente que una operación sea legal en toda circunstancia.

### 2.3. DDL, DML, consultas y normalización

El **DDL** describe estructura (`CREATE DATABASE`, `CREATE TABLE`, índices y vistas). El **DML** consulta o modifica datos: `INSERT` añade filas, `SELECT` lee, `UPDATE` cambia y `DELETE` elimina. Una consulta `JOIN` combina tablas relacionadas; `WHERE` filtra, `GROUP BY` agrupa, las funciones `COUNT` y `SUM` agregan y `ORDER BY` ordena. Por ejemplo, el valor declarado por importador se calcula sumando `detalle_declaracion.cantidad * valor_unitario_declarado` tras enlazar el detalle con su declaración e importador. Hay que evitar joins que multipliquen filas; por eso el total no se calcula después de unir innecesariamente inspecciones y contenedores.

La normalización reduce redundancia y anomalías. En **1FN**, cada celda contiene un valor atómico y no una lista de productos. En **2FN**, cada atributo no clave depende de la clave completa; las propiedades del producto no se colocan en una relación puente con clave compuesta si dependen solo del producto. En **3FN**, se evitan dependencias transitivas: el nombre del país está en `pais`, no repetido dentro de cada declaración ni dentro de cada detalle. Para el esquema propuesto, las tablas separan catálogos, actores, documentos, líneas, existencias y eventos.

Un **diagrama entidad-relación (DER)** presenta entidades, atributos y relaciones antes de crear tablas. Chen usa entidades, relaciones y atributos como formas distintas; la notación **pata de gallo** representa cardinalidad uno o muchos en los extremos de las líneas. El archivo Mermaid del laboratorio usa esta última idea y marca PK, FK y campos únicos; el SQL es la autoridad final para los nombres y restricciones.

## 3. Comparación de gestores

| Criterio | SQLite | MySQL 8.0 | PostgreSQL |
|---|---|---|---|
| Modelo/arquitectura | Motor embebido, archivo local | Servicio cliente-servidor | Servicio cliente-servidor objeto-relacional |
| Puesta en marcha | Muy sencilla; sin servidor dedicado | Requiere instancia/credenciales | Requiere instancia/credenciales |
| Concurrencia y operación | Excelente para apps locales; menos apropiado como servidor multiusuario central | Adecuado para aplicaciones multiusuario comunes | Muy sólido en consultas complejas, integridad y extensibilidad |
| Administración | Mínima | Usuarios, privilegios, copias y monitoreo del servidor | Roles, extensiones, copias y monitoreo del servidor |
| Compatibilidad de n8n | No se usa como nodo MySQL; n8n puede emplearlo internamente | Nodo MySQL nativo y credenciales dedicadas | Nodo PostgreSQL nativo y credenciales dedicadas |
| Uso típico | Aplicación de escritorio, móvil o prototipo embebido | Aplicación web con base central | Sistemas analíticos y transaccionales que aprovechan tipos/extensiones avanzadas |

SQLite se describe oficialmente como un motor SQL transaccional autocontenido y sin servidor; PostgreSQL enfatiza capacidades objeto-relacionales, integridad y extensibilidad. Ambos son excelentes en escenarios apropiados. Se eligió **MySQL 8.0** porque es el gestor solicitado y n8n ofrece un nodo nativo para consultarlo. La elección facilita que el estudiante practique usuarios SQL, red cliente-servidor y permisos mínimos. El diseño usa InnoDB, `utf8mb4`, claves foráneas y `CHECK`; las restricciones `CHECK` se aplican desde MySQL 8.0.16.

## 4. n8n y los agentes de IA

**n8n** automatiza procesos conectando nodos. Un **workflow** es una cadena o grafo de pasos; un nodo recibe datos, ejecuta una operación y entrega una salida. Un **trigger** inicia el flujo por chat, webhook, horario o evento. Las **credenciales** guardan la autenticación del servicio en la interfaz, de forma separada del archivo JSON exportado.

Un chatbot convencional suele responder con reglas o texto generado a partir del contexto que se le entrega. Un **agente de IA** también decide cuándo llamar herramientas disponibles. Un **modelo de lenguaje (LLM)** interpreta lenguaje y produce texto o llamadas de herramientas, pero puede equivocarse; por eso no se toma como fuente de verdad para cantidades del inventario. En el flujo, Chat Trigger recibe la pregunta, el AI Agent elige una herramienta de lectura, el nodo MySQL devuelve filas y el modelo las explica en español. Simple Memory retiene contexto de conversación durante la sesión; no reemplaza la persistencia de la base de datos.

El workflow preparado usa el agente moderno **Tools Agent** y herramientas MySQL que ejecutan consultas predefinidas de solo lectura o SELECT sobre vistas. No ofrece al modelo una caja de texto SQL abierta: la SQL reside en los nodos, reduce la superficie para inyección y permite revisar cada consulta. La cuenta `agente_aduana_ro` solo recibe `SELECT`; los nodos no tienen una credencial dentro del JSON y deben vincularse en n8n después de importarlo.

La seguridad exige capas independientes. Un prompt que dice “no borres datos” es una instrucción lingüística, no un control de acceso. La base de datos debe impedir `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `CREATE`, `GRANT` y consultas a esquemas ajenos. Las consultas deben ser limitadas, predefinidas o validadas con un parser SQL adecuado si el sistema permite generar SQL dinámico. No basta con expresiones regulares para analizar todas las formas de SQL. En este laboratorio, las tools aprobadas usan SQL fijo; los filtros libres se obtienen mediante herramientas de selección sobre vistas conocidas. El usuario de lectura tampoco debe acceder a tablas del sistema ni secretos. Los errores técnicos se registran para mantenimiento sin mostrar contraseñas al usuario.

## 5. Dominio aduanero

Una **aduana** controla la entrada, salida y tránsito de mercancías, recauda tributos cuando proceden y verifica restricciones/documentos. Una **declaración aduanera** identifica una operación y enlaza al importador o exportador según el régimen, al agente, a los países de origen y destino, a los detalles y al estado. Una **partida del Sistema Armonizado (SA/HS)** es un código de clasificación internacional: la Organización Mundial de Aduanas describe el HS como una nomenclatura de grupos de mercancías identificados internacionalmente por códigos de seis dígitos. El arancel es un derecho o porcentaje aplicable según producto, origen y régimen legal; no hay una tasa universal para todos los países o mercancías.

Los regímenes aquí simulados son: **importación**, ingreso para el mercado interno; **exportación**, salida al exterior; **tránsito**, traslado bajo control hacia otro punto; y **depósito**, almacenamiento temporal bajo control aduanero. Un **agente aduanal** representa o asiste en trámites según la normativa local, pero sus facultades concretas varían. Una mercancía **retenida** queda bloqueada para despacho hasta completar la revisión; una mercancía **liberada** puede continuar según las reglas del ejercicio. La declaración `pendiente` o `en_revision` no equivale automáticamente a una resolución legal.

Los valores arancelarios, los estados disponibles y las reglas de transición son simplificaciones académicas. No sustituyen legislación, criterios de clasificación, reglas de origen, permisos sanitarios, ni sistemas oficiales de Costa Rica u otra jurisdicción. La clasificación y arancel reales deben confirmarse con la autoridad competente y la nomenclatura vigente para la fecha y país aplicables.

## 6. Uso responsable de IA en el desarrollo

La IA puede apoyar al estudiante para explorar alternativas de normalización, generar datos sintéticos, explicar errores de sintaxis y redactar casos de prueba. No demuestra por sí sola que un script sea correcto ni que un workflow se haya ejecutado. En el artefacto presente se distinguieron las verificaciones del conjunto de prueba realizadas mediante un motor SQLite de compatibilidad de las comprobaciones aún pendientes contra una instancia MySQL 8.0 real y n8n.

Prompts reutilizables:

1. **Diseño del esquema:** “Propón un modelo 3FN para declaraciones, productos, inventario por bodega y movimientos. Identifica PK/FK, cardinalidades, estados y restricciones; devuelve una lista de supuestos a revisar”.
2. **Datos sintéticos:** “Genera registros ficticios coherentes con claves foráneas válidas, más de 15 filas por tabla y diversidad de estados y fechas. No uses datos personales reales”.
3. **Depuración SQL:** “Analiza este error de MySQL junto con la definición exacta de tabla. Señala la causa, propone una corrección mínima y una prueba negativa que demuestre la restricción”.
4. **Agente n8n:** “Diseña un agente Tools Agent sin credenciales incrustadas. Propón herramientas de consulta predefinidas y concede solo SELECT al usuario SQL. Indica qué pruebas requieren un servicio real”.

La revisión manual debe comprobar claves foráneas, columnas y nombres, cálculos, integridad del libro de movimientos, permisos efectivos, JSON de workflow e interacciones reales. El estudiante debe ejecutar los scripts y registrar los resultados en su propia instalación antes de declarar pruebas aprobadas. La IA es una herramienta de apoyo: la responsabilidad académica incluye comprender y poder explicar las decisiones del modelo.

## 7. Conclusiones

La trazabilidad depende de separar la declaración, sus detalles, los catálogos y el inventario físico. El vínculo de existencias a declaración conserva el origen, y la bitácora permite auditar entradas, salidas y traslados. La IA facilita preguntas en lenguaje natural, pero solo es fiable cuando obtiene datos del sistema, declara límites y cuenta con permisos reducidos. El siguiente paso obligatorio de validación es importar y ejecutar el proyecto con MySQL 8.0 y n8n, revisar resultados reales y guardar capturas propias.

## Bibliografía y fuentes oficiales

1. Oracle. *MySQL 8.0 Reference Manual: CREATE TABLE Statement*. https://dev.mysql.com/doc/refman/8.0/en/create-table.html (consulta: 23-10-2026).
2. Oracle. *MySQL 8.0 Reference Manual: GRANT Statement*. https://dev.mysql.com/doc/refman/8.0/en/grant.html (consulta: 23-10-2026).
3. n8n. *AI Agent node documentation*. https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/ (consulta: 23-10-2026).
4. n8n. *MySQL node documentation*. https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.mysql/ (consulta: 23-10-2026).
5. n8n. *Releases*. https://github.com/n8n-io/n8n/releases/ (consulta: 23-10-2026; versión estable consultada: 2.44.6, publicada el 22-10-2026).
6. Docker. *Define services in Docker Compose*. https://docs.docker.com/reference/compose-file/services/ (consulta: 23-10-2026).
7. Docker. *Define and manage volumes in Docker Compose*. https://docs.docker.com/reference/compose-file/volumes/ (consulta: 23-10-2026).
8. SQLite Project. *About SQLite*. https://sqlite.org/about.html (consulta: 23-10-2026).
9. PostgreSQL Global Development Group. *What Is PostgreSQL?*. https://www.postgresql.org/docs/current/intro-whatis.html (consulta: 23-10-2026).
10. World Customs Organization (WCO/OMA). *What is the Harmonized System (HS)?*. https://www.wcoomd.org/en/topics/nomenclature/overview/harmonized_system_faq.aspx?p=1 (consulta: 23-10-2026).
