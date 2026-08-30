-- =============================================================================
-- 05 — Post-load validation. Every row should be OK. Run in a worksheet after
-- the COPY step (scripts/load_raw.py runs an equivalent check automatically).
-- =============================================================================
USE SCHEMA {{DATABASE}}.{{RAW_SCHEMA}};

-- ---- Row counts vs the published figures -----------------------------------
WITH counts AS (
    SELECT 'orders'         AS table_name, COUNT(*) AS rows, 99441   AS expected FROM orders
    UNION ALL SELECT 'order_items',     COUNT(*), 112650 FROM order_items
    UNION ALL SELECT 'order_payments',  COUNT(*), 103886 FROM order_payments
    UNION ALL SELECT 'order_reviews',   COUNT(*), 99224  FROM order_reviews
    UNION ALL SELECT 'customers',       COUNT(*), 99441  FROM customers
    UNION ALL SELECT 'products',        COUNT(*), 32951  FROM products
    UNION ALL SELECT 'sellers',         COUNT(*), 3095   FROM sellers
    UNION ALL SELECT 'geolocation',     COUNT(*), 1000163 FROM geolocation
    UNION ALL SELECT 'product_category_name_translation', COUNT(*), 71 FROM product_category_name_translation
)
SELECT *,
       CASE WHEN rows > 0 AND ABS(rows - expected) <= expected * 0.02
            THEN 'OK' ELSE 'CHECK' END AS status
FROM counts
ORDER BY table_name;

-- ---- Spot checks ----------------------------------------------------------
-- order_id should be unique in orders
SELECT COUNT(*) AS dup_order_ids
FROM (SELECT order_id FROM orders GROUP BY order_id HAVING COUNT(*) > 1);

-- (order_id, order_item_id) should be unique in order_items
SELECT COUNT(*) AS dup_item_keys
FROM (SELECT order_id, order_item_id FROM order_items GROUP BY 1, 2 HAVING COUNT(*) > 1);

-- purchase timestamps should span 2016-2018
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- order_status domain
SELECT order_status, COUNT(*) AS n FROM orders GROUP BY 1 ORDER BY 2 DESC;

-- prices should be positive
SELECT COUNT(*) AS non_positive_prices FROM order_items WHERE price <= 0 OR freight_value < 0;

-- every order_item.order_id should exist in orders
SELECT COUNT(*) AS orphan_items
FROM order_items i LEFT JOIN orders o USING (order_id)
WHERE o.order_id IS NULL;
