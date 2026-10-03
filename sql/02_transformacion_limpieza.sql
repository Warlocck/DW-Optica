USE staging_optica;

-- =============================================
-- ELIMINAR TABLAS EXISTENTES
-- =============================================
DROP TABLE IF EXISTS st_persons_clean;
DROP TABLE IF EXISTS st_items_clean;
DROP TABLE IF EXISTS st_users_clean;
DROP TABLE IF EXISTS st_documents_clean;

-- =============================================
-- CREAR TABLAS DE TRANSFORMACIÓN
-- =============================================

-- 1. Limpiar clientes
CREATE TABLE st_persons_clean AS 
SELECT DISTINCT
    person_id,
    UPPER(TRIM(nombre_cliente)) AS nombre_cliente,
    documento,
    COALESCE(email, 'NO_REGISTRA') AS email,
    COALESCE(telephone, 'NO_REGISTRA') AS telefono
FROM st_persons;

-- 2. Limpiar productos
CREATE TABLE st_items_clean AS 
SELECT DISTINCT
    item_id,
    UPPER(TRIM(description)) AS nombre_producto,
    COALESCE(model, 'SIN_MODELO') AS modelo,
    sale_unit_price AS precio_unitario
FROM st_items 
WHERE description IS NOT NULL;

-- 3. Limpiar vendedores
CREATE TABLE st_users_clean AS 
SELECT DISTINCT
    user_id,
    UPPER(TRIM(nombre_vendedor)) AS nombre_vendedor,
    COALESCE(email, 'NO_REGISTRA') AS email
FROM st_users;

-- 4. Limpiar documentos
CREATE TABLE st_documents_clean AS 
SELECT DISTINCT
    document_id,
    customer_id,
    user_id,
    DATE(date_of_issue) AS fecha,
    total,
    currency_type_id
FROM st_documents 
WHERE date_of_issue IS NOT NULL;

-- =============================================
-- VERIFICACIÓN COMPLETA
-- =============================================

-- Conteos principales
SELECT 
    'st_persons_clean' AS tabla, 
    COUNT(*) AS total_registros 
FROM st_persons_clean
UNION ALL
SELECT 
    'st_items_clean', 
    COUNT(*) 
FROM st_items_clean
UNION ALL
SELECT 
    'st_users_clean', 
    COUNT(*) 
FROM st_users_clean
UNION ALL
SELECT 
    'st_documents_clean', 
    COUNT(*) 
FROM st_documents_clean;

-- Ver datos de muestra
SELECT '=== st_persons_clean (primeros 3) ===' AS info;
SELECT * FROM st_persons_clean LIMIT 3;

SELECT '=== st_items_clean (primeros 3) ===' AS info;
SELECT * FROM st_items_clean LIMIT 3;

SELECT '=== st_users_clean (todos) ===' AS info;
SELECT * FROM st_users_clean;

SELECT '=== st_documents_clean (primeros 3) ===' AS info;
SELECT * FROM st_documents_clean LIMIT 3;