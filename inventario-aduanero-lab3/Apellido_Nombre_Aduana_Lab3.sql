-- Sistema de Inventario Aduanero - Laboratorio #3 de Bases de Datos
-- Integrantes: [Apellido Nombre] / [Segundo integrante, si aplica]
-- Gestor: MySQL 8.0 (InnoDB, utf8mb4)
-- Fecha de creación del artefacto: 2026-10-23
-- Propósito: esquema académico con datos ficticios y consultas de control.
-- ADVERTENCIA: al ejecutarse, este script elimina SOLO la base inventario_aduanero_lab3
-- si ya existe y la recrea. Revise el nombre antes de ejecutarlo. No apuntar a una base ajena.

DROP DATABASE IF EXISTS inventario_aduanero_lab3;
CREATE DATABASE inventario_aduanero_lab3 CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE inventario_aduanero_lab3;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE pais (
  id_pais INT UNSIGNED NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  codigo_iso CHAR(2) NOT NULL,
  PRIMARY KEY (id_pais),
  CONSTRAINT uq_pais_nombre UNIQUE (nombre),
  CONSTRAINT uq_pais_iso UNIQUE (codigo_iso)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE importador (
  id_importador INT UNSIGNED NOT NULL,
  razon_social VARCHAR(160) NOT NULL,
  identificacion_fiscal VARCHAR(30) NOT NULL,
  direccion VARCHAR(220) NOT NULL,
  telefono VARCHAR(30) NOT NULL,
  correo VARCHAR(160) NOT NULL,
  PRIMARY KEY (id_importador),
  CONSTRAINT uq_importador_identificacion UNIQUE (identificacion_fiscal),
  CONSTRAINT uq_importador_correo UNIQUE (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE exportador (
  id_exportador INT UNSIGNED NOT NULL,
  razon_social VARCHAR(160) NOT NULL,
  identificacion_fiscal VARCHAR(30) NOT NULL,
  direccion VARCHAR(220) NOT NULL,
  telefono VARCHAR(30) NOT NULL,
  correo VARCHAR(160) NOT NULL,
  PRIMARY KEY (id_exportador),
  CONSTRAINT uq_exportador_identificacion UNIQUE (identificacion_fiscal),
  CONSTRAINT uq_exportador_correo UNIQUE (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE agente_aduanal (
  id_agente INT UNSIGNED NOT NULL,
  nombre VARCHAR(140) NOT NULL,
  numero_licencia VARCHAR(40) NOT NULL,
  telefono VARCHAR(30) NOT NULL,
  correo VARCHAR(160) NOT NULL,
  PRIMARY KEY (id_agente),
  CONSTRAINT uq_agente_licencia UNIQUE (numero_licencia),
  CONSTRAINT uq_agente_correo UNIQUE (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE categoria_arancelaria (
  id_categoria INT UNSIGNED NOT NULL,
  codigo_sa CHAR(6) NOT NULL COMMENT 'Código HS representativo de seis dígitos; validar jurisdicción',
  descripcion VARCHAR(220) NOT NULL,
  porcentaje_arancel DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (id_categoria),
  CONSTRAINT uq_categoria_codigo_sa UNIQUE (codigo_sa),
  CONSTRAINT chk_categoria_arancel CHECK (porcentaje_arancel >= 0 AND porcentaje_arancel <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE producto (
  id_producto INT UNSIGNED NOT NULL,
  descripcion VARCHAR(220) NOT NULL,
  unidad_medida VARCHAR(30) NOT NULL,
  valor_unitario DECIMAL(12,2) NOT NULL,
  peso_unitario_kg DECIMAL(10,3) NOT NULL,
  id_categoria INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_producto),
  CONSTRAINT chk_producto_valor CHECK (valor_unitario >= 0),
  CONSTRAINT chk_producto_peso CHECK (peso_unitario_kg > 0),
  CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria) REFERENCES categoria_arancelaria(id_categoria) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_producto_categoria (id_categoria),
  INDEX idx_producto_descripcion (descripcion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE funcionario (
  id_funcionario INT UNSIGNED NOT NULL,
  nombre VARCHAR(140) NOT NULL,
  cargo VARCHAR(100) NOT NULL,
  id_supervisor INT UNSIGNED NULL,
  PRIMARY KEY (id_funcionario),
  CONSTRAINT fk_funcionario_supervisor FOREIGN KEY (id_supervisor) REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_funcionario_supervisor (id_supervisor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE transportista (
  id_transportista INT UNSIGNED NOT NULL,
  razon_social VARCHAR(160) NOT NULL,
  codigo_registro VARCHAR(40) NOT NULL,
  telefono VARCHAR(30) NOT NULL,
  PRIMARY KEY (id_transportista),
  CONSTRAINT uq_transportista_codigo UNIQUE (codigo_registro)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE bodega (
  id_bodega INT UNSIGNED NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  ubicacion VARCHAR(180) NOT NULL,
  capacidad_kg DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id_bodega),
  CONSTRAINT uq_bodega_nombre UNIQUE (nombre),
  CONSTRAINT chk_bodega_capacidad CHECK (capacidad_kg > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE declaracion_aduanera (
  id_declaracion INT UNSIGNED NOT NULL,
  numero_declaracion VARCHAR(30) NOT NULL,
  fecha DATE NOT NULL,
  regimen VARCHAR(20) NOT NULL,
  estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
  id_importador INT UNSIGNED NULL,
  id_exportador INT UNSIGNED NULL,
  id_agente INT UNSIGNED NOT NULL,
  id_pais_origen INT UNSIGNED NOT NULL,
  id_pais_destino INT UNSIGNED NULL,
  PRIMARY KEY (id_declaracion),
  CONSTRAINT uq_declaracion_numero UNIQUE (numero_declaracion),
  CONSTRAINT chk_declaracion_regimen CHECK (regimen IN ('importacion','exportacion','transito','deposito')),
  CONSTRAINT chk_declaracion_estado CHECK (estado IN ('pendiente','en_revision','retenida','liberada','cerrada')),
  CONSTRAINT chk_declaracion_parte CHECK ((regimen = 'exportacion' AND id_exportador IS NOT NULL AND id_importador IS NULL) OR (regimen <> 'exportacion' AND id_importador IS NOT NULL AND id_exportador IS NULL)),
  CONSTRAINT fk_declaracion_importador FOREIGN KEY (id_importador) REFERENCES importador(id_importador) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_declaracion_exportador FOREIGN KEY (id_exportador) REFERENCES exportador(id_exportador) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_declaracion_agente FOREIGN KEY (id_agente) REFERENCES agente_aduanal(id_agente) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_declaracion_pais_origen FOREIGN KEY (id_pais_origen) REFERENCES pais(id_pais) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_declaracion_pais_destino FOREIGN KEY (id_pais_destino) REFERENCES pais(id_pais) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_declaracion_fecha_regimen (fecha, regimen),
  INDEX idx_declaracion_estado (estado),
  INDEX idx_declaracion_pais_origen (id_pais_origen),
  INDEX idx_declaracion_pais_destino (id_pais_destino)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE detalle_declaracion (
  id_detalle INT UNSIGNED NOT NULL,
  id_declaracion INT UNSIGNED NOT NULL,
  id_producto INT UNSIGNED NOT NULL,
  cantidad INT UNSIGNED NOT NULL,
  valor_unitario_declarado DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id_detalle),
  CONSTRAINT uq_detalle_declaracion_producto UNIQUE (id_declaracion, id_producto),
  CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_detalle_valor CHECK (valor_unitario_declarado >= 0),
  CONSTRAINT fk_detalle_declaracion FOREIGN KEY (id_declaracion) REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_detalle_producto (id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE contenedor (
  id_contenedor INT UNSIGNED NOT NULL,
  numero_contenedor VARCHAR(20) NOT NULL,
  tipo VARCHAR(40) NOT NULL,
  peso_kg DECIMAL(12,2) NOT NULL,
  id_transportista INT UNSIGNED NOT NULL,
  id_declaracion INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_contenedor),
  CONSTRAINT uq_contenedor_numero UNIQUE (numero_contenedor),
  CONSTRAINT chk_contenedor_peso CHECK (peso_kg > 0),
  CONSTRAINT fk_contenedor_transportista FOREIGN KEY (id_transportista) REFERENCES transportista(id_transportista) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_contenedor_declaracion FOREIGN KEY (id_declaracion) REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_contenedor_declaracion (id_declaracion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE inventario_bodega (
  id_inventario INT UNSIGNED NOT NULL,
  id_bodega INT UNSIGNED NOT NULL,
  id_producto INT UNSIGNED NOT NULL,
  id_declaracion INT UNSIGNED NOT NULL,
  cantidad INT UNSIGNED NOT NULL,
  fecha_ingreso DATE NOT NULL,
  estado VARCHAR(12) NOT NULL DEFAULT 'retenido',
  PRIMARY KEY (id_inventario),
  CONSTRAINT uq_inventario_lote_bodega UNIQUE (id_declaracion, id_producto, id_bodega),
  CONSTRAINT chk_inventario_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_inventario_estado CHECK (estado IN ('retenido','liberado')),
  CONSTRAINT fk_inventario_bodega FOREIGN KEY (id_bodega) REFERENCES bodega(id_bodega) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_inventario_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_inventario_declaracion FOREIGN KEY (id_declaracion) REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_inventario_estado_bodega (estado, id_bodega),
  INDEX idx_inventario_producto (id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE movimiento_inventario (
  id_movimiento INT UNSIGNED NOT NULL,
  tipo_movimiento VARCHAR(12) NOT NULL,
  fecha DATETIME NOT NULL,
  cantidad INT UNSIGNED NOT NULL,
  id_producto INT UNSIGNED NOT NULL,
  id_declaracion INT UNSIGNED NOT NULL,
  id_bodega_origen INT UNSIGNED NULL,
  id_bodega_destino INT UNSIGNED NULL,
  id_funcionario INT UNSIGNED NOT NULL,
  referencia VARCHAR(40) NOT NULL,
  PRIMARY KEY (id_movimiento),
  CONSTRAINT uq_movimiento_referencia UNIQUE (referencia),
  CONSTRAINT chk_movimiento_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_movimiento_tipo CHECK (tipo_movimiento IN ('entrada','salida','traslado')),
  CONSTRAINT chk_movimiento_bodegas CHECK (
    (tipo_movimiento = 'entrada' AND id_bodega_origen IS NULL AND id_bodega_destino IS NOT NULL) OR
    (tipo_movimiento = 'salida' AND id_bodega_origen IS NOT NULL AND id_bodega_destino IS NULL) OR
    (tipo_movimiento = 'traslado' AND id_bodega_origen IS NOT NULL AND id_bodega_destino IS NOT NULL AND id_bodega_origen <> id_bodega_destino)
  ),
  CONSTRAINT fk_mov_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mov_declaracion FOREIGN KEY (id_declaracion) REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mov_origen FOREIGN KEY (id_bodega_origen) REFERENCES bodega(id_bodega) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mov_destino FOREIGN KEY (id_bodega_destino) REFERENCES bodega(id_bodega) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mov_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_mov_fecha_tipo (fecha, tipo_movimiento),
  INDEX idx_mov_declaracion_producto (id_declaracion, id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE inspeccion (
  id_inspeccion INT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL,
  resultado VARCHAR(30) NOT NULL,
  observaciones VARCHAR(500) NOT NULL,
  id_declaracion INT UNSIGNED NOT NULL,
  id_funcionario INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_inspeccion),
  CONSTRAINT chk_inspeccion_resultado CHECK (resultado IN ('Conforme','Con observaciones','Rechazada','Pendiente')),
  CONSTRAINT fk_inspeccion_declaracion FOREIGN KEY (id_declaracion) REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_inspeccion_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_inspeccion_resultado_fecha (resultado, fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE evento_declaracion (
  id_evento INT UNSIGNED NOT NULL,
  id_declaracion INT UNSIGNED NOT NULL,
  fecha_hora DATETIME NOT NULL,
  tipo_evento VARCHAR(100) NOT NULL,
  descripcion VARCHAR(500) NOT NULL,
  id_funcionario INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_evento),
  CONSTRAINT fk_evento_declaracion FOREIGN KEY (id_declaracion) REFERENCES declaracion_aduanera(id_declaracion) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_evento_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_evento_declaracion_fecha (id_declaracion, fecha_hora)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Datos de prueba ficticios: no representan operaciones aduaneras reales.


INSERT INTO `pais` (`id_pais`, `nombre`, `codigo_iso`) VALUES
  (1, 'China', 'CN'),
  (2, 'Estados Unidos', 'US'),
  (3, 'Alemania', 'DE'),
  (4, 'México', 'MX'),
  (5, 'Japón', 'JP'),
  (6, 'Corea del Sur', 'KR'),
  (7, 'España', 'ES'),
  (8, 'Panamá', 'PA'),
  (9, 'Colombia', 'CO'),
  (10, 'Brasil', 'BR'),
  (11, 'Italia', 'IT'),
  (12, 'Canadá', 'CA'),
  (13, 'Taiwán', 'TW'),
  (14, 'India', 'IN'),
  (15, 'Vietnam', 'VN'),
  (16, 'Países Bajos', 'NL'),
  (17, 'Chile', 'CL'),
  (18, 'Costa Rica', 'CR');

INSERT INTO `importador` (`id_importador`, `razon_social`, `identificacion_fiscal`, `direccion`, `telefono`, `correo`) VALUES
  (1, 'Tecnología del Valle CR S.A.', 'FICT-CR-0001', '101 Avenida Académica, San José', '+506 2000-1001', 'contacto1@example.com'),
  (2, 'Comercializadora Horizonte S.R.L.', 'FICT-CR-0002', '102 Avenida Académica, San José', '+506 2000-1002', 'contacto2@example.com'),
  (3, 'ElectroNexo Centroamérica S.A.', 'FICT-CR-0003', '103 Avenida Académica, San José', '+506 2000-1003', 'contacto3@example.com'),
  (4, 'Hogar y Oficina Tica S.A.', 'FICT-CR-0004', '104 Avenida Académica, San José', '+506 2000-1004', 'contacto4@example.com'),
  (5, 'Distribuciones Bahía Verde Ltda.', 'FICT-CR-0005', '105 Avenida Académica, San José', '+506 2000-1005', 'contacto5@example.com'),
  (6, 'Agroinsumos La Cosecha S.A.', 'FICT-CR-0006', '106 Avenida Académica, San José', '+506 2000-1006', 'contacto6@example.com'),
  (7, 'Repuestos Ruta Norte S.R.L.', 'FICT-CR-0007', '107 Avenida Académica, San José', '+506 2000-1007', 'contacto7@example.com'),
  (8, 'Café y Equipo Profesional S.A.', 'FICT-CR-0008', '108 Avenida Académica, San José', '+506 2000-1008', 'contacto8@example.com'),
  (9, 'Soluciones Médicas Aurora S.A.', 'FICT-CR-0009', '109 Avenida Académica, San José', '+506 2000-1009', 'contacto9@example.com'),
  (10, 'Ferretería Central del Pacífico S.A.', 'FICT-CR-0010', '110 Avenida Académica, San José', '+506 2000-1010', 'contacto10@example.com'),
  (11, 'Mundo Solar CR S.A.', 'FICT-CR-0011', '111 Avenida Académica, San José', '+506 2000-1011', 'contacto11@example.com'),
  (12, 'Textiles Prisma S.R.L.', 'FICT-CR-0012', '112 Avenida Académica, San José', '+506 2000-1012', 'contacto12@example.com'),
  (13, 'Alimentos Puente Real S.A.', 'FICT-CR-0013', '113 Avenida Académica, San José', '+506 2000-1013', 'contacto13@example.com'),
  (14, 'Logística Mirador S.A.', 'FICT-CR-0014', '114 Avenida Académica, San José', '+506 2000-1014', 'contacto14@example.com'),
  (15, 'Papelera Roble Blanco Ltda.', 'FICT-CR-0015', '115 Avenida Académica, San José', '+506 2000-1015', 'contacto15@example.com'),
  (16, 'Innova Empaques CR S.A.', 'FICT-CR-0016', '116 Avenida Académica, San José', '+506 2000-1016', 'contacto16@example.com'),
  (17, 'Clima y Energía del Istmo S.A.', 'FICT-CR-0017', '117 Avenida Académica, San José', '+506 2000-1017', 'contacto17@example.com'),
  (18, 'Importaciones Río Claro S.R.L.', 'FICT-CR-0018', '118 Avenida Académica, San José', '+506 2000-1018', 'contacto18@example.com');

INSERT INTO `exportador` (`id_exportador`, `razon_social`, `identificacion_fiscal`, `direccion`, `telefono`, `correo`) VALUES
  (1, 'Exportaciones Brisa del Pacífico S.A.', 'FICT-EXP-0001', '201 Avenida de Exportación, San José', '+506 2100-3001', 'exporta1@example.com'),
  (2, 'Cacao y Café de Altura Ltda.', 'FICT-EXP-0002', '202 Avenida de Exportación, San José', '+506 2100-3002', 'exporta2@example.com'),
  (3, 'Manufacturas Ticas del Norte S.A.', 'FICT-EXP-0003', '203 Avenida de Exportación, San José', '+506 2100-3003', 'exporta3@example.com'),
  (4, 'Muebles Roble Dorado S.R.L.', 'FICT-EXP-0004', '204 Avenida de Exportación, San José', '+506 2100-3004', 'exporta4@example.com'),
  (5, 'Alimentos Valle Claro S.A.', 'FICT-EXP-0005', '205 Avenida de Exportación, San José', '+506 2100-3005', 'exporta5@example.com'),
  (6, 'Textiles Viento Sur Ltda.', 'FICT-EXP-0006', '206 Avenida de Exportación, San José', '+506 2100-3006', 'exporta6@example.com'),
  (7, 'Dispositivos Médicos del Caribe S.A.', 'FICT-EXP-0007', '207 Avenida de Exportación, San José', '+506 2100-3007', 'exporta7@example.com'),
  (8, 'Componentes Verdes Centroamericanos S.A.', 'FICT-EXP-0008', '208 Avenida de Exportación, San José', '+506 2100-3008', 'exporta8@example.com'),
  (9, 'Productos Marinos Costa Azul S.A.', 'FICT-EXP-0009', '209 Avenida de Exportación, San José', '+506 2100-3009', 'exporta9@example.com'),
  (10, 'Agroexportadora Tierra Fértil S.A.', 'FICT-EXP-0010', '210 Avenida de Exportación, San José', '+506 2100-3010', 'exporta10@example.com'),
  (11, 'Diseño y Madera Artesanal S.R.L.', 'FICT-EXP-0011', '211 Avenida de Exportación, San José', '+506 2100-3011', 'exporta11@example.com'),
  (12, 'Energía Limpia del Istmo S.A.', 'FICT-EXP-0012', '212 Avenida de Exportación, San José', '+506 2100-3012', 'exporta12@example.com'),
  (13, 'Plásticos Reutilizables CR S.A.', 'FICT-EXP-0013', '213 Avenida de Exportación, San José', '+506 2100-3013', 'exporta13@example.com'),
  (14, 'Equipos Industriales Monte Claro S.A.', 'FICT-EXP-0014', '214 Avenida de Exportación, San José', '+506 2100-3014', 'exporta14@example.com'),
  (15, 'Frutas del Trópico Export S.A.', 'FICT-EXP-0015', '215 Avenida de Exportación, San José', '+506 2100-3015', 'exporta15@example.com'),
  (16, 'Conservas Bahía Serena Ltda.', 'FICT-EXP-0016', '216 Avenida de Exportación, San José', '+506 2100-3016', 'exporta16@example.com'),
  (17, 'Químicos Técnicos Académicos S.A.', 'FICT-EXP-0017', '217 Avenida de Exportación, San José', '+506 2100-3017', 'exporta17@example.com'),
  (18, 'Empaques Biodegradables del Valle S.A.', 'FICT-EXP-0018', '218 Avenida de Exportación, San José', '+506 2100-3018', 'exporta18@example.com');

INSERT INTO `agente_aduanal` (`id_agente`, `nombre`, `numero_licencia`, `telefono`, `correo`) VALUES
  (1, 'María Fernanda Rojas', 'LIC-ACA-2021', '+506 2200-2001', 'agente1@example.com'),
  (2, 'Carlos Andrés Vega', 'LIC-ACA-2022', '+506 2200-2002', 'agente2@example.com'),
  (3, 'Daniela Solís Mora', 'LIC-ACA-2023', '+506 2200-2003', 'agente3@example.com'),
  (4, 'Esteban Quesada R.', 'LIC-ACA-2024', '+506 2200-2004', 'agente4@example.com'),
  (5, 'Valeria Chacón López', 'LIC-ACA-2025', '+506 2200-2005', 'agente5@example.com'),
  (6, 'Andrés Jiménez P.', 'LIC-ACA-2026', '+506 2200-2006', 'agente6@example.com'),
  (7, 'Paula Villalobos', 'LIC-ACA-2027', '+506 2200-2007', 'agente7@example.com'),
  (8, 'Marco A. Herrera', 'LIC-ACA-2028', '+506 2200-2008', 'agente8@example.com'),
  (9, 'Sofía Navarro C.', 'LIC-ACA-2029', '+506 2200-2009', 'agente9@example.com'),
  (10, 'Luis Diego Méndez', 'LIC-ACA-2030', '+506 2200-2010', 'agente10@example.com'),
  (11, 'Gabriela Castro', 'LIC-ACA-2031', '+506 2200-2011', 'agente11@example.com'),
  (12, 'Ricardo Salas M.', 'LIC-ACA-2032', '+506 2200-2012', 'agente12@example.com'),
  (13, 'Natalia Araya', 'LIC-ACA-2033', '+506 2200-2013', 'agente13@example.com'),
  (14, 'Felipe Brenes', 'LIC-ACA-2034', '+506 2200-2014', 'agente14@example.com'),
  (15, 'Isabel Calderón', 'LIC-ACA-2035', '+506 2200-2015', 'agente15@example.com');

INSERT INTO `categoria_arancelaria` (`id_categoria`, `codigo_sa`, `descripcion`, `porcentaje_arancel`) VALUES
  (1, '847130', 'Máquinas automáticas portátiles para procesamiento de datos', 1.0),
  (2, '851713', 'Teléfonos inteligentes', 2.0),
  (3, '847330', 'Partes y accesorios de máquinas de procesamiento de datos', 1.5),
  (4, '850440', 'Convertidores estáticos y fuentes de alimentación', 3.0),
  (5, '854442', 'Conductores eléctricos con piezas de conexión', 5.0),
  (6, '392690', 'Manufacturas diversas de plástico', 8.0),
  (7, '940360', 'Muebles de madera para otros usos', 10.0),
  (8, '610910', 'Camisetas de algodón', 12.0),
  (9, '090121', 'Café sin tostar, descafeinado o no', 0.0),
  (10, '401110', 'Neumáticos nuevos para automóviles', 8.0),
  (11, '300490', 'Medicamentos preparados para venta al por menor', 0.0),
  (12, '841510', 'Acondicionadores de aire de pared o ventana', 5.0),
  (13, '850760', 'Acumuladores eléctricos de ion de litio', 3.0),
  (14, '482110', 'Etiquetas de papel o cartón impresas', 5.0),
  (15, '940320', 'Muebles de metal', 8.0),
  (16, '420292', 'Bolsos y contenedores con superficie exterior textil', 10.0),
  (17, '732690', 'Manufacturas diversas de hierro o acero', 8.0),
  (18, '100630', 'Arroz semiblanqueado o blanqueado', 1.0);

INSERT INTO `producto` (`id_producto`, `descripcion`, `unidad_medida`, `valor_unitario`, `peso_unitario_kg`, `id_categoria`) VALUES
  (1, 'Computadora portátil empresarial', 'unidad', 685.0, 2.1, 1),
  (2, 'Teléfono inteligente gama media', 'unidad', 315.0, 0.22, 2),
  (3, 'Memoria SSD 1 TB', 'unidad', 82.5, 0.08, 3),
  (4, 'Fuente de alimentación industrial', 'unidad', 46.0, 0.65, 4),
  (5, 'Cable USB-C reforzado', 'unidad', 5.8, 0.04, 5),
  (6, 'Caja organizadora plástica', 'unidad', 3.2, 0.45, 6),
  (7, 'Escritorio de madera', 'unidad', 125.0, 28.0, 7),
  (8, 'Camiseta de algodón', 'unidad', 7.4, 0.18, 8),
  (9, 'Café tostado en saco', 'kg', 8.2, 1.0, 9),
  (10, 'Neumático para automóvil', 'unidad', 74.0, 9.3, 10),
  (11, 'Kit de curación básico', 'caja', 14.5, 0.8, 11),
  (12, 'Aire acondicionado compacto', 'unidad', 290.0, 26.0, 12),
  (13, 'Batería de litio para equipo', 'unidad', 52.0, 1.1, 13),
  (14, 'Etiquetas autoadhesivas', 'rollo', 12.0, 0.6, 14),
  (15, 'Estantería metálica', 'unidad', 95.0, 32.0, 15),
  (16, 'Bolso de viaje textil', 'unidad', 22.0, 1.0, 16),
  (17, 'Tornillería de acero', 'kg', 4.2, 1.0, 17),
  (18, 'Arroz empacado', 'kg', 1.45, 1.0, 18),
  (19, 'Monitor LED 27 pulgadas', 'unidad', 164.0, 5.4, 1),
  (20, 'Tableta de uso profesional', 'unidad', 245.0, 0.55, 2),
  (21, 'Tarjeta de red empresarial', 'unidad', 39.0, 0.12, 3),
  (22, 'Convertidor de voltaje', 'unidad', 25.0, 0.9, 4),
  (23, 'Cable de red categoría 6', 'rollo', 18.0, 1.7, 5),
  (24, 'Contenedor apilable', 'unidad', 6.5, 0.85, 6),
  (25, 'Silla de oficina', 'unidad', 88.0, 14.0, 7),
  (26, 'Chaqueta de trabajo', 'unidad', 31.0, 0.65, 8),
  (27, 'Café verde en saco', 'kg', 6.4, 1.0, 9),
  (28, 'Filtro para vehículo', 'unidad', 11.8, 0.35, 10),
  (29, 'Termómetro digital', 'unidad', 9.7, 0.08, 11),
  (30, 'Panel solar pequeño', 'unidad', 112.0, 8.5, 13);

INSERT INTO `funcionario` (`id_funcionario`, `nombre`, `cargo`, `id_supervisor`) VALUES
  (1, 'Ana Lucía Montero', 'Jefatura de Operaciones', NULL),
  (2, 'Jorge Elías Vargas', 'Coordinación de Inspección', NULL),
  (3, 'Mónica Chaves Rojas', 'Jefatura de Inventario', NULL),
  (4, 'Kevin Mora Salazar', 'Técnico de inventario', 1),
  (5, 'Sofía Campos Díaz', 'Inspector aduanero', 2),
  (6, 'Diego Ureña Solano', 'Analista de declaraciones', 3),
  (7, 'Daniela Retana', 'Oficial de bodega', 1),
  (8, 'Mauricio Leiva', 'Supervisor de turno', 2),
  (9, 'Elena Gutiérrez', 'Técnico de inventario', 3),
  (10, 'Pablo Salazar', 'Inspector aduanero', 1),
  (11, 'Andrea Porras', 'Analista de declaraciones', 2),
  (12, 'Fabián Soto', 'Oficial de bodega', 3),
  (13, 'Carolina Solano', 'Supervisor de turno', 1),
  (14, 'Tomás Méndez', 'Técnico de inventario', 2),
  (15, 'Valentina Ruiz', 'Inspector aduanero', 3),
  (16, 'Esteban Arias', 'Analista de declaraciones', 1),
  (17, 'Natalia Murillo', 'Oficial de bodega', 2),
  (18, 'José Pablo Alfaro', 'Supervisor de turno', 3);

INSERT INTO `transportista` (`id_transportista`, `razon_social`, `codigo_registro`, `telefono`) VALUES
  (1, 'Carga Tica Integral S.A.', 'CR-TR-001', '001-002-003'),
  (2, 'Logística del Istmo S.R.L.', 'CR-TR-002', '002-003-004'),
  (3, 'Transporte Global Centroamérica', 'CR-TR-003', '003-004-005'),
  (4, 'Pacífico Cargo Lines', 'CR-TR-004', '004-005-006'),
  (5, 'Ruta Segura Internacional', 'CR-TR-005', '005-006-007'),
  (6, 'Fletes La Unión', 'CR-TR-006', '006-007-008'),
  (7, 'Contenedores del Caribe', 'CR-TR-007', '007-008-009'),
  (8, 'Aduana Express Logistics', 'CR-TR-008', '008-009-010'),
  (9, 'Intermodal Horizonte', 'CR-TR-009', '009-010-011'),
  (10, 'Carga y Más CR', 'CR-TR-010', '010-011-012'),
  (11, 'Nexo Transportes', 'CR-TR-011', '011-012-013'),
  (12, 'Servicios Portuarios del Valle', 'CR-TR-012', '012-013-014'),
  (13, 'Distribución Montaña Azul', 'CR-TR-013', '013-014-015'),
  (14, 'Red Logística Central', 'CR-TR-014', '014-015-016'),
  (15, 'Transporte Mercurio', 'CR-TR-015', '015-016-017');

INSERT INTO `bodega` (`id_bodega`, `nombre`, `ubicacion`, `capacidad_kg`) VALUES
  (1, 'Bodega Central Norte', 'Zona primaria - sector A', 4179),
  (2, 'Bodega de Inspección 2', 'Zona de revisión - andén 2', 651),
  (3, 'Bodega Fiscal Este', 'Complejo fiscal - módulo E', 608),
  (4, 'Bodega de Carga General', 'Patio de carga - nave 4', 205),
  (5, 'Bodega de Alto Valor', 'Área controlada - módulo H', 3471),
  (6, 'Bodega Temporal Sur', 'Patio temporal - sector S', 317),
  (7, 'Bodega Refrigerada', 'Nave con control térmico', 290),
  (8, 'Bodega de Consolidación', 'Área de consolidación', 8199),
  (9, 'Bodega de Exportaciones', 'Patio de salida internacional', 383),
  (10, 'Bodega de Tránsito', 'Corredor de tránsito', 3182),
  (11, 'Bodega de Retenidos', 'Zona de mercancía retenida', 2947),
  (12, 'Bodega de Liberados', 'Zona de despacho autorizado', 307),
  (13, 'Bodega Intermodal', 'Terminal intermodal', 8000),
  (14, 'Bodega de Documentación', 'Área de apoyo logístico', 464),
  (15, 'Bodega de Reserva', 'Patio de reserva', 379);

INSERT INTO `declaracion_aduanera` (`id_declaracion`, `numero_declaracion`, `fecha`, `regimen`, `estado`, `id_importador`, `id_exportador`, `id_agente`, `id_pais_origen`, `id_pais_destino`) VALUES
  (1, 'DA-2026-0001', '2026-10-01', 'importacion', 'pendiente', 5, NULL, 7, 1, 18),
  (2, 'DA-2026-0002', '2026-10-02', 'exportacion', 'liberada', NULL, 4, 14, 18, 14),
  (3, 'DA-2026-0003', '2026-10-03', 'transito', 'cerrada', 15, NULL, 6, 4, 18),
  (4, 'DA-2026-0004', '2026-10-04', 'deposito', 'pendiente', 2, NULL, 13, 11, 18),
  (5, 'DA-2026-0005', '2026-10-05', 'importacion', 'liberada', 7, NULL, 5, 2, 18),
  (6, 'DA-2026-0006', '2026-10-06', 'exportacion', 'cerrada', NULL, 12, 12, 18, 8),
  (7, 'DA-2026-0007', '2026-10-07', 'transito', 'en_revision', 17, NULL, 4, 15, 18),
  (8, 'DA-2026-0008', '2026-10-08', 'deposito', 'liberada', 4, NULL, 11, 5, 18),
  (9, 'DA-2026-0009', '2026-10-09', 'importacion', 'cerrada', 9, NULL, 3, 3, 18),
  (10, 'DA-2026-0010', '2026-10-10', 'exportacion', 'en_revision', NULL, 2, 10, 18, 2),
  (11, 'DA-2026-0011', '2026-10-11', 'transito', 'retenida', 1, NULL, 2, 9, 18),
  (12, 'DA-2026-0012', '2026-10-12', 'deposito', 'cerrada', 6, NULL, 9, 16, 18),
  (13, 'DA-2026-0013', '2026-10-13', 'importacion', 'en_revision', 11, NULL, 1, 1, 18),
  (14, 'DA-2026-0014', '2026-10-14', 'exportacion', 'retenida', NULL, 10, 8, 18, 13),
  (15, 'DA-2026-0015', '2026-10-15', 'transito', 'pendiente', 3, NULL, 15, 3, 18),
  (16, 'DA-2026-0016', '2026-10-16', 'deposito', 'en_revision', 8, NULL, 7, 10, 18),
  (17, 'DA-2026-0017', '2026-10-17', 'importacion', 'retenida', 13, NULL, 14, 4, 18),
  (18, 'DA-2026-0018', '2026-10-18', 'exportacion', 'pendiente', NULL, 18, 6, 18, 7),
  (19, 'DA-2026-0019', '2026-10-19', 'transito', 'liberada', 5, NULL, 13, 14, 18),
  (20, 'DA-2026-0020', '2026-10-20', 'deposito', 'retenida', 10, NULL, 5, 4, 18),
  (21, 'DA-2026-0021', '2026-10-21', 'importacion', 'pendiente', 15, NULL, 12, 2, 18),
  (22, 'DA-2026-0022', '2026-10-22', 'exportacion', 'liberada', NULL, 8, 4, 18, 1),
  (23, 'DA-2026-0023', '2026-09-01', 'transito', 'cerrada', 7, NULL, 11, 8, 18),
  (24, 'DA-2026-0024', '2026-09-03', 'deposito', 'pendiente', 12, NULL, 3, 15, 18),
  (25, 'DA-2026-0025', '2026-09-05', 'importacion', 'liberada', 17, NULL, 10, 6, 18),
  (26, 'DA-2026-0026', '2026-09-07', 'exportacion', 'cerrada', NULL, 16, 2, 18, 12),
  (27, 'DA-2026-0027', '2026-09-09', 'transito', 'en_revision', 9, NULL, 9, 2, 18),
  (28, 'DA-2026-0028', '2026-09-11', 'deposito', 'liberada', 14, NULL, 1, 9, 18),
  (29, 'DA-2026-0029', '2026-09-13', 'importacion', 'cerrada', 1, NULL, 8, 1, 18),
  (30, 'DA-2026-0030', '2026-09-15', 'exportacion', 'en_revision', NULL, 6, 15, 18, 6);

INSERT INTO `detalle_declaracion` (`id_detalle`, `id_declaracion`, `id_producto`, `cantidad`, `valor_unitario_declarado`) VALUES
  (1, 1, 1, 72, 674.73),
  (2, 1, 10, 63, 74.89),
  (3, 2, 2, 89, 315.0),
  (4, 2, 11, 86, 14.85),
  (5, 3, 3, 106, 83.74),
  (6, 3, 12, 109, 283.04),
  (7, 4, 4, 123, 47.38),
  (8, 4, 13, 132, 51.38),
  (9, 5, 5, 140, 5.63),
  (10, 5, 14, 55, 12.0),
  (11, 6, 6, 157, 3.15),
  (12, 6, 15, 78, 96.14),
  (13, 7, 7, 174, 125.0),
  (14, 7, 16, 101, 22.53),
  (15, 8, 8, 71, 7.51),
  (16, 8, 17, 124, 4.1),
  (17, 9, 9, 88, 8.45),
  (18, 9, 18, 47, 1.43),
  (19, 10, 10, 105, 71.78),
  (20, 10, 19, 70, 164.0),
  (21, 11, 11, 122, 14.28),
  (22, 11, 20, 93, 247.94),
  (23, 12, 12, 139, 290.0),
  (24, 12, 21, 116, 39.94),
  (25, 13, 13, 156, 52.78),
  (26, 13, 22, 139, 24.4),
  (27, 14, 14, 173, 12.36),
  (28, 14, 23, 62, 17.78),
  (29, 15, 15, 70, 92.15),
  (30, 15, 24, 85, 6.5),
  (31, 16, 16, 87, 21.67),
  (32, 16, 25, 108, 89.06),
  (33, 17, 17, 104, 4.2),
  (34, 17, 26, 131, 31.74),
  (35, 18, 18, 121, 1.47),
  (36, 18, 27, 54, 6.25),
  (37, 19, 19, 138, 168.92),
  (38, 19, 28, 77, 11.66),
  (39, 20, 20, 155, 237.65),
  (40, 20, 29, 100, 9.7),
  (41, 21, 21, 172, 38.41),
  (42, 21, 30, 123, 113.34),
  (43, 22, 22, 69, 25.0),
  (44, 22, 1, 46, 701.44),
  (45, 23, 23, 86, 18.27),
  (46, 23, 2, 69, 307.44),
  (47, 24, 24, 103, 6.7),
  (48, 24, 3, 92, 81.51),
  (49, 25, 25, 120, 85.36),
  (50, 25, 4, 115, 46.0),
  (51, 26, 26, 137, 30.54),
  (52, 26, 5, 138, 5.87),
  (53, 27, 27, 154, 6.4),
  (54, 27, 6, 61, 3.28),
  (55, 28, 28, 171, 11.98),
  (56, 28, 7, 84, 122.0),
  (57, 29, 29, 68, 9.99),
  (58, 29, 8, 107, 7.31),
  (59, 30, 30, 85, 108.64),
  (60, 30, 9, 130, 8.2);

INSERT INTO `contenedor` (`id_contenedor`, `numero_contenedor`, `tipo`, `peso_kg`, `id_transportista`, `id_declaracion`) VALUES
  (1, 'TCLU0000013', '20 pies', 2413, 7, 1),
  (2, 'TCLU0000026', '40 pies', 3026, 14, 2),
  (3, 'TCLU0000039', '40 pies HC', 3639, 6, 3),
  (4, 'TCLU0000042', 'Refrigerado', 4252, 13, 4),
  (5, 'TCLU0000055', 'Open top', 4865, 5, 5),
  (6, 'TCLU0000068', '20 pies', 5478, 12, 6),
  (7, 'TCLU0000071', '40 pies', 6091, 4, 7),
  (8, 'TCLU0000084', '40 pies HC', 6704, 11, 8),
  (9, 'TCLU0000097', 'Refrigerado', 7317, 3, 9),
  (10, 'TCLU0000100', 'Open top', 7930, 10, 10),
  (11, 'TCLU0000113', '20 pies', 8543, 2, 11),
  (12, 'TCLU0000126', '40 pies', 9156, 9, 12),
  (13, 'TCLU0000139', '40 pies HC', 9769, 1, 13),
  (14, 'TCLU0000142', 'Refrigerado', 10382, 8, 14),
  (15, 'TCLU0000155', 'Open top', 10995, 15, 15),
  (16, 'TCLU0000168', '20 pies', 11608, 7, 16),
  (17, 'TCLU0000171', '40 pies', 12221, 14, 17),
  (18, 'TCLU0000184', '40 pies HC', 12834, 6, 18),
  (19, 'TCLU0000197', 'Refrigerado', 13447, 13, 19),
  (20, 'TCLU0000200', 'Open top', 14060, 5, 20),
  (21, 'TCLU0000213', '20 pies', 14673, 12, 21),
  (22, 'TCLU0000226', '40 pies', 15286, 4, 22),
  (23, 'TCLU0000239', '40 pies HC', 15899, 11, 23),
  (24, 'TCLU0000242', 'Refrigerado', 16512, 3, 24),
  (25, 'TCLU0000255', 'Open top', 17125, 10, 25),
  (26, 'TCLU0000268', '20 pies', 17738, 2, 26),
  (27, 'TCLU0000271', '40 pies', 1851, 9, 27),
  (28, 'TCLU0000284', '40 pies HC', 2464, 1, 28),
  (29, 'TCLU0000297', 'Refrigerado', 3077, 8, 29),
  (30, 'TCLU0000300', 'Open top', 3690, 15, 30);

INSERT INTO `inventario_bodega` (`id_inventario`, `id_bodega`, `id_producto`, `id_declaracion`, `cantidad`, `fecha_ingreso`, `estado`) VALUES
  (1, 2, 1, 1, 72, '2026-10-01', 'retenido'),
  (2, 8, 10, 1, 63, '2026-10-01', 'retenido'),
  (3, 3, 2, 2, 89, '2026-10-02', 'liberado'),
  (4, 9, 11, 2, 86, '2026-10-02', 'liberado'),
  (5, 4, 3, 3, 49, '2026-10-03', 'liberado'),
  (6, 5, 3, 3, 49, '2026-10-03', 'liberado'),
  (7, 10, 12, 3, 101, '2026-10-03', 'liberado'),
  (8, 5, 4, 4, 123, '2026-10-04', 'retenido'),
  (9, 11, 13, 4, 132, '2026-10-04', 'retenido'),
  (10, 6, 5, 5, 140, '2026-10-05', 'liberado'),
  (11, 12, 14, 5, 27, '2026-10-05', 'liberado'),
  (12, 13, 14, 5, 28, '2026-10-05', 'liberado'),
  (13, 7, 6, 6, 152, '2026-10-06', 'liberado'),
  (14, 13, 15, 6, 73, '2026-10-06', 'liberado'),
  (15, 8, 7, 7, 174, '2026-10-07', 'retenido'),
  (16, 14, 16, 7, 101, '2026-10-07', 'retenido'),
  (17, 9, 8, 8, 35, '2026-10-08', 'liberado'),
  (18, 10, 8, 8, 36, '2026-10-08', 'liberado'),
  (19, 15, 17, 8, 124, '2026-10-08', 'liberado'),
  (20, 10, 9, 9, 80, '2026-10-09', 'liberado'),
  (21, 1, 18, 9, 39, '2026-10-09', 'liberado'),
  (22, 11, 10, 10, 105, '2026-10-10', 'retenido'),
  (23, 2, 19, 10, 35, '2026-10-10', 'retenido'),
  (24, 3, 19, 10, 35, '2026-10-10', 'retenido'),
  (25, 12, 11, 11, 122, '2026-10-11', 'retenido'),
  (26, 3, 20, 11, 93, '2026-10-11', 'retenido'),
  (27, 13, 12, 12, 134, '2026-10-12', 'liberado'),
  (28, 4, 21, 12, 111, '2026-10-12', 'liberado'),
  (29, 2, 13, 13, 78, '2026-10-13', 'retenido'),
  (30, 3, 13, 13, 78, '2026-10-13', 'retenido'),
  (31, 5, 22, 13, 139, '2026-10-13', 'retenido'),
  (32, 15, 14, 14, 173, '2026-10-14', 'retenido'),
  (33, 6, 23, 14, 62, '2026-10-14', 'retenido'),
  (34, 1, 15, 15, 70, '2026-10-15', 'retenido'),
  (35, 7, 24, 15, 42, '2026-10-15', 'retenido'),
  (36, 8, 24, 15, 43, '2026-10-15', 'retenido'),
  (37, 2, 16, 16, 87, '2026-10-16', 'retenido'),
  (38, 8, 25, 16, 108, '2026-10-16', 'retenido'),
  (39, 3, 17, 17, 104, '2026-10-17', 'retenido'),
  (40, 9, 26, 17, 131, '2026-10-17', 'retenido'),
  (41, 4, 18, 18, 60, '2026-10-18', 'retenido'),
  (42, 5, 18, 18, 61, '2026-10-18', 'retenido'),
  (43, 10, 27, 18, 54, '2026-10-18', 'retenido'),
  (44, 5, 19, 19, 138, '2026-10-19', 'liberado'),
  (45, 11, 28, 19, 77, '2026-10-19', 'liberado'),
  (46, 6, 20, 20, 155, '2026-10-20', 'retenido'),
  (47, 12, 29, 20, 50, '2026-10-20', 'retenido'),
  (48, 13, 29, 20, 50, '2026-10-20', 'retenido'),
  (49, 7, 21, 21, 172, '2026-10-21', 'retenido'),
  (50, 13, 30, 21, 123, '2026-10-21', 'retenido'),
  (51, 8, 22, 22, 69, '2026-10-22', 'liberado'),
  (52, 14, 1, 22, 46, '2026-10-22', 'liberado'),
  (53, 9, 23, 23, 43, '2026-09-01', 'liberado'),
  (54, 10, 23, 23, 43, '2026-09-01', 'liberado'),
  (55, 15, 2, 23, 69, '2026-09-01', 'liberado'),
  (56, 10, 24, 24, 103, '2026-09-03', 'retenido'),
  (57, 1, 3, 24, 92, '2026-09-03', 'retenido'),
  (58, 11, 25, 25, 120, '2026-09-05', 'liberado'),
  (59, 2, 4, 25, 57, '2026-09-05', 'liberado'),
  (60, 3, 4, 25, 58, '2026-09-05', 'liberado'),
  (61, 12, 26, 26, 137, '2026-09-07', 'liberado'),
  (62, 3, 5, 26, 138, '2026-09-07', 'liberado'),
  (63, 13, 27, 27, 154, '2026-09-09', 'retenido'),
  (64, 4, 6, 27, 61, '2026-09-09', 'retenido'),
  (65, 14, 28, 28, 85, '2026-09-11', 'liberado'),
  (66, 15, 28, 28, 86, '2026-09-11', 'liberado'),
  (67, 5, 7, 28, 84, '2026-09-11', 'liberado'),
  (68, 15, 29, 29, 68, '2026-09-13', 'liberado'),
  (69, 6, 8, 29, 107, '2026-09-13', 'liberado'),
  (70, 1, 30, 30, 85, '2026-09-15', 'retenido'),
  (71, 7, 9, 30, 65, '2026-09-15', 'retenido'),
  (72, 8, 9, 30, 65, '2026-09-15', 'retenido');

INSERT INTO `movimiento_inventario` (`id_movimiento`, `tipo_movimiento`, `fecha`, `cantidad`, `id_producto`, `id_declaracion`, `id_bodega_origen`, `id_bodega_destino`, `id_funcionario`, `referencia`) VALUES
  (1, 'entrada', '2026-10-01 08:00:00', 72, 1, 1, NULL, 2, 1, 'REC-0001'),
  (2, 'entrada', '2026-10-01 08:00:00', 63, 10, 1, NULL, 8, 1, 'REC-0002'),
  (3, 'entrada', '2026-10-02 08:00:00', 89, 2, 2, NULL, 3, 2, 'REC-0003'),
  (4, 'entrada', '2026-10-02 08:00:00', 86, 11, 2, NULL, 9, 2, 'REC-0004'),
  (5, 'entrada', '2026-10-03 08:00:00', 61, 3, 3, NULL, 4, 3, 'REC-0005'),
  (6, 'salida', '2026-10-04 10:00:00', 8, 3, 3, 4, NULL, 8, 'SAL-0005'),
  (7, 'entrada', '2026-10-03 08:00:00', 45, 3, 3, NULL, 5, 3, 'REC-0006'),
  (8, 'entrada', '2026-10-03 08:00:00', 109, 12, 3, NULL, 10, 3, 'REC-0007'),
  (9, 'salida', '2026-10-04 10:00:00', 8, 12, 3, 10, NULL, 8, 'SAL-0007'),
  (10, 'entrada', '2026-10-04 08:00:00', 123, 4, 4, NULL, 5, 4, 'REC-0008'),
  (11, 'entrada', '2026-10-04 08:00:00', 132, 13, 4, NULL, 11, 4, 'REC-0009'),
  (12, 'entrada', '2026-10-05 08:00:00', 140, 5, 5, NULL, 6, 5, 'REC-0010'),
  (13, 'entrada', '2026-10-05 08:00:00', 29, 14, 5, NULL, 12, 5, 'REC-0011'),
  (14, 'entrada', '2026-10-05 08:00:00', 26, 14, 5, NULL, 13, 5, 'REC-0012'),
  (15, 'entrada', '2026-10-06 08:00:00', 157, 6, 6, NULL, 7, 6, 'REC-0013'),
  (16, 'salida', '2026-10-07 10:00:00', 5, 6, 6, 7, NULL, 11, 'SAL-0013'),
  (17, 'entrada', '2026-10-06 08:00:00', 78, 15, 6, NULL, 13, 6, 'REC-0014'),
  (18, 'salida', '2026-10-07 10:00:00', 5, 15, 6, 13, NULL, 11, 'SAL-0014'),
  (19, 'entrada', '2026-10-07 08:00:00', 174, 7, 7, NULL, 8, 7, 'REC-0015'),
  (20, 'entrada', '2026-10-07 08:00:00', 101, 16, 7, NULL, 14, 7, 'REC-0016'),
  (21, 'entrada', '2026-10-08 08:00:00', 38, 8, 8, NULL, 9, 8, 'REC-0017'),
  (22, 'entrada', '2026-10-08 08:00:00', 33, 8, 8, NULL, 10, 8, 'REC-0018'),
  (23, 'entrada', '2026-10-08 08:00:00', 124, 17, 8, NULL, 15, 8, 'REC-0019'),
  (24, 'entrada', '2026-10-09 08:00:00', 88, 9, 9, NULL, 10, 9, 'REC-0020'),
  (25, 'salida', '2026-10-10 10:00:00', 8, 9, 9, 10, NULL, 14, 'SAL-0020'),
  (26, 'entrada', '2026-10-09 08:00:00', 47, 18, 9, NULL, 1, 9, 'REC-0021'),
  (27, 'salida', '2026-10-10 10:00:00', 8, 18, 9, 1, NULL, 14, 'SAL-0021'),
  (28, 'entrada', '2026-10-10 08:00:00', 105, 10, 10, NULL, 11, 10, 'REC-0022'),
  (29, 'entrada', '2026-10-10 08:00:00', 38, 19, 10, NULL, 2, 10, 'REC-0023'),
  (30, 'entrada', '2026-10-10 08:00:00', 32, 19, 10, NULL, 3, 10, 'REC-0024'),
  (31, 'entrada', '2026-10-11 08:00:00', 122, 11, 11, NULL, 12, 11, 'REC-0025'),
  (32, 'entrada', '2026-10-11 08:00:00', 93, 20, 11, NULL, 3, 11, 'REC-0026'),
  (33, 'entrada', '2026-10-12 08:00:00', 139, 12, 12, NULL, 13, 12, 'REC-0027'),
  (34, 'salida', '2026-10-13 10:00:00', 5, 12, 12, 13, NULL, 17, 'SAL-0027'),
  (35, 'entrada', '2026-10-12 08:00:00', 116, 21, 12, NULL, 4, 12, 'REC-0028'),
  (36, 'salida', '2026-10-13 10:00:00', 5, 21, 12, 4, NULL, 17, 'SAL-0028'),
  (37, 'entrada', '2026-10-13 08:00:00', 83, 13, 13, NULL, 2, 13, 'REC-0029'),
  (38, 'entrada', '2026-10-13 08:00:00', 73, 13, 13, NULL, 3, 13, 'REC-0030'),
  (39, 'entrada', '2026-10-13 08:00:00', 139, 22, 13, NULL, 5, 13, 'REC-0031'),
  (40, 'entrada', '2026-10-14 08:00:00', 173, 14, 14, NULL, 15, 14, 'REC-0032'),
  (41, 'entrada', '2026-10-14 08:00:00', 62, 23, 14, NULL, 6, 14, 'REC-0033'),
  (42, 'entrada', '2026-10-15 08:00:00', 70, 15, 15, NULL, 1, 15, 'REC-0034'),
  (43, 'entrada', '2026-10-15 08:00:00', 45, 24, 15, NULL, 7, 15, 'REC-0035'),
  (44, 'entrada', '2026-10-15 08:00:00', 40, 24, 15, NULL, 8, 15, 'REC-0036'),
  (45, 'entrada', '2026-10-16 08:00:00', 87, 16, 16, NULL, 2, 16, 'REC-0037'),
  (46, 'entrada', '2026-10-16 08:00:00', 108, 25, 16, NULL, 8, 16, 'REC-0038'),
  (47, 'entrada', '2026-10-17 08:00:00', 104, 17, 17, NULL, 3, 17, 'REC-0039'),
  (48, 'entrada', '2026-10-17 08:00:00', 131, 26, 17, NULL, 9, 17, 'REC-0040'),
  (49, 'entrada', '2026-10-18 08:00:00', 64, 18, 18, NULL, 4, 18, 'REC-0041'),
  (50, 'entrada', '2026-10-18 08:00:00', 57, 18, 18, NULL, 5, 18, 'REC-0042'),
  (51, 'entrada', '2026-10-18 08:00:00', 54, 27, 18, NULL, 10, 18, 'REC-0043'),
  (52, 'entrada', '2026-10-19 08:00:00', 138, 19, 19, NULL, 5, 1, 'REC-0044'),
  (53, 'entrada', '2026-10-19 08:00:00', 77, 28, 19, NULL, 11, 1, 'REC-0045'),
  (54, 'entrada', '2026-10-20 08:00:00', 155, 20, 20, NULL, 6, 2, 'REC-0046'),
  (55, 'entrada', '2026-10-20 08:00:00', 55, 29, 20, NULL, 12, 2, 'REC-0047'),
  (56, 'entrada', '2026-10-20 08:00:00', 45, 29, 20, NULL, 13, 2, 'REC-0048'),
  (57, 'entrada', '2026-10-21 08:00:00', 172, 21, 21, NULL, 7, 3, 'REC-0049'),
  (58, 'entrada', '2026-10-21 08:00:00', 123, 30, 21, NULL, 13, 3, 'REC-0050'),
  (59, 'entrada', '2026-10-22 08:00:00', 69, 22, 22, NULL, 8, 4, 'REC-0051'),
  (60, 'entrada', '2026-10-22 08:00:00', 46, 1, 22, NULL, 14, 4, 'REC-0052'),
  (61, 'entrada', '2026-09-01 08:00:00', 46, 23, 23, NULL, 9, 5, 'REC-0053'),
  (62, 'entrada', '2026-09-01 08:00:00', 40, 23, 23, NULL, 10, 5, 'REC-0054'),
  (63, 'entrada', '2026-09-01 08:00:00', 69, 2, 23, NULL, 15, 5, 'REC-0055'),
  (64, 'entrada', '2026-09-03 08:00:00', 103, 24, 24, NULL, 10, 6, 'REC-0056'),
  (65, 'entrada', '2026-09-03 08:00:00', 92, 3, 24, NULL, 1, 6, 'REC-0057'),
  (66, 'entrada', '2026-09-05 08:00:00', 120, 25, 25, NULL, 11, 7, 'REC-0058'),
  (67, 'entrada', '2026-09-05 08:00:00', 61, 4, 25, NULL, 2, 7, 'REC-0059'),
  (68, 'entrada', '2026-09-05 08:00:00', 54, 4, 25, NULL, 3, 7, 'REC-0060'),
  (69, 'entrada', '2026-09-07 08:00:00', 137, 26, 26, NULL, 12, 8, 'REC-0061'),
  (70, 'entrada', '2026-09-07 08:00:00', 138, 5, 26, NULL, 3, 8, 'REC-0062'),
  (71, 'entrada', '2026-09-09 08:00:00', 154, 27, 27, NULL, 13, 9, 'REC-0063'),
  (72, 'entrada', '2026-09-09 08:00:00', 61, 6, 27, NULL, 4, 9, 'REC-0064'),
  (73, 'entrada', '2026-09-11 08:00:00', 90, 28, 28, NULL, 14, 10, 'REC-0065'),
  (74, 'entrada', '2026-09-11 08:00:00', 81, 28, 28, NULL, 15, 10, 'REC-0066'),
  (75, 'entrada', '2026-09-11 08:00:00', 84, 7, 28, NULL, 5, 10, 'REC-0067'),
  (76, 'entrada', '2026-09-13 08:00:00', 68, 29, 29, NULL, 15, 11, 'REC-0068'),
  (77, 'entrada', '2026-09-13 08:00:00', 107, 8, 29, NULL, 6, 11, 'REC-0069'),
  (78, 'entrada', '2026-09-15 08:00:00', 85, 30, 30, NULL, 1, 12, 'REC-0070'),
  (79, 'entrada', '2026-09-15 08:00:00', 68, 9, 30, NULL, 7, 12, 'REC-0071'),
  (80, 'entrada', '2026-09-15 08:00:00', 62, 9, 30, NULL, 8, 12, 'REC-0072'),
  (81, 'traslado', '2026-10-05 13:00:00', 4, 3, 3, 4, 5, 13, 'TRA-0001'),
  (82, 'traslado', '2026-10-07 13:00:00', 2, 14, 5, 12, 13, 15, 'TRA-0002'),
  (83, 'traslado', '2026-10-10 13:00:00', 3, 8, 8, 9, 10, 18, 'TRA-0003'),
  (84, 'traslado', '2026-10-12 13:00:00', 3, 19, 10, 2, 3, 2, 'TRA-0004'),
  (85, 'traslado', '2026-10-15 13:00:00', 5, 13, 13, 2, 3, 5, 'TRA-0005'),
  (86, 'traslado', '2026-10-17 13:00:00', 3, 24, 15, 7, 8, 7, 'TRA-0006'),
  (87, 'traslado', '2026-10-20 13:00:00', 4, 18, 18, 4, 5, 10, 'TRA-0007'),
  (88, 'traslado', '2026-10-22 13:00:00', 5, 29, 20, 12, 13, 12, 'TRA-0008'),
  (89, 'traslado', '2026-09-03 13:00:00', 3, 23, 23, 9, 10, 15, 'TRA-0009'),
  (90, 'traslado', '2026-09-07 13:00:00', 4, 4, 25, 2, 3, 17, 'TRA-0010'),
  (91, 'traslado', '2026-09-13 13:00:00', 5, 28, 28, 14, 15, 2, 'TRA-0011'),
  (92, 'traslado', '2026-09-17 13:00:00', 3, 9, 30, 7, 8, 4, 'TRA-0012');

INSERT INTO `inspeccion` (`id_inspeccion`, `fecha`, `resultado`, `observaciones`, `id_declaracion`, `id_funcionario`) VALUES
  (1, '2026-10-08 09:07:00', 'Pendiente', 'Inspección agendada; resultado aún no emitido.', 7, 5),
  (2, '2026-10-16 09:14:00', 'Rechazada', 'Diferencia sustantiva entre manifiesto y mercancía.', 14, 10),
  (3, '2026-10-24 09:21:00', 'Con observaciones', 'Se solicita ampliar evidencia del valor declarado.', 21, 15),
  (4, '2026-09-11 09:28:00', 'Con observaciones', 'Se solicita ampliar evidencia del valor declarado.', 28, 2),
  (5, '2026-10-06 09:35:00', 'Conforme', 'Documentación y carga coinciden.', 5, 7),
  (6, '2026-10-14 09:42:00', 'Pendiente', 'Inspección agendada; resultado aún no emitido.', 12, 12),
  (7, '2026-10-22 09:49:00', 'Rechazada', 'Diferencia sustantiva entre manifiesto y mercancía.', 19, 17),
  (8, '2026-09-07 09:56:00', 'Rechazada', 'Diferencia sustantiva entre manifiesto y mercancía.', 26, 4),
  (9, '2026-10-04 09:03:00', 'Con observaciones', 'Se solicita ampliar evidencia del valor declarado.', 3, 9),
  (10, '2026-10-12 09:10:00', 'Conforme', 'Documentación y carga coinciden.', 10, 14),
  (11, '2026-10-20 09:17:00', 'Pendiente', 'Inspección agendada; resultado aún no emitido.', 17, 1),
  (12, '2026-09-03 09:24:00', 'Pendiente', 'Inspección agendada; resultado aún no emitido.', 24, 6),
  (13, '2026-10-02 09:31:00', 'Rechazada', 'Diferencia sustantiva entre manifiesto y mercancía.', 1, 11),
  (14, '2026-10-10 09:38:00', 'Con observaciones', 'Se solicita ampliar evidencia del valor declarado.', 8, 16),
  (15, '2026-10-18 09:45:00', 'Conforme', 'Documentación y carga coinciden.', 15, 3),
  (16, '2026-10-22 09:52:00', 'Conforme', 'Documentación y carga coinciden.', 22, 8),
  (17, '2026-09-14 09:59:00', 'Pendiente', 'Inspección agendada; resultado aún no emitido.', 29, 13),
  (18, '2026-10-08 09:06:00', 'Rechazada', 'Diferencia sustantiva entre manifiesto y mercancía.', 6, 18),
  (19, '2026-10-16 09:13:00', 'Con observaciones', 'Se solicita ampliar evidencia del valor declarado.', 13, 5),
  (20, '2026-10-20 09:20:00', 'Con observaciones', 'Se solicita ampliar evidencia del valor declarado.', 20, 10),
  (21, '2026-09-10 09:27:00', 'Conforme', 'Documentación y carga coinciden.', 27, 15),
  (22, '2026-10-06 09:34:00', 'Pendiente', 'Inspección agendada; resultado aún no emitido.', 4, 2),
  (23, '2026-10-14 09:41:00', 'Rechazada', 'Diferencia sustantiva entre manifiesto y mercancía.', 11, 7),
  (24, '2026-10-18 09:48:00', 'Rechazada', 'Diferencia sustantiva entre manifiesto y mercancía.', 18, 12);

INSERT INTO `evento_declaracion` (`id_evento`, `id_declaracion`, `fecha_hora`, `tipo_evento`, `descripcion`, `id_funcionario`) VALUES
  (1, 11, '2026-10-12 09:07:00', 'Recepción de expediente', 'Evento académico 001: seguimiento operativo registrado.', 7),
  (2, 22, '2026-10-24 10:14:00', 'Registro de declaración', 'Evento académico 002: seguimiento operativo registrado.', 14),
  (3, 3, '2026-10-06 11:21:00', 'Asignación de bodega', 'Evento académico 003: seguimiento operativo registrado.', 3),
  (4, 14, '2026-10-18 12:28:00', 'Inicio de inspección', 'Evento académico 004: seguimiento operativo registrado.', 10),
  (5, 25, '2026-09-05 13:35:00', 'Actualización de estado', 'Evento académico 005: seguimiento operativo registrado.', 17),
  (6, 6, '2026-10-07 14:42:00', 'Validación documental', 'Evento académico 006: seguimiento operativo registrado.', 6),
  (7, 17, '2026-10-19 15:49:00', 'Cierre de revisión', 'Evento académico 007: seguimiento operativo registrado.', 13),
  (8, 28, '2026-09-14 16:56:00', 'Recepción de expediente', 'Evento académico 008: seguimiento operativo registrado.', 2),
  (9, 9, '2026-10-13 08:03:00', 'Registro de declaración', 'Evento académico 009: seguimiento operativo registrado.', 9),
  (10, 20, '2026-10-20 09:10:00', 'Asignación de bodega', 'Evento académico 010: seguimiento operativo registrado.', 16),
  (11, 1, '2026-10-02 10:17:00', 'Inicio de inspección', 'Evento académico 011: seguimiento operativo registrado.', 5),
  (12, 12, '2026-10-14 11:24:00', 'Actualización de estado', 'Evento académico 012: seguimiento operativo registrado.', 12),
  (13, 23, '2026-09-04 12:31:00', 'Validación documental', 'Evento académico 013: seguimiento operativo registrado.', 1),
  (14, 4, '2026-10-08 13:38:00', 'Cierre de revisión', 'Evento académico 014: seguimiento operativo registrado.', 8),
  (15, 15, '2026-10-15 14:45:00', 'Recepción de expediente', 'Evento académico 015: seguimiento operativo registrado.', 15),
  (16, 26, '2026-09-08 15:52:00', 'Registro de declaración', 'Evento académico 016: seguimiento operativo registrado.', 4),
  (17, 7, '2026-10-09 16:59:00', 'Asignación de bodega', 'Evento académico 017: seguimiento operativo registrado.', 11),
  (18, 18, '2026-10-21 08:06:00', 'Inicio de inspección', 'Evento académico 018: seguimiento operativo registrado.', 18),
  (19, 29, '2026-09-17 09:13:00', 'Actualización de estado', 'Evento académico 019: seguimiento operativo registrado.', 7),
  (20, 10, '2026-10-10 10:20:00', 'Validación documental', 'Evento académico 020: seguimiento operativo registrado.', 14),
  (21, 21, '2026-10-22 11:27:00', 'Cierre de revisión', 'Evento académico 021: seguimiento operativo registrado.', 3),
  (22, 2, '2026-10-04 12:34:00', 'Recepción de expediente', 'Evento académico 022: seguimiento operativo registrado.', 10),
  (23, 13, '2026-10-16 13:41:00', 'Registro de declaración', 'Evento académico 023: seguimiento operativo registrado.', 17),
  (24, 24, '2026-09-07 14:48:00', 'Asignación de bodega', 'Evento académico 024: seguimiento operativo registrado.', 6),
  (25, 5, '2026-10-05 15:55:00', 'Inicio de inspección', 'Evento académico 025: seguimiento operativo registrado.', 13),
  (26, 16, '2026-10-17 16:02:00', 'Actualización de estado', 'Evento académico 026: seguimiento operativo registrado.', 2),
  (27, 27, '2026-09-11 08:09:00', 'Validación documental', 'Evento académico 027: seguimiento operativo registrado.', 9),
  (28, 8, '2026-10-11 09:16:00', 'Cierre de revisión', 'Evento académico 028: seguimiento operativo registrado.', 16),
  (29, 19, '2026-10-23 10:23:00', 'Recepción de expediente', 'Evento académico 029: seguimiento operativo registrado.', 5),
  (30, 30, '2026-09-15 11:30:00', 'Registro de declaración', 'Evento académico 030: seguimiento operativo registrado.', 12),
  (31, 11, '2026-10-12 12:37:00', 'Asignación de bodega', 'Evento académico 031: seguimiento operativo registrado.', 1),
  (32, 22, '2026-10-24 13:44:00', 'Inicio de inspección', 'Evento académico 032: seguimiento operativo registrado.', 8),
  (33, 3, '2026-10-06 14:51:00', 'Actualización de estado', 'Evento académico 033: seguimiento operativo registrado.', 15),
  (34, 14, '2026-10-18 15:58:00', 'Validación documental', 'Evento académico 034: seguimiento operativo registrado.', 4),
  (35, 25, '2026-09-05 16:05:00', 'Cierre de revisión', 'Evento académico 035: seguimiento operativo registrado.', 11),
  (36, 6, '2026-10-07 08:12:00', 'Recepción de expediente', 'Evento académico 036: seguimiento operativo registrado.', 18),
  (37, 17, '2026-10-19 09:19:00', 'Registro de declaración', 'Evento académico 037: seguimiento operativo registrado.', 7),
  (38, 28, '2026-09-14 10:26:00', 'Asignación de bodega', 'Evento académico 038: seguimiento operativo registrado.', 14),
  (39, 9, '2026-10-13 11:33:00', 'Inicio de inspección', 'Evento académico 039: seguimiento operativo registrado.', 3),
  (40, 20, '2026-10-20 12:40:00', 'Actualización de estado', 'Evento académico 040: seguimiento operativo registrado.', 10),
  (41, 1, '2026-10-02 13:47:00', 'Validación documental', 'Evento académico 041: seguimiento operativo registrado.', 17),
  (42, 12, '2026-10-14 14:54:00', 'Cierre de revisión', 'Evento académico 042: seguimiento operativo registrado.', 6),
  (43, 23, '2026-09-04 15:01:00', 'Recepción de expediente', 'Evento académico 043: seguimiento operativo registrado.', 13),
  (44, 4, '2026-10-08 16:08:00', 'Registro de declaración', 'Evento académico 044: seguimiento operativo registrado.', 2),
  (45, 15, '2026-10-15 08:15:00', 'Asignación de bodega', 'Evento académico 045: seguimiento operativo registrado.', 9);

-- Vistas de lectura para el agente: exponen lo que necesita el caso académico.
CREATE OR REPLACE VIEW vw_inventario_consulta AS
SELECT ib.id_inventario, ib.id_declaracion, da.numero_declaracion, da.fecha AS fecha_declaracion,
       da.regimen, da.estado AS estado_declaracion, i.razon_social AS importador, e.razon_social AS exportador,
       COALESCE(i.razon_social,e.razon_social) AS parte_comercial, pa.nombre AS pais_origen, pr.id_producto, pr.descripcion AS producto,
       ca.codigo_sa, ca.descripcion AS categoria_arancelaria,
       b.id_bodega, b.nombre AS bodega, ib.cantidad, ib.fecha_ingreso,
       ib.estado AS estado_inventario, pr.unidad_medida, pr.valor_unitario,
       pr.peso_unitario_kg
FROM inventario_bodega ib
JOIN declaracion_aduanera da ON da.id_declaracion = ib.id_declaracion
LEFT JOIN importador i ON i.id_importador = da.id_importador
LEFT JOIN exportador e ON e.id_exportador = da.id_exportador
JOIN pais pa ON pa.id_pais = da.id_pais_origen
JOIN producto pr ON pr.id_producto = ib.id_producto
JOIN categoria_arancelaria ca ON ca.id_categoria = pr.id_categoria
JOIN bodega b ON b.id_bodega = ib.id_bodega;

CREATE OR REPLACE VIEW vw_declaraciones_consulta AS
SELECT da.id_declaracion, da.numero_declaracion, da.fecha, da.regimen, da.estado,
       i.razon_social AS importador, e.razon_social AS exportador, COALESCE(i.razon_social,e.razon_social) AS parte_comercial, aa.nombre AS agente_aduanal, pa.nombre AS pais_origen,
       pd.nombre AS pais_destino,
       (SELECT COUNT(*) FROM contenedor c WHERE c.id_declaracion = da.id_declaracion) AS cantidad_contenedores,
       (SELECT COALESCE(SUM(dd.cantidad * dd.valor_unitario_declarado),0)
          FROM detalle_declaracion dd WHERE dd.id_declaracion = da.id_declaracion) AS valor_total_declarado
FROM declaracion_aduanera da
LEFT JOIN importador i ON i.id_importador = da.id_importador
LEFT JOIN exportador e ON e.id_exportador = da.id_exportador
JOIN agente_aduanal aa ON aa.id_agente = da.id_agente
JOIN pais pa ON pa.id_pais = da.id_pais_origen
LEFT JOIN pais pd ON pd.id_pais = da.id_pais_destino;

CREATE OR REPLACE VIEW vw_inspecciones_consulta AS
SELECT ins.id_inspeccion, ins.fecha, ins.resultado, ins.observaciones,
       da.numero_declaracion, da.regimen, i.razon_social AS importador, e.razon_social AS exportador,
       f.nombre AS funcionario, f.cargo
FROM inspeccion ins
JOIN declaracion_aduanera da ON da.id_declaracion = ins.id_declaracion
LEFT JOIN importador i ON i.id_importador = da.id_importador
LEFT JOIN exportador e ON e.id_exportador = da.id_exportador
JOIN funcionario f ON f.id_funcionario = ins.id_funcionario;

CREATE OR REPLACE VIEW vw_ocupacion_bodega AS
SELECT b.id_bodega, b.nombre, b.ubicacion, b.capacidad_kg,
       COALESCE(SUM(ib.cantidad * p.peso_unitario_kg),0) AS ocupacion_kg,
       ROUND(100 * COALESCE(SUM(ib.cantidad * p.peso_unitario_kg),0) / b.capacidad_kg,2) AS porcentaje_ocupacion
FROM bodega b
LEFT JOIN inventario_bodega ib ON ib.id_bodega = b.id_bodega
LEFT JOIN producto p ON p.id_producto = ib.id_producto
GROUP BY b.id_bodega, b.nombre, b.ubicacion, b.capacidad_kg;

