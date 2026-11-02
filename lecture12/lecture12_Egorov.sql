-- Егоров Дмитрий, 16М-нф26. Лекция 12.
SET search_path=public;
SET TIME ZONE 'UTC';
-- 25. Исходный seed, первый запуск.
-- Лекция 12. Секционирование таблиц PostgreSQL. Самостоятельный повторяемый стенд.
-- Работает в отдельной схеме public; не удаляет существующие пользовательские данные.
BEGIN;
CREATE TABLE IF NOT EXISTS l12_customers (customer_id bigint PRIMARY KEY, full_name text NOT NULL, region text NOT NULL);
CREATE TABLE IF NOT EXISTS l12_products (product_id bigint PRIMARY KEY, product_name text NOT NULL, category text NOT NULL, price numeric(12,2) NOT NULL CHECK(price>0));
CREATE TABLE IF NOT EXISTS l12_orders (
 order_id bigint NOT NULL, order_date date NOT NULL, customer_id bigint NOT NULL REFERENCES l12_customers(customer_id),
 status text NOT NULL CHECK(status IN ('paid','new','cancelled')), amount numeric(12,2) NOT NULL CHECK(amount>=0),
 PRIMARY KEY(order_id,order_date)
) PARTITION BY RANGE(order_date);
DO $$ DECLARE m int; d date; e date; BEGIN
 FOR m IN 1..12 LOOP
   d := make_date(2025,m,1); e := (d + interval '1 month')::date;
   EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF l12_orders FOR VALUES FROM (%L) TO (%L)',
     'l12_orders_2025_'||lpad(m::text,2,'0'),d,e);
 END LOOP;
END $$;
CREATE TABLE IF NOT EXISTS l12_order_items (
 item_id bigint PRIMARY KEY, order_id bigint NOT NULL, order_date date NOT NULL,
 product_id bigint NOT NULL REFERENCES l12_products(product_id), quantity int NOT NULL CHECK(quantity>0),
 unit_price numeric(12,2) NOT NULL CHECK(unit_price>0),
 FOREIGN KEY(order_id,order_date) REFERENCES l12_orders(order_id,order_date)
);
INSERT INTO l12_customers(customer_id,full_name,region)
SELECT 1200000+g, 'Клиент №'||g, (ARRAY['Север','Юг','Восток','Запад','Центр'])[(g%5)+1]
FROM generate_series(1,200) g ON CONFLICT(customer_id) DO NOTHING;
INSERT INTO l12_products(product_id,product_name,category,price)
SELECT 1210000+g, 'Товар №'||g, (ARRAY['Ноутбуки','Сеть','Хранение','Периферия'])[(g%4)+1], (100+(g%180)*17.5)::numeric(12,2)
FROM generate_series(1,250) g ON CONFLICT(product_id) DO NOTHING;
INSERT INTO l12_orders(order_id,order_date,customer_id,status,amount)
SELECT 1220000+g, make_date(2025,1,1)+(g%365),1200000+(g%200)+1,
 (ARRAY['paid','paid','paid','new','cancelled'])[(g%5)+1], (500+(g%97)*37)::numeric(12,2)
FROM generate_series(1,2400) g ON CONFLICT(order_id,order_date) DO NOTHING;
INSERT INTO l12_order_items(item_id,order_id,order_date,product_id,quantity,unit_price)
SELECT 12300000+((o.g-1)*3)+i, 1220000+o.g, make_date(2025,1,1)+(o.g%365),
 1210000+((o.g*7+i)%250)+1, 1+((o.g+i)%4), (50+((o.g*3+i)%90)*11)::numeric(12,2)
FROM generate_series(1,2400) AS o(g) CROSS JOIN generate_series(1,3) AS i
ON CONFLICT(item_id) DO NOTHING;
CREATE INDEX IF NOT EXISTS l12_orders_customer_date_idx ON l12_orders(customer_id,order_date);
CREATE INDEX IF NOT EXISTS l12_items_order_date_idx ON l12_order_items(order_id,order_date);
COMMIT;
ANALYZE l12_customers; ANALYZE l12_products; ANALYZE l12_orders; ANALYZE l12_order_items;
-- Проверка количества записей
SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM l12_customers WHERE customer_id BETWEEN 1200001 AND 1200200
UNION ALL SELECT 'products',COUNT(*) FROM l12_products WHERE product_id BETWEEN 1210001 AND 1210250
UNION ALL SELECT 'orders',COUNT(*) FROM l12_orders WHERE order_id BETWEEN 1220001 AND 1222400
UNION ALL SELECT 'order_items',COUNT(*) FROM l12_order_items WHERE item_id BETWEEN 12300001 AND 12307200;
-- Проверка секций: должно быть 12 дочерних таблиц
SELECT child.relname AS partition_name FROM pg_inherits inh JOIN pg_class parent ON parent.oid=inh.inhparent
JOIN pg_class child ON child.oid=inh.inhrelid WHERE parent.oid='l12_orders'::regclass ORDER BY child.relname;
-- Проверка pruning: сравните число читаемых секций с запросом без фильтра по дате
EXPLAIN (ANALYZE, BUFFERS) SELECT COUNT(*) FROM l12_orders WHERE order_date >= DATE '2025-05-01' AND order_date < DATE '2025-06-01';

SELECT 'after_first_seed' AS stage;
SELECT 'customers' AS table_name, count(*) AS rows_count FROM l12_customers
UNION ALL SELECT 'products', count(*) FROM l12_products
UNION ALL SELECT 'orders', count(*) FROM l12_orders
UNION ALL SELECT 'order_items', count(*) FROM l12_order_items
UNION ALL SELECT 'partitions', count(*) FROM pg_inherits WHERE inhparent='l12_orders'::regclass;
-- 25. Повторный запуск того же seed.
-- Лекция 12. Секционирование таблиц PostgreSQL. Самостоятельный повторяемый стенд.
-- Работает в отдельной схеме public; не удаляет существующие пользовательские данные.
BEGIN;
CREATE TABLE IF NOT EXISTS l12_customers (customer_id bigint PRIMARY KEY, full_name text NOT NULL, region text NOT NULL);
CREATE TABLE IF NOT EXISTS l12_products (product_id bigint PRIMARY KEY, product_name text NOT NULL, category text NOT NULL, price numeric(12,2) NOT NULL CHECK(price>0));
CREATE TABLE IF NOT EXISTS l12_orders (
 order_id bigint NOT NULL, order_date date NOT NULL, customer_id bigint NOT NULL REFERENCES l12_customers(customer_id),
 status text NOT NULL CHECK(status IN ('paid','new','cancelled')), amount numeric(12,2) NOT NULL CHECK(amount>=0),
 PRIMARY KEY(order_id,order_date)
) PARTITION BY RANGE(order_date);
DO $$ DECLARE m int; d date; e date; BEGIN
 FOR m IN 1..12 LOOP
   d := make_date(2025,m,1); e := (d + interval '1 month')::date;
   EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF l12_orders FOR VALUES FROM (%L) TO (%L)',
     'l12_orders_2025_'||lpad(m::text,2,'0'),d,e);
 END LOOP;
END $$;
CREATE TABLE IF NOT EXISTS l12_order_items (
 item_id bigint PRIMARY KEY, order_id bigint NOT NULL, order_date date NOT NULL,
 product_id bigint NOT NULL REFERENCES l12_products(product_id), quantity int NOT NULL CHECK(quantity>0),
 unit_price numeric(12,2) NOT NULL CHECK(unit_price>0),
 FOREIGN KEY(order_id,order_date) REFERENCES l12_orders(order_id,order_date)
);
INSERT INTO l12_customers(customer_id,full_name,region)
SELECT 1200000+g, 'Клиент №'||g, (ARRAY['Север','Юг','Восток','Запад','Центр'])[(g%5)+1]
FROM generate_series(1,200) g ON CONFLICT(customer_id) DO NOTHING;
INSERT INTO l12_products(product_id,product_name,category,price)
SELECT 1210000+g, 'Товар №'||g, (ARRAY['Ноутбуки','Сеть','Хранение','Периферия'])[(g%4)+1], (100+(g%180)*17.5)::numeric(12,2)
FROM generate_series(1,250) g ON CONFLICT(product_id) DO NOTHING;
INSERT INTO l12_orders(order_id,order_date,customer_id,status,amount)
SELECT 1220000+g, make_date(2025,1,1)+(g%365),1200000+(g%200)+1,
 (ARRAY['paid','paid','paid','new','cancelled'])[(g%5)+1], (500+(g%97)*37)::numeric(12,2)
FROM generate_series(1,2400) g ON CONFLICT(order_id,order_date) DO NOTHING;
INSERT INTO l12_order_items(item_id,order_id,order_date,product_id,quantity,unit_price)
SELECT 12300000+((o.g-1)*3)+i, 1220000+o.g, make_date(2025,1,1)+(o.g%365),
 1210000+((o.g*7+i)%250)+1, 1+((o.g+i)%4), (50+((o.g*3+i)%90)*11)::numeric(12,2)
FROM generate_series(1,2400) AS o(g) CROSS JOIN generate_series(1,3) AS i
ON CONFLICT(item_id) DO NOTHING;
CREATE INDEX IF NOT EXISTS l12_orders_customer_date_idx ON l12_orders(customer_id,order_date);
CREATE INDEX IF NOT EXISTS l12_items_order_date_idx ON l12_order_items(order_id,order_date);
COMMIT;
ANALYZE l12_customers; ANALYZE l12_products; ANALYZE l12_orders; ANALYZE l12_order_items;
-- Проверка количества записей
SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM l12_customers WHERE customer_id BETWEEN 1200001 AND 1200200
UNION ALL SELECT 'products',COUNT(*) FROM l12_products WHERE product_id BETWEEN 1210001 AND 1210250
UNION ALL SELECT 'orders',COUNT(*) FROM l12_orders WHERE order_id BETWEEN 1220001 AND 1222400
UNION ALL SELECT 'order_items',COUNT(*) FROM l12_order_items WHERE item_id BETWEEN 12300001 AND 12307200;
-- Проверка секций: должно быть 12 дочерних таблиц
SELECT child.relname AS partition_name FROM pg_inherits inh JOIN pg_class parent ON parent.oid=inh.inhparent
JOIN pg_class child ON child.oid=inh.inhrelid WHERE parent.oid='l12_orders'::regclass ORDER BY child.relname;
-- Проверка pruning: сравните число читаемых секций с запросом без фильтра по дате
EXPLAIN (ANALYZE, BUFFERS) SELECT COUNT(*) FROM l12_orders WHERE order_date >= DATE '2025-05-01' AND order_date < DATE '2025-06-01';

SELECT 'after_second_seed' AS stage;
SELECT 'customers' AS table_name, count(*) AS rows_count FROM l12_customers
UNION ALL SELECT 'products', count(*) FROM l12_products
UNION ALL SELECT 'orders', count(*) FROM l12_orders
UNION ALL SELECT 'order_items', count(*) FROM l12_order_items
UNION ALL SELECT 'partitions', count(*) FROM pg_inherits WHERE inhparent='l12_orders'::regclass;
SELECT c.relname AS partition_name, pg_get_expr(c.relpartbound,c.oid) AS bounds,
coalesce(d.rows_count,0) AS rows_count, d.min_date, d.max_date
FROM pg_inherits h JOIN pg_class c ON c.oid=h.inhrelid
LEFT JOIN (SELECT tableoid, count(*) AS rows_count, min(order_date) AS min_date,
max(order_date) AS max_date FROM l12_orders GROUP BY tableoid) d ON d.tableoid=c.oid
WHERE h.inhparent='l12_orders'::regclass ORDER BY c.relname;
SELECT conname, contype, pg_get_constraintdef(oid) AS definition
FROM pg_constraint WHERE (conrelid='l12_orders'::regclass AND contype='p')
OR (conrelid='l12_order_items'::regclass AND confrelid='l12_orders'::regclass AND contype='f')
ORDER BY conname;
-- 26. Весь год и май 2025.
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM l12_orders;
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM l12_orders WHERE order_date >= DATE '2025-05-01' AND order_date < DATE '2025-06-01';
-- 27. Индекс уже создаётся seed; используем предусмотренный заданием вариант проверки наличия.
SELECT c.relname AS index_name, i.indisvalid, i.indisready,
pg_get_indexdef(c.oid) AS definition
FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid
WHERE c.oid='l12_orders_customer_date_idx'::regclass OR c.oid IN
(SELECT inhrelid FROM pg_inherits WHERE inhparent='l12_orders_customer_date_idx'::regclass)
ORDER BY c.relname;
SELECT * FROM l12_orders WHERE customer_id=1200002 AND order_date >= DATE '2025-01-01' AND order_date < DATE '2025-02-01';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM l12_orders WHERE customer_id=1200002 AND order_date >= DATE '2025-01-01' AND order_date < DATE '2025-02-01';
-- 28. Два независимых расчёта выручки оплаченных заказов.
WITH orders_month AS (
 SELECT date_trunc('month',order_date)::date AS month,
 count(*) AS paid_orders, sum(amount) AS orders_revenue
 FROM l12_orders WHERE status='paid' GROUP BY 1
), items_month AS (
 SELECT date_trunc('month',o.order_date)::date AS month,
 count(*) AS paid_items, sum(i.quantity*i.unit_price) AS items_revenue
 FROM l12_orders o JOIN l12_order_items i
 ON i.order_id=o.order_id AND i.order_date=o.order_date
 WHERE o.status='paid' GROUP BY 1
)
SELECT o.month, o.paid_orders, i.paid_items, o.orders_revenue, i.items_revenue,
i.items_revenue-o.orders_revenue AS difference
FROM orders_month o JOIN items_month i USING(month) ORDER BY o.month;
SELECT
(SELECT count(*) FROM l12_orders WHERE status='paid') AS paid_orders,
(SELECT sum(amount) FROM l12_orders WHERE status='paid') AS orders_revenue,
count(*) AS paid_items, sum(i.quantity*i.unit_price) AS items_revenue,
sum(i.quantity*i.unit_price)-(SELECT sum(amount) FROM l12_orders WHERE status='paid') AS difference
FROM l12_orders o JOIN l12_order_items i
ON i.order_id=o.order_id AND i.order_date=o.order_date WHERE o.status='paid';
SELECT count(*) AS joined_items, count(DISTINCT i.item_id) AS distinct_items,
(SELECT count(*) FROM l12_order_items) AS source_items,
count(*)=(SELECT count(*) FROM l12_order_items) AND count(*)=count(DISTINCT i.item_id) AS no_multiplication
FROM l12_orders o JOIN l12_order_items i
ON i.order_id=o.order_id AND i.order_date=o.order_date;
-- 29. Новая секция и заказ откатываются вместе.
BEGIN;
CREATE TABLE l12_orders_2026_01 PARTITION OF l12_orders
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
INSERT INTO l12_orders(order_id,order_date,customer_id,status,amount)
VALUES (1299000,DATE '2026-01-15',1200002,'new',125.00);
SELECT order_id, order_date, tableoid::regclass AS partition_name
FROM l12_orders WHERE order_id=1299000 AND order_date=DATE '2026-01-15';
ROLLBACK;
-- 30. Реальная ошибка перехватывается для непрерывного запуска файла; транзакция откатывается.
BEGIN;
CREATE TEMP TABLE l12_expected_error(sqlstate text, message text, detail text) ON COMMIT DROP;
DO $error$
DECLARE err_state text; err_message text; err_detail text;
BEGIN
 BEGIN
  INSERT INTO l12_orders(order_id,order_date,customer_id,status,amount)
  VALUES (1299001,DATE '2026-02-10',1200002,'new',100);
  RAISE EXCEPTION 'Expected routing error did not occur';
 EXCEPTION WHEN check_violation THEN
  GET STACKED DIAGNOSTICS err_state=RETURNED_SQLSTATE,
  err_message=MESSAGE_TEXT, err_detail=PG_EXCEPTION_DETAIL;
  INSERT INTO l12_expected_error VALUES (err_state,err_message,err_detail);
 END;
END $error$;
SELECT * FROM l12_expected_error;
ROLLBACK;
-- 31. Итоговая проверка.
SELECT 'customers' AS table_name, count(*) AS rows_count FROM l12_customers
UNION ALL SELECT 'products', count(*) FROM l12_products
UNION ALL SELECT 'orders', count(*) FROM l12_orders
UNION ALL SELECT 'order_items', count(*) FROM l12_order_items
UNION ALL SELECT 'partitions', count(*) FROM pg_inherits WHERE inhparent='l12_orders'::regclass;
SELECT to_regclass('l12_orders_2026_01') IS NULL AS january_rolled_back,
NOT EXISTS(SELECT 1 FROM l12_orders WHERE order_date >= DATE '2026-01-01') AS no_test_orders;
