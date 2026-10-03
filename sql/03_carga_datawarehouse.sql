-- =============================================
-- CARGA AL DATA WAREHOUSE - VERSIÓN CORREGIDA
-- =============================================

-- Crear base de datos del Data Warehouse
CREATE DATABASE IF NOT EXISTS dw_optica;
USE dw_optica;

-- =============================================
-- 1. CREAR TABLAS DIMENSIONALES CON ESTRUCTURA CORREGIDA
-- =============================================

-- Dimensión Tiempo
CREATE TABLE dim_tiempo (
    id_tiempo INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE UNIQUE,
    anio INT,
    mes INT,
    dia INT,
    trimestre INT,
    nombre_mes VARCHAR(20),
    INDEX idx_fecha (fecha),
    INDEX idx_anio_mes (anio, mes)
);

-- Dimensión Cliente (corregido: aumentar longitud de campos)
CREATE TABLE dim_cliente (
    id_cliente INT PRIMARY KEY,
    nombre_cliente VARCHAR(500),
    documento VARCHAR(100),
    email VARCHAR(300),
    telefono VARCHAR(100),
    INDEX idx_nombre (nombre_cliente(100)),
    INDEX idx_documento (documento)
);

-- Dimensión Producto (corregido: aumentar longitud y precisión decimal)
CREATE TABLE dim_producto (
    id_producto INT PRIMARY KEY,
    nombre_producto VARCHAR(1000),
    modelo VARCHAR(500),
    precio_unitario DECIMAL(14,4),  -- Aumentada precisión
    INDEX idx_nombre (nombre_producto(100)),
    INDEX idx_modelo (modelo(100))
);

-- Dimensión Vendedor
CREATE TABLE dim_vendedor (
    id_vendedor INT PRIMARY KEY,
    nombre_vendedor VARCHAR(300),
    email VARCHAR(300),
    INDEX idx_nombre (nombre_vendedor)
);

-- Tabla de Hechos Ventas (corregido: aumentar precisiones decimales)
CREATE TABLE fact_ventas (
    id_fact INT AUTO_INCREMENT PRIMARY KEY,
    id_tiempo INT,
    id_cliente INT,
    id_producto INT,
    id_vendedor INT,
    cantidad DECIMAL(12,4),
    precio_unitario DECIMAL(14,4),
    total DECIMAL(16,4),
    moneda VARCHAR(10),
    document_id INT,  -- Para trazabilidad
    FOREIGN KEY (id_tiempo) REFERENCES dim_tiempo(id_tiempo),
    FOREIGN KEY (id_cliente) REFERENCES dim_cliente(id_cliente),
    FOREIGN KEY (id_producto) REFERENCES dim_producto(id_producto),
    FOREIGN KEY (id_vendedor) REFERENCES dim_vendedor(id_vendedor),
    INDEX idx_tiempo (id_tiempo),
    INDEX idx_cliente (id_cliente),
    INDEX idx_producto (id_producto),
    INDEX idx_vendedor (id_vendedor),
    INDEX idx_fecha_cliente (id_tiempo, id_cliente)
);

-- =============================================
-- 2. POBLAR DIMENSIONES
-- =============================================

-- Poblar dimensión tiempo
INSERT INTO dim_tiempo (fecha, anio, mes, dia, trimestre, nombre_mes)
SELECT DISTINCT
    fecha,
    YEAR(fecha),
    MONTH(fecha),
    DAY(fecha),
    QUARTER(fecha),
    MONTHNAME(fecha)
FROM staging_optica.st_documents_clean;

-- Poblar dimensión cliente
INSERT INTO dim_cliente (id_cliente, nombre_cliente, documento, email, telefono)
SELECT 
    person_id,
    nombre_cliente,
    documento,
    email,
    telefono
FROM staging_optica.st_persons_clean;

-- Poblar dimensión producto
INSERT INTO dim_producto (id_producto, nombre_producto, modelo, precio_unitario)
SELECT 
    item_id,
    nombre_producto,
    modelo,
    precio_unitario
FROM staging_optica.st_items_clean;

-- Poblar dimensión vendedor
INSERT INTO dim_vendedor (id_vendedor, nombre_vendedor, email)
SELECT 
    user_id,
    nombre_vendedor,
    email
FROM staging_optica.st_users_clean;

-- =============================================
-- 3. POBLAR TABLA DE HECHOS - VERSIÓN CORREGIDA
-- =============================================

-- Primero: Crear tabla temporal para documentos con producto representativo
CREATE TEMPORARY TABLE temp_document_products AS
SELECT 
    d.document_id,
    d.customer_id,
    d.user_id,
    d.fecha,
    d.total,
    d.currency_type_id,
    -- Seleccionar el primer producto del documento como representativo
    (SELECT di.item_id 
     FROM staging_optica.st_document_items di 
     WHERE di.document_id = d.document_id 
     LIMIT 1) AS representative_item_id
FROM staging_optica.st_documents_clean d;

-- Poblar fact_ventas (1 registro por documento)
INSERT INTO fact_ventas (id_tiempo, id_cliente, id_producto, id_vendedor, cantidad, precio_unitario, total, moneda, document_id)
SELECT 
    t.id_tiempo,
    c.id_cliente,
    p.id_producto,
    v.id_vendedor,
    1 AS cantidad,  -- Cada documento cuenta como 1 venta
    td.total AS precio_unitario,
    td.total,
    td.currency_type_id,
    td.document_id  -- Mantener trazabilidad
FROM temp_document_products td
JOIN dw_optica.dim_tiempo t ON t.fecha = td.fecha
JOIN dw_optica.dim_cliente c ON c.id_cliente = td.customer_id
JOIN dw_optica.dim_vendedor v ON v.id_vendedor = td.user_id
JOIN dw_optica.dim_producto p ON p.id_producto = td.representative_item_id;

-- Limpiar tabla temporal
DROP TEMPORARY TABLE temp_document_products;

-- =============================================
-- 4. VALIDACIÓN FINAL
-- =============================================

-- Validar conteos
SELECT 
    'dim_tiempo' AS tabla, COUNT(*) AS registros FROM dim_tiempo
    UNION ALL
    SELECT 'dim_cliente', COUNT(*) FROM dim_cliente
    UNION ALL
    SELECT 'dim_producto', COUNT(*) FROM dim_producto
    UNION ALL
    SELECT 'dim_vendedor', COUNT(*) FROM dim_vendedor
    UNION ALL
    SELECT 'fact_ventas', COUNT(*) FROM fact_ventas;

-- Validar totales
SELECT 
    (SELECT SUM(total) FROM staging_optica.st_documents_clean) AS total_original,
    (SELECT SUM(total) FROM fact_ventas) AS total_dw,
    ROUND(((SELECT SUM(total) FROM staging_optica.st_documents_clean) - 
          (SELECT SUM(total) FROM fact_ventas)) / 
         (SELECT SUM(total) FROM staging_optica.st_documents_clean) * 100, 4) AS diferencia_porcentaje;

-- Validar integridad referencial
SELECT 
    'Ventas sin tiempo' AS validacion, COUNT(*) AS cantidad
    FROM fact_ventas f LEFT JOIN dim_tiempo t ON f.id_tiempo = t.id_tiempo WHERE t.id_tiempo IS NULL
    UNION ALL
    SELECT 'Ventas sin cliente', COUNT(*) FROM fact_ventas f LEFT JOIN dim_cliente c ON f.id_cliente = c.id_cliente WHERE c.id_cliente IS NULL
    UNION ALL
    SELECT 'Ventas sin producto', COUNT(*) FROM fact_ventas f LEFT JOIN dim_producto p ON f.id_producto = p.id_producto WHERE p.id_producto IS NULL
    UNION ALL
    SELECT 'Ventas sin vendedor', COUNT(*) FROM fact_ventas f LEFT JOIN dim_vendedor v ON f.id_vendedor = v.id_vendedor WHERE v.id_vendedor IS NULL;

-- =============================================
-- 5. CREAR VISTAS PARA REPORTES
-- =============================================

-- Vista para ventas mensuales
CREATE VIEW vw_ventas_mensuales AS
SELECT 
    t.anio,
    t.mes,
    t.nombre_mes,
    COUNT(*) AS cantidad_ventas,
    SUM(f.total) AS total_ventas,
    AVG(f.total) AS ticket_promedio
FROM fact_ventas f
JOIN dim_tiempo t ON f.id_tiempo = t.id_tiempo
GROUP BY t.anio, t.mes, t.nombre_mes
ORDER BY t.anio DESC, t.mes DESC;

-- Vista para top clientes
CREATE VIEW vw_top_clientes AS
SELECT 
    c.nombre_cliente,
    COUNT(*) AS total_compras,
    SUM(f.total) AS total_gastado,
    AVG(f.total) AS ticket_promedio
FROM fact_ventas f
JOIN dim_cliente c ON f.id_cliente = c.id_cliente
GROUP BY c.nombre_cliente
ORDER BY total_gastado DESC;

-- Vista para ventas por vendedor
CREATE VIEW vw_ventas_vendedor AS
SELECT 
    v.nombre_vendedor,
    COUNT(*) AS ventas_realizadas,
    SUM(f.total) AS total_vendido,
    AVG(f.total) AS ticket_promedio
FROM fact_ventas f
JOIN dim_vendedor v ON f.id_vendedor = v.id_vendedor
GROUP BY v.nombre_vendedor
ORDER BY total_vendido DESC;

-- Vista para productos más vendidos
CREATE VIEW vw_productos_populares AS
SELECT 
    p.nombre_producto,
    COUNT(*) AS veces_vendido
FROM fact_ventas f
JOIN dim_producto p ON f.id_producto = p.id_producto
GROUP BY p.nombre_producto
ORDER BY veces_vendido DESC;

-- =============================================
-- 6. QUERIES DE VALIDACIÓN RÁPIDA
-- =============================================

-- Consulta rápida de validación
SELECT '=== VALIDACIÓN RÁPIDA ===' AS info;
SELECT * FROM vw_ventas_mensuales LIMIT 12;
SELECT * FROM vw_top_clientes LIMIT 10;
SELECT * FROM vw_ventas_vendedor;
SELECT * FROM vw_productos_populares LIMIT 10;