-- Практическая работа 4. Егоров, группа 16М-нф26.
-- Первый запуск в пустой базе; для повторного показа — READ-файлы.
BEGIN;
CREATE SCHEMA lecture04;
SET search_path TO lecture04;
CREATE TABLE products (
  product_id integer PRIMARY KEY,
  sku varchar(30) UNIQUE NOT NULL,
  product_name varchar(150) NOT NULL,
  category varchar(80),
  price numeric(12,2) NOT NULL CHECK (price >= 0),
  stock_quantity integer NOT NULL DEFAULT 0
    CHECK (stock_quantity >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO products
  (product_id, sku, product_name, category, price, stock_quantity, is_active, created_at)
VALUES
  (1, 'SKU-001', 'Ноутбук Учебный', 'Ноутбуки', 40000, 3, true, '2026-09-01 10:00:00'),
  (2, 'SKU-002', 'Ноутбук Рабочий', 'Ноутбуки', 65000, 2, true, '2026-09-02 10:00:00'),
  (3, 'SKU-003', 'Ноутбук Игровой', 'Ноутбуки', 120000, 0, true, '2026-09-03 10:00:00'),
  (4, 'SKU-004', 'Ноутбук Лёгкий', 'Ноутбуки', 80000, 1, true, '2026-09-04 10:00:00'),
  (5, 'SKU-005', 'Ноутбук Архивный', 'Ноутбуки', 30000, 0, false, '2026-09-05 10:00:00'),
  (6, 'SKU-006', 'Ноутбук Базовый', 'Ноутбуки', 50000, 4, true, '2026-09-06 10:00:00'),
  (7, 'SKU-007', 'Монитор 22', 'Мониторы', 10000, 5, true, '2026-09-07 10:00:00'),
  (8, 'SKU-008', 'Монитор 24', 'Мониторы', 15000, 3, true, '2026-09-08 10:00:00'),
  (9, 'SKU-009', 'Монитор 27', 'Мониторы', 20000, 0, true, '2026-09-09 10:00:00'),
  (10, 'SKU-010', 'Монитор 32', 'Мониторы', 35000, 2, true, '2026-09-10 10:00:00'),
  (11, 'SKU-011', 'Монитор Старый', 'Мониторы', 8000, 0, false, '2026-09-11 10:00:00'),
  (12, 'SKU-012', 'Мышь', 'Аксессуары', 990.00, 10, true, '2026-09-12 10:00:00'),
  (13, 'SKU-013', 'Клавиатура', 'Аксессуары', 1800.00, 5, true, '2026-09-13 10:00:00'),
  (14, 'SKU-014', 'Кабель USB', 'Аксессуары', 450.00, 20, true, '2026-09-14 10:00:00'),
  (15, 'SKU-015', 'Подставка', 'Аксессуары', 4500.00, 0, true, '2026-09-15 10:00:00'),
  (16, 'SKU-016', 'Чехол', 'Аксессуары', 1350.00, 4, false, '2026-09-16 10:00:00'),
  (17, 'SKU-017', 'Коврик', 'Аксессуары', 450.00, 0, true, '2026-09-17 10:00:00'),
  (18, 'SKU-018', 'Наушники', 'Аксессуары', 4499.10, 6, true, '2026-09-18 10:00:00'),
  (19, 'SKU-019', 'Веб-камера', 'Аксессуары', 6300.00, 2, true, '2026-09-19 10:00:00'),
  (20, 'SKU-020', 'SSD 256', 'Накопители', 3000, 8, true, '2026-09-20 10:00:00'),
  (21, 'SKU-021', 'SSD 512', 'Накопители', 5000, 9, true, '2026-09-21 10:00:00'),
  (22, 'SKU-022', 'SSD 1024', 'Накопители', 9000, 0, true, '2026-09-22 10:00:00'),
  (23, 'SKU-023', 'HDD 2000', 'Накопители', 6000, 3, false, '2026-09-23 10:00:00'),
  (24, 'SKU-024', 'Флешка', 'Накопители', 1000, 12, true, '2026-09-24 10:00:00'),
  (25, 'SKU-025', 'Роутер Дом', 'Сеть', 4000, 5, true, '2026-09-25 10:00:00'),
  (26, 'SKU-026', 'Роутер Офис', 'Сеть', 12000, 2, true, '2026-09-26 10:00:00'),
  (27, 'SKU-027', 'Коммутатор', 'Сеть', 19999, 0, true, '2026-09-27 10:00:00'),
  (28, 'SKU-028', 'Адаптер Wi-Fi', 'Сеть', 2000, 7, false, '2026-09-28 10:00:00'),
  (29, 'SKU-029', 'Новинка A', NULL, 2500, 1, true, '2026-09-29 10:00:00'),
  (30, 'SKU-030', 'Новинка B', NULL, 20000, 0, false, '2026-09-30 10:00:00')
;
COMMIT;
SET search_path TO lecture04;

-- 4.01. Каков общий профиль каталога?
SELECT COUNT(*) AS items,COUNT(category) AS known_categories,
COUNT(DISTINCT category) AS categories, SUM(stock_quantity) AS units,
ROUND(AVG(price),2) AS avg_price, MIN(price) AS min_price,
MAX(price) AS max_price FROM products;

-- 4.02. Каков профиль только активных товаров?
SELECT COUNT(*) AS items,SUM(stock_quantity) AS units,
ROUND(AVG(price),2) AS avg_price,MIN(price) AS min_price,MAX(price) AS max_price
FROM products WHERE is_active = true;

-- 4.03. Сколько товаров и единиц в каждой категории?
SELECT category,COUNT(*) AS items,SUM(stock_quantity) AS units,
ROUND(AVG(price),2) AS avg_price FROM products
GROUP BY category ORDER BY category NULLS LAST;

-- 4.04. Как категории разделяются по активности?
SELECT category,is_active,COUNT(*) AS items,SUM(stock_quantity) AS units
FROM products GROUP BY category,is_active
ORDER BY category NULLS LAST,is_active DESC;

-- 4.05. В каких категориях не меньше пяти товаров?
SELECT category,COUNT(*) AS items FROM products
GROUP BY category HAVING COUNT(*) >= 5 ORDER BY category;

-- 4.06. У каких категорий суммарный остаток не меньше 15?
SELECT category,SUM(stock_quantity) AS units FROM products
GROUP BY category HAVING SUM(stock_quantity) >= 15 ORDER BY category;

-- 4.07. В каких категориях одновременно не меньше пяти товаров и остаток не меньше 15?
SELECT category,COUNT(*) AS items,SUM(stock_quantity) AS units
FROM products GROUP BY category
HAVING COUNT(*) >= 5 AND SUM(stock_quantity) >= 15 ORDER BY category;

-- 4.08. Сколько активных, неактивных и отсутствующих позиций?
SELECT category,COUNT(*) AS total,
COUNT(*) FILTER (WHERE is_active) AS active,
COUNT(*) FILTER (WHERE NOT is_active) AS inactive,
COUNT(*) FILTER (WHERE stock_quantity = 0) AS zero_stock
FROM products GROUP BY category ORDER BY category NULLS LAST;

-- 4.09. Как товары распределены по ценовым сегментам?
SELECT CASE WHEN price < 5000 THEN 'Бюджет'
            WHEN price < 20000 THEN 'Средний' ELSE 'Высокий' END AS segment,
COUNT(*) AS items,SUM(stock_quantity) AS units
FROM products GROUP BY segment ORDER BY MIN(price);

-- 4.10. Какова доля позиций с нулевым остатком по категориям?
SELECT category,COUNT(*) AS total,
COUNT(*) FILTER (WHERE stock_quantity=0) AS zero_stock,
ROUND(100.0*COUNT(*) FILTER (WHERE stock_quantity=0)/NULLIF(COUNT(*),0),2)
AS zero_stock_percent FROM products
GROUP BY category ORDER BY category NULLS LAST;

-- 4.11. Какие строки подтверждают сумму остатков аксессуаров?
SELECT product_id,product_name,stock_quantity FROM products
WHERE category='Аксессуары' ORDER BY product_id;

-- 4.12. Какие строки подтверждают среднюю цену ноутбуков?
SELECT product_id,product_name,price FROM products
WHERE category='Ноутбуки' ORDER BY product_id;

-- 4.13. Сходятся ли суммы групп с общим каталогом?
WITH g AS (SELECT category,COUNT(*) AS n,SUM(stock_quantity) AS s
FROM products GROUP BY category)
SELECT SUM(n) AS grouped_items,SUM(s) AS grouped_units,
(SELECT COUNT(*) FROM products) AS all_items,
(SELECT SUM(stock_quantity) FROM products) AS all_units FROM g;
