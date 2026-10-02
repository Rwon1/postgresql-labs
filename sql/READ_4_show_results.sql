-- Работа 4. Егоров, группа 16М-нф26.

-- 4.01. Каков общий профиль каталога?
SELECT COUNT(*) AS items,COUNT(category) AS known_categories,
COUNT(DISTINCT category) AS categories, SUM(stock_quantity) AS units,
ROUND(AVG(price),2) AS avg_price, MIN(price) AS min_price,
MAX(price) AS max_price FROM lecture04.products;

-- 4.02. Каков профиль только активных товаров?
SELECT COUNT(*) AS items,SUM(stock_quantity) AS units,
ROUND(AVG(price),2) AS avg_price,MIN(price) AS min_price,MAX(price) AS max_price
FROM lecture04.products WHERE is_active = true;

-- 4.03. Сколько товаров и единиц в каждой категории?
SELECT category,COUNT(*) AS items,SUM(stock_quantity) AS units,
ROUND(AVG(price),2) AS avg_price FROM lecture04.products
GROUP BY category ORDER BY category NULLS LAST;

-- 4.04. Как категории разделяются по активности?
SELECT category,is_active,COUNT(*) AS items,SUM(stock_quantity) AS units
FROM lecture04.products GROUP BY category,is_active
ORDER BY category NULLS LAST,is_active DESC;

-- 4.05. В каких категориях не меньше пяти товаров?
SELECT category,COUNT(*) AS items FROM lecture04.products
GROUP BY category HAVING COUNT(*) >= 5 ORDER BY category;

-- 4.06. У каких категорий суммарный остаток не меньше 15?
SELECT category,SUM(stock_quantity) AS units FROM lecture04.products
GROUP BY category HAVING SUM(stock_quantity) >= 15 ORDER BY category;

-- 4.07. В каких категориях одновременно не меньше пяти товаров и остаток не меньше 15?
SELECT category,COUNT(*) AS items,SUM(stock_quantity) AS units
FROM lecture04.products GROUP BY category
HAVING COUNT(*) >= 5 AND SUM(stock_quantity) >= 15 ORDER BY category;

-- 4.08. Сколько активных, неактивных и отсутствующих позиций?
SELECT category,COUNT(*) AS total,
COUNT(*) FILTER (WHERE is_active) AS active,
COUNT(*) FILTER (WHERE NOT is_active) AS inactive,
COUNT(*) FILTER (WHERE stock_quantity = 0) AS zero_stock
FROM lecture04.products GROUP BY category ORDER BY category NULLS LAST;

-- 4.09. Как товары распределены по ценовым сегментам?
SELECT CASE WHEN price < 5000 THEN 'Бюджет'
            WHEN price < 20000 THEN 'Средний' ELSE 'Высокий' END AS segment,
COUNT(*) AS items,SUM(stock_quantity) AS units
FROM lecture04.products GROUP BY segment ORDER BY MIN(price);

-- 4.10. Какова доля позиций с нулевым остатком по категориям?
SELECT category,COUNT(*) AS total,
COUNT(*) FILTER (WHERE stock_quantity=0) AS zero_stock,
ROUND(100.0*COUNT(*) FILTER (WHERE stock_quantity=0)/NULLIF(COUNT(*),0),2)
AS zero_stock_percent FROM lecture04.products
GROUP BY category ORDER BY category NULLS LAST;

-- 4.11. Какие строки подтверждают сумму остатков аксессуаров?
SELECT product_id,product_name,stock_quantity FROM lecture04.products
WHERE category='Аксессуары' ORDER BY product_id;

-- 4.12. Какие строки подтверждают среднюю цену ноутбуков?
SELECT product_id,product_name,price FROM lecture04.products
WHERE category='Ноутбуки' ORDER BY product_id;

-- 4.13. Сходятся ли суммы групп с общим каталогом?
WITH g AS (SELECT category,COUNT(*) AS n,SUM(stock_quantity) AS s
FROM lecture04.products GROUP BY category)
SELECT SUM(n) AS grouped_items,SUM(s) AS grouped_units,
(SELECT COUNT(*) FROM lecture04.products) AS all_items,
(SELECT SUM(stock_quantity) FROM lecture04.products) AS all_units FROM g;
