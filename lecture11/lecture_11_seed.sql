-- Рабочая копия: исправлены только два оператора конкатенации + на || g::text.
-- Лекция 11. Самостоятельный повторяемый учебный стенд для EXPLAIN.
-- Таблицы имеют префикс l11_, чтобы не затрагивать материалы других лекций.
BEGIN;
CREATE TABLE IF NOT EXISTS l11_customers (customer_id integer PRIMARY KEY,customer_name text NOT NULL,region text NOT NULL);
CREATE TABLE IF NOT EXISTS l11_products (product_id integer PRIMARY KEY,product_name text NOT NULL,category text NOT NULL,price numeric(12,2) NOT NULL CHECK(price>=0));
CREATE TABLE IF NOT EXISTS l11_orders (order_id integer PRIMARY KEY,customer_id integer NOT NULL REFERENCES l11_customers(customer_id),status text NOT NULL,total_amount numeric(14,2) NOT NULL DEFAULT 0,created_at timestamp NOT NULL);
CREATE TABLE IF NOT EXISTS l11_order_items (item_id integer PRIMARY KEY,order_id integer NOT NULL REFERENCES l11_orders(order_id),product_id integer NOT NULL REFERENCES l11_products(product_id),quantity integer NOT NULL CHECK(quantity>0),unit_price numeric(12,2) NOT NULL CHECK(unit_price>=0));
INSERT INTO l11_customers(customer_id,customer_name,region)
SELECT 110000+g,'Клиент ' || g::text, (ARRAY['Север','Юг','Восток','Запад','Центр'])[1+(g%5)] FROM generate_series(1,200) g
ON CONFLICT(customer_id) DO NOTHING;
INSERT INTO l11_products(product_id,product_name,category,price)
SELECT 111000+g,'Товар ' || g::text,(ARRAY['Ноутбуки','Сети','Хранение','Периферия','Серверы'])[1+(g%5)],round((150+g*13.47)::numeric,2)
FROM generate_series(1,250) g ON CONFLICT(product_id) DO NOTHING;
INSERT INTO l11_orders(order_id,customer_id,status,total_amount,created_at)
SELECT 1120000+g,110001+((g*17)%200),CASE WHEN g%40=0 THEN 'failed' WHEN g%8=0 THEN 'cancelled' WHEN g%5=0 THEN 'new' ELSE 'paid' END,0,
TIMESTAMP '2026-01-01' + (g%300)*INTERVAL '1 day' + (g%24)*INTERVAL '1 hour'
FROM generate_series(1,1200) g ON CONFLICT(order_id) DO NOTHING;
INSERT INTO l11_order_items(item_id,order_id,product_id,quantity,unit_price)
SELECT 1130000+g,1120001+((g-1)%1200),111001+((g*19)%250),1+(g%5),round((120+(g%250)*13.47)::numeric,2)
FROM generate_series(1,3600) g ON CONFLICT(item_id) DO NOTHING;
-- Сумма заказа синхронизируется с учебными позициями без удаления других данных.
UPDATE l11_orders o SET total_amount=s.amount FROM
(SELECT order_id,SUM(quantity*unit_price) amount FROM l11_order_items WHERE item_id BETWEEN 1130001 AND 1133600 GROUP BY order_id) s
WHERE o.order_id=s.order_id AND o.order_id BETWEEN 1120001 AND 1121200;
COMMIT;
ANALYZE l11_customers;
ANALYZE l11_products;
ANALYZE l11_orders;
ANALYZE l11_order_items;
SELECT 'l11_customers' AS table_name,COUNT(*) AS total_rows,COUNT(*) FILTER(WHERE customer_id BETWEEN 110001 AND 110200) AS lesson_rows FROM l11_customers
UNION ALL SELECT 'l11_products',COUNT(*),COUNT(*) FILTER(WHERE product_id BETWEEN 111001 AND 111250) FROM l11_products
UNION ALL SELECT 'l11_orders',COUNT(*),COUNT(*) FILTER(WHERE order_id BETWEEN 1120001 AND 1121200) FROM l11_orders
UNION ALL SELECT 'l11_order_items',COUNT(*),COUNT(*) FILTER(WHERE item_id BETWEEN 1130001 AND 1133600) FROM l11_order_items;
-- После установки индексов в практикуме повторно выполните ANALYZE и EXPLAIN.
