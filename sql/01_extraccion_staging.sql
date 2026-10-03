-- =============================================
-- EXTRACCIÓN COMPLETA Y CORREGIDA
-- =============================================

-- Crear base temporal para staging
CREATE DATABASE IF NOT EXISTS staging_optica;
USE staging_optica;

-- 1. Extraer documentos (ventas)
CREATE TABLE st_documents AS 
SELECT 
    id AS document_id,
    customer_id,
    user_id,
    date_of_issue,
    total,
    currency_type_id
FROM opticaventas.documents 
WHERE total > 0;

-- VERIFICACIÓN
SELECT COUNT(*) AS total_documents FROM st_documents; -- Resultado: 42,366 ✅


-- 2. Extraer items de documentos (detalle de ventas)
CREATE TABLE st_document_items AS 
SELECT 
    id AS item_detalle_id,
    document_id,
    item_id,
    quantity,
    unit_value,
    total
FROM opticaventas.document_items;

-- VERIFICACIÓN
SELECT COUNT(*) AS total_document_items FROM st_document_items; -- Resultado: 68,198 ✅


-- 3. Extraer clientes
CREATE TABLE st_persons AS 
SELECT 
    id AS person_id,
    name AS nombre_cliente,
    number AS documento,
    type,
    email,
    telephone
FROM opticaventas.persons 
WHERE type = 'customers';

-- VERIFICACIÓN
SELECT COUNT(*) AS total_persons FROM st_persons; -- Resultado: 18,841 ✅


-- 4. Extraer productos
CREATE TABLE st_items AS 
SELECT 
    id AS item_id,
    description,
    model,
    sale_unit_price
FROM opticaventas.items;

-- VERIFICACIÓN
SELECT COUNT(*) AS total_items FROM st_items; -- Resultado: 59,585 ✅


-- 5. ✅ CORREGIDO: Extraer vendedores (usuarios con ventas reales)
DROP TABLE IF EXISTS st_users; -- Eliminar si existe vacía

CREATE TABLE st_users AS 
SELECT DISTINCT
    u.id AS user_id,
    u.name AS nombre_vendedor,
    u.email,
    u.type
FROM opticaventas.users u
JOIN opticaventas.documents d ON u.id = d.user_id
WHERE d.total > 0;

-- VERIFICACIÓN
SELECT COUNT(*) AS total_users FROM st_users; -- Resultado: 4 ✅