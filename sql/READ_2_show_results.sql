-- Работа 2. Егоров, группа 16М-нф26.

-- 2.01. Каково итоговое состояние товаров?
SELECT product_id,sku,product_name,category,price,stock_quantity,
brand,discount_percent FROM lecture02.products ORDER BY product_id;

-- 2.02. Какие количественные требования выполнены?
SELECT COUNT(*) AS products, COUNT(DISTINCT category) AS categories,
COUNT(*) FILTER (WHERE brand IS NOT NULL) AS with_brand,
COUNT(*) FILTER (WHERE sku = 'TEST-DELETE') AS test_rows FROM lecture02.products;

-- 2.03. Какие ошибки действительно были отклонены?
SELECT * FROM lecture02.constraint_checks ORDER BY test_name;

-- 2.04. Какие номера выдала IDENTITY?
SELECT * FROM lecture02.identity_test ORDER BY product_id;

-- 2.05. Есть ли brand, скидка и её значение по умолчанию?
SELECT column_name,data_type,column_default,is_nullable
FROM information_schema.columns
WHERE table_schema='lecture02' AND table_name='products'
ORDER BY ordinal_position;

-- 2.06. Какие ошибки CSV отклонены?
SELECT test_row, expected_state, actual_state, message
FROM lecture02.csv_checks ORDER BY test_row;
