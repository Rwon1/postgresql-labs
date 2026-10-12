-- Краткий показ плана; полные измерения находятся в lecture08_egorov.sql.
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT order_id,order_date,status FROM lecture08.orders
WHERE customer_id=870042 ORDER BY order_date DESC,order_id DESC LIMIT 20;

-- Работа 8. Запросы к готовой базе.
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date,status
FROM lecture08.orders
WHERE customer_id=870042
ORDER BY order_date DESC,order_id DESC LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id,COUNT(*) AS positions,SUM(quantity) AS units,
       SUM(quantity*unit_price) AS revenue
FROM lecture08.order_items
WHERE product_id=880042 GROUP BY product_id;

SELECT status,COUNT(*) AS orders_count
FROM lecture08.orders GROUP BY status ORDER BY status;
