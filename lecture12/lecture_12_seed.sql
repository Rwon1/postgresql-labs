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
