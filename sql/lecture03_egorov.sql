-- Практическая работа 3. Егоров, группа 16М-нф26.
-- Первый запуск в пустой базе; для повторного показа — READ-файлы.
BEGIN;
CREATE SCHEMA lecture03;
SET search_path TO lecture03;
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
SET search_path TO lecture03;

-- 3.01. Какие товары дороже 10000 есть на складе?
SELECT product_id,product_name,price,stock_quantity FROM products
WHERE price > 10000 AND stock_quantity > 0 ORDER BY product_id;

-- 3.02. Что стоит от 5000 до 20000 включительно?
SELECT product_id,product_name,price FROM products
WHERE price BETWEEN 5000 AND 20000 ORDER BY price,product_id;

-- 3.03. Что входит в три выбранные категории?
SELECT product_id,product_name,category FROM products
WHERE category IN ('Ноутбуки','Мониторы','Сеть') ORDER BY product_id;

-- 3.04. Какие названия начинаются с Монитор с учётом регистра?
SELECT product_id,product_name FROM products
WHERE product_name LIKE 'Монитор%' ORDER BY product_id;

-- 3.05. Какие названия содержат ноутбук без учёта регистра?
SELECT product_id,product_name FROM products
WHERE product_name ILIKE '%ноутбук%' ORDER BY product_id;

-- 3.06. У каких товаров категория неизвестна?
SELECT product_id,product_name,category FROM products
WHERE category IS NULL ORDER BY product_id;

-- 3.07. У каких товаров категория заполнена?
SELECT product_id,product_name,category FROM products
WHERE category IS NOT NULL ORDER BY product_id;

-- 3.08. Какие активные ноутбуки или мониторы есть в наличии?
SELECT product_id,product_name,category,stock_quantity FROM products
WHERE is_active = true AND (category = 'Ноутбуки' OR category = 'Мониторы')
AND stock_quantity > 0 ORDER BY product_id;

-- 3.09. Как отсортировать товары по категории и убыванию цены?
SELECT product_id,product_name,category,price FROM products
ORDER BY category ASC NULLS LAST, price DESC, product_id;

-- 3.10. Какие пять товаров самые дорогие?
SELECT product_id,product_name,price FROM products
ORDER BY price DESC,product_id LIMIT 5;

-- 3.11. Как получить вторую страницу по пять товаров?
SELECT product_id,product_name FROM products
ORDER BY product_id LIMIT 5 OFFSET 5;

-- 3.12. Какие товары отсутствуют на складе и активны?
SELECT product_id,product_name,price FROM products
WHERE stock_quantity = 0 AND is_active = true ORDER BY price,product_id;

-- 3.13. Какие товары не относятся к аксессуарам?
-- Неожиданный результат: 20 строк, а не 22 — сравнение <> исключает также NULL.
SELECT product_id,product_name,category FROM products
WHERE category <> 'Аксессуары' ORDER BY product_id;

-- 3.14. Как включить также товары с неизвестной категорией?
SELECT product_id,product_name,category FROM products
WHERE category <> 'Аксессуары' OR category IS NULL ORDER BY product_id;

-- 3.15. Какие пять самых дешёвых активных ноутбуков и мониторов доступны до 80000?
-- Ожидание: ID 7, 8, 10, 1, 6; цены 10000, 15000, 35000, 40000, 50000.
SELECT product_id,product_name,category,price,stock_quantity
FROM products
WHERE is_active = true
  AND stock_quantity > 0
  AND category IN ('Ноутбуки','Мониторы')
  AND price BETWEEN 10000 AND 80000
ORDER BY price ASC,product_id
LIMIT 5;

-- Итоговый запрос: объяснение по требованию задания.
-- SELECT: показать номер, название, категорию, цену и остаток.
-- FROM: таблица товаров.
-- WHERE is_active: оставить активные позиции.
-- AND stock_quantity > 0: оставить товары в наличии.
-- AND category IN: выбрать только ноутбуки и мониторы.
-- AND price BETWEEN: включить цены от 10000 до 80000 с обеими границами.
-- ORDER BY: от дешёвых к дорогим; при равенстве - по product_id.
-- LIMIT: показать первые пять строк уже отсортированного результата.
-- Результат: ID 7, 8, 10, 1, 6 — совпал с ожиданием.
