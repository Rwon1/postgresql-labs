-- Практическая работа 8. Егоров, 16М-нф26.
-- Исходные данные: lecture_08_seed.sql; исправлена скобка в формуле unit_price.
CREATE SCHEMA IF NOT EXISTS lecture08;
SET search_path TO lecture08;


CREATE TABLE IF NOT EXISTS customers (
  customer_id BIGINT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE,
  city TEXT,
  registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS products (
  product_id BIGINT PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  product_name TEXT NOT NULL,
  category TEXT,
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS orders (
  order_id BIGINT PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
  order_date TIMESTAMP NOT NULL,
  status TEXT NOT NULL,
  delivery_city TEXT,
  channel TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS order_items (
  order_item_id BIGINT PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(order_id),
  product_id BIGINT NOT NULL REFERENCES products(product_id),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0)
);

ALTER TABLE customers ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS stock_quantity INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_city TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS channel TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

WITH src AS (
 SELECT 870000+g customer_id,
        'Performance Customer #'||g full_name,
        'perf'||g||'@example.com' email,
        (ARRAY['Valencia','Madrid','Barcelona','Sevilla','Bilbao','Malaga','Zaragoza','Alicante','Murcia','Valladolid'])[((g*7-1)%10)+1] city,
        TIMESTAMP '2022-01-01' + ((g*13)%1400)*INTERVAL '1 day' registered_at,
        (g%23<>0) is_active
 FROM generate_series(1,1000) gs(g)
)
INSERT INTO customers(customer_id,full_name,email,city,registered_at,is_active)
SELECT * FROM src s WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id=s.customer_id)
 AND NOT EXISTS (SELECT 1 FROM customers c WHERE c.email=s.email);

WITH src AS (
 SELECT 880000+g product_id,
        'L08-'||lpad(g::text,5,'0') sku,
        (ARRAY['Ноутбук','Монитор','SSD','Клавиатура','Мышь','Роутер','Наушники','Камера','Док-станция','Планшет'])[((g-1)%10)+1]||' Performance #'||g product_name,
        (ARRAY['Ноутбуки','Мониторы','Накопители','Периферия','Сеть','Аудио','Видео','Аксессуары'])[((g*5-1)%8)+1] category,
        (990 + ((g*37)%400)*250)::numeric(12,2) price,
        ((g*29)%250) stock_quantity,
        (g%19<>0) is_active,
        TIMESTAMP '2022-01-01' + ((g*17)%1400)*INTERVAL '1 day' created_at
 FROM generate_series(1,2000) gs(g)
)
INSERT INTO products(product_id,sku,product_name,category,price,stock_quantity,is_active,created_at)
SELECT * FROM src s WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.product_id=s.product_id)
 AND NOT EXISTS (SELECT 1 FROM products p WHERE p.sku=s.sku);

WITH src AS (
 SELECT 890000+g order_id,
        870001 + ((g*73)%1000) customer_id,
        TIMESTAMP '2023-01-01 08:00' + ((g*17)%1360)*INTERVAL '1 day' + ((g*11)%14)*INTERVAL '1 hour' order_date,
        CASE WHEN g%20<11 THEN 'paid' WHEN g%20<17 THEN 'completed' WHEN g%20<19 THEN 'pending' ELSE 'cancelled' END status,
        (ARRAY['Valencia','Madrid','Barcelona','Sevilla','Bilbao','Malaga','Zaragoza','Alicante','Murcia','Valladolid'])[((g*3-1)%10)+1] delivery_city,
        (ARRAY['web','mobile','marketplace','store'])[((g*7-1)%4)+1] channel,
        TIMESTAMP '2023-01-01 08:00' + ((g*17)%1360)*INTERVAL '1 day' created_at
 FROM generate_series(1,120000) gs(g)
)
INSERT INTO orders(order_id,customer_id,order_date,status,delivery_city,channel,created_at)
SELECT * FROM src s WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.order_id=s.order_id);

WITH src AS (
 SELECT 990000 + ((g-1)*4+k) order_item_id,
        890000+g order_id,
        880001 + (((g*31 + k*197)-1)%2000) product_id,
        1 + ((g+k*3)%5) quantity,
        (990 + (((((g*31 + k*197)-1)%2000 + 1)*37)%400)*250)::numeric(12,2) unit_price
 FROM generate_series(1,120000) gs(g)
 CROSS JOIN generate_series(1,4) pos(k)
)
INSERT INTO order_items(order_item_id,order_id,product_id,quantity,unit_price)
SELECT * FROM src s WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.order_item_id=s.order_item_id);

ANALYZE customers;
ANALYZE products;
ANALYZE orders;
ANALYZE order_items;

SELECT 'customers L08' table_name, COUNT(*) rows_count FROM customers WHERE customer_id BETWEEN 870001 AND 871000
UNION ALL SELECT 'products L08', COUNT(*) FROM products WHERE product_id BETWEEN 880001 AND 882000
UNION ALL SELECT 'orders L08', COUNT(*) FROM orders WHERE order_id BETWEEN 890001 AND 1010000
UNION ALL SELECT 'order_items L08', COUNT(*) FROM order_items WHERE order_item_id BETWEEN 990001 AND 1470000;

SELECT status,COUNT(*) AS orders_count,ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),2) AS pct
FROM orders WHERE order_id BETWEEN 890001 AND 1010000 GROUP BY status ORDER BY orders_count DESC;

SELECT COUNT(DISTINCT customer_id) distinct_customers,COUNT(*) orders_count
FROM orders WHERE order_id BETWEEN 890001 AND 1010000;

-- 8.01. Исходные количества строк
SELECT 'customers' AS table_name,COUNT(*) AS rows_count FROM customers
UNION ALL SELECT 'products',COUNT(*) FROM products
UNION ALL SELECT 'orders',COUNT(*) FROM orders
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items;

-- 8.02. Статистика и сброс только индексов этой работы для повторного эксперимента
DROP INDEX IF EXISTS idx_l08_customer_date;
DROP INDEX IF EXISTS idx_l08_cancelled_date;
DROP INDEX IF EXISTS idx_l08_item_product;
DROP INDEX IF EXISTS idx_l08_status_test;
ANALYZE customers; ANALYZE products; ANALYZE orders; ANALYZE order_items;

-- 8.03. Исходные индексы orders и order_items
SELECT tablename,indexname,indexdef FROM pg_indexes
WHERE schemaname='lecture08' AND tablename IN ('orders','order_items')
ORDER BY tablename,indexname;

-- 8.04. A1. Конкретный клиент
EXPLAIN
SELECT * FROM orders WHERE customer_id=870042;

-- 8.05. A2. Распространённый статус
EXPLAIN
SELECT * FROM orders WHERE status='paid';

-- 8.06. A3. Период
EXPLAIN
SELECT * FROM orders WHERE order_date>=TIMESTAMP '2026-01-01' AND order_date<TIMESTAMP '2026-02-01';

-- 8.07. A4. JOIN заказов и позиций
EXPLAIN
SELECT o.order_id,i.product_id,i.quantity FROM orders o JOIN order_items i USING(order_id) WHERE o.customer_id=870042;

-- 8.08. B1. Гипотеза: (customer_id, order_date DESC) сократит чтение и уберёт Sort
SELECT COUNT(*) AS rows_count,SUM(order_id) AS id_sum FROM (
SELECT order_id,order_date,status FROM orders WHERE customer_id=870042
ORDER BY order_date DESC,order_id DESC LIMIT 20) x;

-- 8.09. B1. До индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date,status FROM orders
WHERE customer_id=870042 ORDER BY order_date DESC,order_id DESC LIMIT 20;

-- 8.10. B1. Индекс
CREATE INDEX idx_l08_customer_date ON orders(customer_id,order_date DESC,order_id DESC);

-- 8.11. B1. После индекса — тот же SQL
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date,status FROM orders
WHERE customer_id=870042 ORDER BY order_date DESC,order_id DESC LIMIT 20;

-- 8.12. B1. Контроль после
SELECT COUNT(*) AS rows_count,SUM(order_id) AS id_sum FROM (
SELECT order_id,order_date,status FROM orders WHERE customer_id=870042
ORDER BY order_date DESC,order_id DESC LIMIT 20) x;

-- 8.13. B2. Гипотеза: частичный индекс ускорит редкий статус за период
SELECT COUNT(*) AS rows_count,SUM(order_id) AS id_sum FROM orders
WHERE status='cancelled' AND order_date>=TIMESTAMP '2026-01-01';

-- 8.14. B2. До индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date FROM orders
WHERE status='cancelled' AND order_date>=TIMESTAMP '2026-01-01';

-- 8.15. B2. Индекс
CREATE INDEX idx_l08_cancelled_date ON orders(order_date) WHERE status='cancelled';

-- 8.16. B2. После индекса — тот же SQL
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date FROM orders
WHERE status='cancelled' AND order_date>=TIMESTAMP '2026-01-01';

-- 8.17. B2. Контроль после
SELECT COUNT(*) AS rows_count,SUM(order_id) AS id_sum FROM orders
WHERE status='cancelled' AND order_date>=TIMESTAMP '2026-01-01';

-- 8.18. B3. Гипотеза: индекс внешнего ключа product_id уменьшит чтение позиций
SELECT COUNT(*) AS rows_count,SUM(quantity) AS units,SUM(quantity*unit_price) AS revenue
FROM order_items WHERE product_id=880042;

-- 8.19. B3. До индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id,COUNT(*) AS positions,SUM(quantity) AS units,
SUM(quantity*unit_price) AS revenue FROM order_items
WHERE product_id=880042 GROUP BY product_id;

-- 8.20. B3. Индекс
CREATE INDEX idx_l08_item_product ON order_items(product_id);

-- 8.21. B3. После индекса — тот же SQL
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id,COUNT(*) AS positions,SUM(quantity) AS units,
SUM(quantity*unit_price) AS revenue FROM order_items
WHERE product_id=880042 GROUP BY product_id;

-- 8.22. B3. Контроль после
SELECT COUNT(*) AS rows_count,SUM(quantity) AS units,SUM(quantity*unit_price) AS revenue
FROM order_items WHERE product_id=880042;

-- 8.23. C. Доля распространённых статусов
-- Гипотеза: при выборе 85% строк Seq Scan останется выгоднее индекса status.
SELECT status,COUNT(*) AS orders_count FROM orders GROUP BY status ORDER BY status;

-- 8.24. C. До индекса status
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE status IN ('paid','completed');

-- 8.25. C. Тестовый индекс status
CREATE INDEX idx_l08_status_test ON orders(status);

-- 8.26. C. После индекса status
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE status IN ('paid','completed');

-- 8.27. C. Размер тестового индекса
SELECT pg_relation_size('idx_l08_status_test') AS bytes,pg_size_pretty(pg_relation_size('idx_l08_status_test')) AS size;

-- 8.28. C. Удаление: для чтения 85% строк тестовый индекс не нужен
DROP INDEX idx_l08_status_test;

-- 8.29. D1. DATE(order_date); новых индексов нет
-- Гипотеза: диапазон уберёт вычисление DATE для каждой строки, но без подходящего индекса сканирование останется.
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE DATE(order_date)=DATE '2026-06-12';

-- 8.30. D1. Эквивалентный диапазон; индексы те же
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE order_date>=TIMESTAMP '2026-06-12' AND order_date<TIMESTAMP '2026-06-13';

-- 8.31. D1. Сравнение количества и полного множества строк
WITH a AS (SELECT * FROM orders WHERE DATE(order_date)=DATE '2026-06-12'),b AS (SELECT * FROM orders WHERE order_date>=TIMESTAMP '2026-06-12' AND order_date<TIMESTAMP '2026-06-13')
SELECT (SELECT COUNT(*) FROM a) AS date_rows,(SELECT COUNT(*) FROM b) AS range_rows,
       (SELECT COUNT(*) FROM ((SELECT * FROM a EXCEPT ALL SELECT * FROM b)
         UNION ALL (SELECT * FROM b EXCEPT ALL SELECT * FROM a)) d) AS differences;

-- 8.32. D2. Все поля клиента
-- Гипотеза: выбор ID и даты позволит читать только составной индекс вместо строк таблицы.
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE customer_id=870042;

-- 8.33. D2. Только нужные поля
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date FROM orders WHERE customer_id=870042;

-- 8.34. D2. Проверка одинаковых ID и дат
WITH a AS (SELECT * FROM orders WHERE customer_id=870042),
b AS (SELECT order_id,order_date FROM orders WHERE customer_id=870042)
SELECT COUNT(*) AS differences FROM (
 (SELECT order_id,order_date FROM a EXCEPT ALL SELECT * FROM b)
 UNION ALL (SELECT * FROM b EXCEPT ALL SELECT order_id,order_date FROM a)) d;

-- 8.35. D3. Последние 20 заказов: ORDER BY и LIMIT
-- Гипотеза: LIMIT уменьшит объём сортировки, но без индекса по общей дате придётся прочитать все заказы.
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date,status FROM orders ORDER BY order_date DESC,order_id DESC LIMIT 20;

-- 8.36. D3. Проверка последних 20 заказов через ROW_NUMBER
WITH a AS (SELECT order_id,order_date FROM orders ORDER BY order_date DESC,order_id DESC LIMIT 20),
b AS (SELECT order_id,order_date,ROW_NUMBER() OVER (ORDER BY order_date DESC,order_id DESC) AS rn FROM orders)
SELECT COUNT(*) AS differences FROM (
 (SELECT * FROM a EXCEPT ALL SELECT order_id,order_date FROM b WHERE rn<=20)
 UNION ALL (SELECT order_id,order_date FROM b WHERE rn<=20 EXCEPT ALL SELECT * FROM a)) d;

-- 8.37. D4. Курсор предыдущей страницы: строка 50000
-- Гипотеза: готовый курсор сократит число сортируемых строк; без индекса по общей дате останется Seq Scan.
CREATE TABLE IF NOT EXISTS lecture08.page_cursor (order_date timestamp,order_id bigint);
DELETE FROM lecture08.page_cursor;
INSERT INTO lecture08.page_cursor
SELECT order_date,order_id FROM orders ORDER BY order_date DESC,order_id DESC OFFSET 49999 LIMIT 1;

-- 8.38. D4. Большой OFFSET
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date FROM orders ORDER BY order_date DESC,order_id DESC OFFSET 50000 LIMIT 20;

-- 8.39. D4. Keyset с готовым курсором предыдущей страницы
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date FROM orders
WHERE (order_date,order_id)<(SELECT order_date,order_id FROM lecture08.page_cursor)
ORDER BY order_date DESC,order_id DESC LIMIT 20;

-- 8.40. D4. Сверка двух способов пагинации
WITH a AS (SELECT order_id,order_date FROM orders ORDER BY order_date DESC,order_id DESC OFFSET 50000 LIMIT 20), b AS (SELECT order_id,order_date FROM orders
WHERE (order_date,order_id)<(SELECT order_date,order_id FROM lecture08.page_cursor)
ORDER BY order_date DESC,order_id DESC LIMIT 20)
SELECT (SELECT COUNT(*) FROM a) AS offset_rows,(SELECT COUNT(*) FROM b) AS keyset_rows,
       (SELECT COUNT(*) FROM ((SELECT * FROM a EXCEPT ALL SELECT * FROM b)
        UNION ALL (SELECT * FROM b EXCEPT ALL SELECT * FROM a)) d) AS differences;

-- 8.41. Удаление служебного курсора эксперимента
DROP TABLE lecture08.page_cursor;

-- 8.42. Индексы, оставленные для трёх проверенных запросов
SELECT indexname,pg_size_pretty(pg_relation_size(quote_ident(schemaname)||'.'||quote_ident(indexname))) AS size
FROM pg_indexes WHERE schemaname='lecture08' AND indexname LIKE 'idx_l08_%' ORDER BY indexname;

-- Измеренные планы и выводы: results/lecture08/analysis.md.
