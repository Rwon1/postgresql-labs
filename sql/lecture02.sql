-- Перед запуском задайте папку: SET coursework.data_dir = 'C:/pg_lab/data';
-- Практическая работа 2. Егоров, группа 16М-нф26.
-- Первый запуск в пустой базе; для повторного показа — READ-файлы.
BEGIN;
CREATE SCHEMA lecture02;
SET search_path TO lecture02;
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
  (12, 'SKU-012', 'Мышь', 'Аксессуары', 1000, 10, true, '2026-09-12 10:00:00'),
  (13, 'SKU-013', 'Клавиатура', 'Аксессуары', 2000, 5, true, '2026-09-13 10:00:00'),
  (14, 'SKU-014', 'Кабель USB', 'Аксессуары', 500, 20, true, '2026-09-14 10:00:00'),
  (15, 'SKU-015', 'Подставка', 'Аксессуары', 5000, 0, true, '2026-09-15 10:00:00'),
  (16, 'SKU-016', 'Чехол', 'Аксессуары', 1500, 4, false, '2026-09-16 10:00:00'),
  (17, 'SKU-017', 'Коврик', 'Аксессуары', 500, 0, true, '2026-09-17 10:00:00'),
  (18, 'SKU-018', 'Наушники', 'Аксессуары', 4999, 6, true, '2026-09-18 10:00:00'),
  (19, 'SKU-019', 'Веб-камера', 'Аксессуары', 7000, 2, true, '2026-09-19 10:00:00'),
  (20, 'SKU-020', 'SSD 256', 'Накопители', 3000, 8, true, '2026-09-20 10:00:00'),
  (21, 'SKU-021', 'SSD 512', 'Накопители', 5000, 4, true, '2026-09-21 10:00:00'),
  (22, 'SKU-022', 'SSD 1024', 'Накопители', 9000, 0, true, '2026-09-22 10:00:00')
RETURNING product_id, sku;
SELECT COUNT(*) AS before_csv FROM products; -- 22
COMMIT;
SET search_path TO lecture02;

-- Импорт через pgAdmin: см. README. После импорта пропустите блок DO $import$.
-- Папка с CSV задаётся параметром coursework.data_dir.
DO $import$
BEGIN
  EXECUTE format($copy$COPY products (product_id, sku, product_name, category, price, stock_quantity, is_active, created_at)
FROM %L
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', DELIMITER ',');$copy$,
      current_setting('coursework.data_dir') || '/products_import.csv');
END $import$;
SELECT COUNT(*) AS after_csv FROM products; -- 30
BEGIN;
-- Проверка ограничений на ошибочных INSERT.
CREATE TABLE constraint_checks (
  test_name text, expected_state text, actual_state text, message text
);
DO $check$
BEGIN
  BEGIN
    INSERT INTO products(product_id,sku,product_name,price) VALUES(901,'BAD-NAME',NULL,100);
    RAISE EXCEPTION 'Ожидаемое ограничение не сработало';
  EXCEPTION WHEN SQLSTATE '23502' THEN
    INSERT INTO constraint_checks VALUES
      ('Отсутствующее название','23502',SQLSTATE,SQLERRM);
  END;
END $check$;
DO $check$
BEGIN
  BEGIN
    INSERT INTO products(product_id,sku,product_name,price) VALUES(902,'SKU-001','Ошибка',100);
    RAISE EXCEPTION 'Ожидаемое ограничение не сработало';
  EXCEPTION WHEN SQLSTATE '23505' THEN
    INSERT INTO constraint_checks VALUES
      ('Повтор артикула','23505',SQLSTATE,SQLERRM);
  END;
END $check$;
DO $check$
BEGIN
  BEGIN
    INSERT INTO products(product_id,sku,product_name,price) VALUES(903,'BAD-PRICE','Ошибка',-100);
    RAISE EXCEPTION 'Ожидаемое ограничение не сработало';
  EXCEPTION WHEN SQLSTATE '23514' THEN
    INSERT INTO constraint_checks VALUES
      ('Отрицательная цена','23514',SQLSTATE,SQLERRM);
  END;
END $check$;
DO $check$
BEGIN
  BEGIN
    INSERT INTO products(product_id,sku,product_name,price,stock_quantity) VALUES(904,'BAD-STOCK','Ошибка',100,-5);
    RAISE EXCEPTION 'Ожидаемое ограничение не сработало';
  EXCEPTION WHEN SQLSTATE '23514' THEN
    INSERT INTO constraint_checks VALUES
      ('Отрицательный остаток','23514',SQLSTATE,SQLERRM);
  END;
END $check$;
DO $check$
BEGIN
  BEGIN
    INSERT INTO products(product_id,sku,product_name,price) VALUES(1,'BAD-PK','Ошибка',100);
    RAISE EXCEPTION 'Ожидаемое ограничение не сработало';
  EXCEPTION WHEN SQLSTATE '23505' THEN
    INSERT INTO constraint_checks VALUES
      ('Повтор первичного ключа','23505',SQLSTATE,SQLERRM);
  END;
END $check$;
-- Изменение цены одного товара.
SELECT product_id, price FROM products WHERE product_id = 12;
UPDATE products SET price = 1100 WHERE product_id = 12
RETURNING product_id, price;

-- Увеличение остатка.
SELECT product_id, stock_quantity FROM products WHERE product_id = 21;
UPDATE products SET stock_quantity = stock_quantity + 5
WHERE product_id = 21 RETURNING product_id, stock_quantity;

-- Скидка 10% на аксессуары.
SELECT product_id, price FROM products WHERE category = 'Аксессуары';
UPDATE products SET price = ROUND(price * 0.90,2)
WHERE category = 'Аксессуары' RETURNING product_id, price;

-- Добавление и удаление тестовой строки.
INSERT INTO products (product_id,sku,product_name,price)
VALUES (999,'TEST-DELETE','Тестовая строка для удаления',1)
RETURNING product_id,stock_quantity,is_active,created_at;
SELECT * FROM products WHERE product_id = 999 AND sku = 'TEST-DELETE';
DELETE FROM products WHERE product_id = 999 AND sku = 'TEST-DELETE'
RETURNING product_id,sku;

-- Добавление brand и discount_percent.
ALTER TABLE products ADD COLUMN brand varchar(80);
ALTER TABLE products ADD COLUMN discount_percent numeric(5,2)
  NOT NULL DEFAULT 0;
ALTER TABLE products ADD CONSTRAINT products_discount_check
  CHECK (discount_percent BETWEEN 0 AND 100);
SELECT product_id,brand FROM products WHERE product_id BETWEEN 1 AND 5;
UPDATE products SET brand = 'Учебный бренд'
WHERE product_id BETWEEN 1 AND 5 RETURNING product_id,brand;
SELECT product_id,discount_percent FROM products WHERE category = 'Аксессуары';
UPDATE products SET discount_percent = 10
WHERE category = 'Аксессуары' RETURNING product_id,discount_percent;

-- Дополнительное задание: IDENTITY.
CREATE TABLE identity_test (
  product_id integer PRIMARY KEY,
  product_name varchar(150) NOT NULL
);
ALTER TABLE identity_test ALTER COLUMN product_id
  ADD GENERATED ALWAYS AS IDENTITY;
INSERT INTO identity_test(product_name)
VALUES ('Автоматический номер A'),('Автоматический номер B')
RETURNING *;
COMMIT;

-- Дополнительное задание: три ошибки CSV.
SET search_path TO lecture02;
CREATE TABLE csv_import_test (LIKE products INCLUDING ALL);
CREATE TABLE csv_checks (test_row integer, expected_state text, actual_state text, message text);
DO $test$
BEGIN
  BEGIN
EXECUTE format($copy$    COPY csv_import_test (product_id,sku,product_name,category,price,
      stock_quantity,is_active,created_at)
    FROM %L
    WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
    WHERE (product_id = 23);$copy$,
      current_setting('coursework.data_dir') || '/products_import_with_errors.csv');
    RAISE EXCEPTION 'Ожидалась ошибка импорта';
  EXCEPTION WHEN SQLSTATE '23514' THEN
    INSERT INTO csv_checks VALUES (23,'23514',SQLSTATE,SQLERRM);
  END;
END $test$;
DO $test$
BEGIN
  BEGIN
EXECUTE format($copy$    COPY csv_import_test (product_id,sku,product_name,category,price,
      stock_quantity,is_active,created_at)
    FROM %L
    WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
    WHERE (product_id = 24);$copy$,
      current_setting('coursework.data_dir') || '/products_import_with_errors.csv');
    RAISE EXCEPTION 'Ожидалась ошибка импорта';
  EXCEPTION WHEN SQLSTATE '23502' THEN
    INSERT INTO csv_checks VALUES (24,'23502',SQLSTATE,SQLERRM);
  END;
END $test$;
DO $test$
BEGIN
  BEGIN
EXECUTE format($copy$    COPY csv_import_test (product_id,sku,product_name,category,price,
      stock_quantity,is_active,created_at)
    FROM %L
    WITH (FORMAT csv,HEADER true,ENCODING 'UTF8')
    WHERE (product_id = 25);$copy$,
      current_setting('coursework.data_dir') || '/products_import_with_errors.csv');
    RAISE EXCEPTION 'Ожидалась ошибка импорта';
  EXCEPTION WHEN SQLSTATE '23514' THEN
    INSERT INTO csv_checks VALUES (25,'23514',SQLSTATE,SQLERRM);
  END;
END $test$;
SELECT * FROM csv_checks ORDER BY test_row;
SELECT COUNT(*) AS rows_imported FROM csv_import_test;

-- 2.01. Каково итоговое состояние товаров?
SELECT product_id,sku,product_name,category,price,stock_quantity,
brand,discount_percent FROM products ORDER BY product_id;

-- 2.02. Какие количественные требования выполнены?
SELECT COUNT(*) AS products, COUNT(DISTINCT category) AS categories,
COUNT(*) FILTER (WHERE brand IS NOT NULL) AS with_brand,
COUNT(*) FILTER (WHERE sku = 'TEST-DELETE') AS test_rows FROM products;

-- 2.03. Какие ошибки действительно были отклонены?
SELECT * FROM constraint_checks ORDER BY test_name;

-- 2.04. Какие номера выдала IDENTITY?
SELECT * FROM identity_test ORDER BY product_id;

-- 2.05. Есть ли brand, скидка и её значение по умолчанию?
SELECT column_name,data_type,column_default,is_nullable
FROM information_schema.columns
WHERE table_schema='lecture02' AND table_name='products'
ORDER BY ordinal_position;
