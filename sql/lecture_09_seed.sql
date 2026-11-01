-- Данные лекции 9.
CREATE SCHEMA IF NOT EXISTS lecture09;
SET search_path TO lecture09;

-- Lecture 09 seed: VIEW, MATERIALIZED VIEW and analytical marts
-- PostgreSQL. Self-contained and idempotent; repeated execution does not duplicate lecture rows.
BEGIN;

CREATE TABLE IF NOT EXISTS customers (
  customer_id BIGINT PRIMARY KEY, full_name TEXT NOT NULL, email TEXT UNIQUE,
  city TEXT, registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS products (
  product_id BIGINT PRIMARY KEY, sku TEXT UNIQUE NOT NULL, product_name TEXT NOT NULL,
  category TEXT, price NUMERIC(12,2) NOT NULL CHECK(price>=0),
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity>=0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS orders (
  order_id BIGINT PRIMARY KEY, customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
  order_date TIMESTAMP NOT NULL, status TEXT NOT NULL, delivery_city TEXT, channel TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS order_items (
  order_item_id BIGINT PRIMARY KEY, order_id BIGINT NOT NULL REFERENCES orders(order_id),
  product_id BIGINT NOT NULL REFERENCES products(product_id), quantity INTEGER NOT NULL CHECK(quantity>0),
  unit_price NUMERIC(12,2) NOT NULL CHECK(unit_price>=0)
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

-- 1,200 customers. Last 100 intentionally receive no generated orders.
WITH src AS (
 SELECT 970000+g customer_id, 'L09 Customer #'||g full_name, 'l09_'||g||'@example.com' email,
   (ARRAY['Valencia','Madrid','Barcelona','Sevilla','Bilbao','Malaga','Zaragoza','Alicante','Murcia','Valladolid'])[((g*7-1)%10)+1] city,
   TIMESTAMP '2021-01-01' + ((g*13)%1800)*INTERVAL '1 day' registered_at, (g%29<>0) is_active
 FROM generate_series(1,1200) gs(g)
)
INSERT INTO customers(customer_id,full_name,email,city,registered_at,is_active)
SELECT * FROM src s WHERE NOT EXISTS(SELECT 1 FROM customers c WHERE c.customer_id=s.customer_id)
 AND NOT EXISTS(SELECT 1 FROM customers c WHERE c.email=s.email);

-- 2,500 products. Last 150 intentionally receive no generated order items.
WITH src AS (
 SELECT 980000+g product_id,'L09-'||lpad(g::text,5,'0') sku,
   (ARRAY['Ноутбук','Монитор','SSD','Клавиатура','Мышь','Роутер','Наушники','Камера','Док-станция','Планшет'])[((g-1)%10)+1]||' Mart #'||g product_name,
   (ARRAY['Ноутбуки','Мониторы','Накопители','Периферия','Сеть','Аудио','Видео','Аксессуары'])[((g*5-1)%8)+1] category,
   (750+((g*41)%600)*125)::numeric(12,2) price,((g*29)%300) stock_quantity,(g%23<>0) is_active,
   TIMESTAMP '2021-01-01'+((g*17)%1800)*INTERVAL '1 day' created_at
 FROM generate_series(1,2500) gs(g)
)
INSERT INTO products(product_id,sku,product_name,category,price,stock_quantity,is_active,created_at)
SELECT * FROM src s WHERE NOT EXISTS(SELECT 1 FROM products p WHERE p.product_id=s.product_id)
 AND NOT EXISTS(SELECT 1 FROM products p WHERE p.sku=s.sku);

-- 150,000 orders across 2023-2026, using only first 1,100 lecture customers.
WITH src AS (
 SELECT 1000000+g order_id,970001+((g*73)%1100) customer_id,
   TIMESTAMP '2023-01-01 08:00'+((g*17)%1400)*INTERVAL '1 day'+((g*11)%14)*INTERVAL '1 hour' order_date,
   CASE WHEN g%20<10 THEN 'paid' WHEN g%20<17 THEN 'completed' WHEN g%20<19 THEN 'pending' ELSE 'cancelled' END status,
   (ARRAY['Valencia','Madrid','Barcelona','Sevilla','Bilbao','Malaga','Zaragoza','Alicante','Murcia','Valladolid'])[((g*3-1)%10)+1] delivery_city,
   (ARRAY['web','mobile','marketplace','store'])[((g*7-1)%4)+1] channel,
   TIMESTAMP '2023-01-01 08:00'+((g*17)%1400)*INTERVAL '1 day' created_at
 FROM generate_series(1,150000) gs(g)
)
INSERT INTO orders(order_id,customer_id,order_date,status,delivery_city,channel,created_at)
SELECT * FROM src s WHERE NOT EXISTS(SELECT 1 FROM orders o WHERE o.order_id=s.order_id);

-- 600,000 positions: four per generated order; only first 2,350 lecture products are sold.
WITH src AS (
 SELECT 2000000+((g-1)*4+k) order_item_id,1000000+g order_id,
   980001+(((g*31+k*197)-1)%2350) product_id,1+((g+k*3)%5) quantity,
   (750 + (((1 + ((g*31 + k*197 - 1) % 2350)) * 41) % 600) * 125)::numeric(12,2) unit_price
 FROM generate_series(1,150000) gs(g) CROSS JOIN generate_series(1,4) pos(k)
)
INSERT INTO order_items(order_item_id,order_id,product_id,quantity,unit_price)
SELECT * FROM src s WHERE NOT EXISTS(SELECT 1 FROM order_items oi WHERE oi.order_item_id=s.order_item_id);

ANALYZE customers; ANALYZE products; ANALYZE orders; ANALYZE order_items;
COMMIT;

-- Control counts for lecture-09 reserved ranges.
SELECT 'customers L09' object_name,COUNT(*) rows_count FROM customers WHERE customer_id BETWEEN 970001 AND 971200
UNION ALL SELECT 'products L09',COUNT(*) FROM products WHERE product_id BETWEEN 980001 AND 982500
UNION ALL SELECT 'orders L09',COUNT(*) FROM orders WHERE order_id BETWEEN 1000001 AND 1150000
UNION ALL SELECT 'order_items L09',COUNT(*) FROM order_items WHERE order_item_id BETWEEN 2000001 AND 2600000;

SELECT status,COUNT(*) orders_count FROM orders WHERE order_id BETWEEN 1000001 AND 1150000 GROUP BY status ORDER BY orders_count DESC;
SELECT MIN(order_date),MAX(order_date),COUNT(DISTINCT order_date::date) active_days FROM orders WHERE order_id BETWEEN 1000001 AND 1150000;
SELECT COUNT(*) customers_without_l09_orders FROM customers c WHERE c.customer_id BETWEEN 970001 AND 971200 AND NOT EXISTS(SELECT 1 FROM orders o WHERE o.customer_id=c.customer_id AND o.order_id BETWEEN 1000001 AND 1150000);
SELECT COUNT(*) products_without_l09_sales FROM products p WHERE p.product_id BETWEEN 980001 AND 982500 AND NOT EXISTS(SELECT 1 FROM order_items oi WHERE oi.product_id=p.product_id AND oi.order_item_id BETWEEN 2000001 AND 2600000);
