-- Перед запуском задайте папку: SET coursework.data_dir = 'C:/pg_lab/data';
-- ЧАСТЬ 2: выполнить ПОСЛЕ импорта 8 строк CSV через окно pgAdmin.
SET search_path TO lecture02;
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
