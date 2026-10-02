-- Работа 3. Егоров, группа 16М-нф26.

-- 3.01. Какие товары дороже 10000 есть на складе?
SELECT product_id,product_name,price,stock_quantity FROM lecture03.products
WHERE price > 10000 AND stock_quantity > 0 ORDER BY product_id;

-- 3.02. Что стоит от 5000 до 20000 включительно?
SELECT product_id,product_name,price FROM lecture03.products
WHERE price BETWEEN 5000 AND 20000 ORDER BY price,product_id;

-- 3.03. Что входит в три выбранные категории?
SELECT product_id,product_name,category FROM lecture03.products
WHERE category IN ('Ноутбуки','Мониторы','Сеть') ORDER BY product_id;

-- 3.04. Какие названия начинаются с Монитор с учётом регистра?
SELECT product_id,product_name FROM lecture03.products
WHERE product_name LIKE 'Монитор%' ORDER BY product_id;

-- 3.05. Какие названия содержат ноутбук без учёта регистра?
SELECT product_id,product_name FROM lecture03.products
WHERE product_name ILIKE '%ноутбук%' ORDER BY product_id;

-- 3.06. У каких товаров категория неизвестна?
SELECT product_id,product_name,category FROM lecture03.products
WHERE category IS NULL ORDER BY product_id;

-- 3.07. У каких товаров категория заполнена?
SELECT product_id,product_name,category FROM lecture03.products
WHERE category IS NOT NULL ORDER BY product_id;

-- 3.08. Какие активные ноутбуки или мониторы есть в наличии?
SELECT product_id,product_name,category,stock_quantity FROM lecture03.products
WHERE is_active = true AND (category = 'Ноутбуки' OR category = 'Мониторы')
AND stock_quantity > 0 ORDER BY product_id;

-- 3.09. Как отсортировать товары по категории и убыванию цены?
SELECT product_id,product_name,category,price FROM lecture03.products
ORDER BY category ASC NULLS LAST, price DESC, product_id;

-- 3.10. Какие пять товаров самые дорогие?
SELECT product_id,product_name,price FROM lecture03.products
ORDER BY price DESC,product_id LIMIT 5;

-- 3.11. Как получить вторую страницу по пять товаров?
SELECT product_id,product_name FROM lecture03.products
ORDER BY product_id LIMIT 5 OFFSET 5;

-- 3.12. Какие товары отсутствуют на складе и активны?
SELECT product_id,product_name,price FROM lecture03.products
WHERE stock_quantity = 0 AND is_active = true ORDER BY price,product_id;

-- 3.13. Какие товары не относятся к аксессуарам?
-- Неожиданный результат: 20 строк, а не 22 — сравнение <> исключает также NULL.
SELECT product_id,product_name,category FROM lecture03.products
WHERE category <> 'Аксессуары' ORDER BY product_id;

-- 3.14. Как включить также товары с неизвестной категорией?
SELECT product_id,product_name,category FROM lecture03.products
WHERE category <> 'Аксессуары' OR category IS NULL ORDER BY product_id;

-- 3.15. Какие пять самых дешёвых активных ноутбуков и мониторов доступны до 80000?
-- Ожидание: ID 7, 8, 10, 1, 6; цены 10000, 15000, 35000, 40000, 50000.
SELECT product_id,product_name,category,price,stock_quantity
FROM lecture03.products
WHERE is_active = true
  AND stock_quantity > 0
  AND category IN ('Ноутбуки','Мониторы')
  AND price BETWEEN 10000 AND 80000
ORDER BY price ASC,product_id
LIMIT 5;
