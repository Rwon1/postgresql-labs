-- Краткий показ: пять покупателей с наибольшей выручкой.
SELECT customer_id,orders_count,revenue FROM (
 SELECT o.customer_id,COUNT(DISTINCT o.order_id) AS orders_count,
        SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture06.orders o JOIN lecture06.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped') GROUP BY o.customer_id
) totals ORDER BY revenue DESC,customer_id LIMIT 5;

-- Работа 6. Запросы к готовым таблицам.

-- 6.01. Товары дороже средней цены каталога
SELECT product_id,product_name,price FROM lecture06.products
WHERE price>(SELECT AVG(price) FROM lecture06.products) ORDER BY price DESC,product_id;

-- 6.02. Самый дорогой активный товар — все совпадения максимума
SELECT product_id,product_name,price FROM lecture06.products
WHERE is_active AND price=(SELECT MAX(price) FROM lecture06.products WHERE is_active)
ORDER BY product_id;

-- 6.03. Клиенты с заказами через IN
SELECT customer_id,full_name FROM lecture06.customers
WHERE customer_id IN (SELECT customer_id FROM lecture06.orders) ORDER BY customer_id;

-- 6.04. Средний чек всех заказов через подзапрос в FROM
SELECT ROUND(AVG(x.total),2) AS avg_order_value
FROM (SELECT o.order_id,COALESCE(SUM(i.quantity*i.unit_price),0) AS total
      FROM lecture06.orders o LEFT JOIN lecture06.order_items i USING(order_id) GROUP BY o.order_id) x;

-- 6.05. Заказы на сумму более 1000000
SELECT * FROM (
  SELECT order_id,SUM(quantity*unit_price) AS total
  FROM lecture06.order_items GROUP BY order_id
) x WHERE total>1000000 ORDER BY total DESC,order_id;

-- 6.06. Клиенты хотя бы с одним paid-заказом: коррелированный EXISTS
SELECT c.customer_id,c.full_name FROM lecture06.customers c
WHERE EXISTS (SELECT 1 FROM lecture06.orders o WHERE o.customer_id=c.customer_id AND o.status='paid')
ORDER BY c.customer_id;

-- 6.07. Клиенты без заказов
SELECT c.customer_id,c.full_name FROM lecture06.customers c
WHERE NOT EXISTS (SELECT 1 FROM lecture06.orders o WHERE o.customer_id=c.customer_id)
ORDER BY c.customer_id;

-- 6.08. Товары, не встречавшиеся ни в одном заказе
SELECT p.product_id,p.product_name FROM lecture06.products p
WHERE NOT EXISTS (SELECT 1 FROM lecture06.order_items i WHERE i.product_id=p.product_id)
ORDER BY p.product_id;

-- 6.09. Товары без состоявшихся продаж в январе 2026
SELECT p.product_id,p.product_name FROM lecture06.products p
WHERE NOT EXISTS (
 SELECT 1 FROM lecture06.order_items i JOIN lecture06.orders o USING(order_id)
 WHERE i.product_id=p.product_id AND o.status IN ('paid','shipped')
   AND o.order_date>=TIMESTAMP '2026-01-01' AND o.order_date<TIMESTAMP '2026-02-01'
) ORDER BY p.product_id;

-- 6.10. Покупали, но никогда не покупали ноутбуки
SELECT c.customer_id,c.full_name FROM lecture06.customers c
WHERE EXISTS (SELECT 1 FROM lecture06.orders o JOIN lecture06.order_items i USING(order_id)
              WHERE o.customer_id=c.customer_id AND o.status IN ('paid','shipped'))
AND NOT EXISTS (
 SELECT 1 FROM lecture06.orders o JOIN lecture06.order_items i USING(order_id) JOIN lecture06.products p USING(product_id)
 WHERE o.customer_id=c.customer_id AND o.status IN ('paid','shipped') AND p.category='Ноутбуки'
) ORDER BY c.customer_id;

-- 6.11. Товары дороже средней цены собственной категории
SELECT p.product_id,p.product_name,p.category,p.price FROM lecture06.products p
WHERE p.price>(SELECT AVG(p2.price) FROM lecture06.products p2
               WHERE p2.category IS NOT DISTINCT FROM p.category)
ORDER BY p.category,p.price DESC,p.product_id;

-- 6.12. CTE 1: суммы состоявшихся заказов — проверка этапа
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM lecture06.orders o LEFT JOIN lecture06.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped')
 GROUP BY o.order_id,o.customer_id,o.order_date
)
SELECT * FROM order_totals ORDER BY order_id;

-- 6.13. CTE 2: показатели покупателей — проверка этапа
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM lecture06.orders o LEFT JOIN lecture06.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped')
 GROUP BY o.order_id,o.customer_id,o.order_date
), customer_stats AS (
 SELECT customer_id,COUNT(*) AS orders_count,SUM(total) AS revenue,
        AVG(total) AS avg_order,MAX(order_date) AS last_order
 FROM order_totals GROUP BY customer_id
)
SELECT * FROM customer_stats ORDER BY customer_id;

-- 6.14. Полный клиентский отчёт: одна строка на клиента
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM lecture06.orders o LEFT JOIN lecture06.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped')
 GROUP BY o.order_id,o.customer_id,o.order_date
), customer_stats AS (
 SELECT customer_id,COUNT(*) AS orders_count,SUM(total) AS revenue,
        AVG(total) AS avg_order,MAX(order_date) AS last_order
 FROM order_totals GROUP BY customer_id
)
SELECT c.customer_id,c.full_name,COALESCE(s.orders_count,0) AS orders_count,
       COALESCE(s.revenue,0) AS revenue,ROUND(s.avg_order,2) AS avg_order,s.last_order
FROM lecture06.customers c LEFT JOIN customer_stats s USING(customer_id)
ORDER BY revenue DESC,c.customer_id;

-- 6.15. Контроль CTE: число заказов, уникальность и сумма
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM lecture06.orders o LEFT JOIN lecture06.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped')
 GROUP BY o.order_id,o.customer_id,o.order_date
), customer_stats AS (
 SELECT customer_id,COUNT(*) AS orders_count,SUM(total) AS revenue,
        AVG(total) AS avg_order,MAX(order_date) AS last_order
 FROM order_totals GROUP BY customer_id
)
SELECT (SELECT COUNT(*) FROM order_totals) AS orders,
       (SELECT COUNT(DISTINCT order_id) FROM order_totals) AS unique_orders,
       (SELECT SUM(orders_count) FROM customer_stats) AS customer_orders,
       (SELECT SUM(total) FROM order_totals) AS order_sum,
       (SELECT SUM(revenue) FROM customer_stats) AS customer_sum,
       (SELECT SUM(i.quantity*i.unit_price) FROM lecture06.order_items i JOIN lecture06.orders o USING(order_id)
        WHERE o.status IN ('paid','shipped')) AS source_sum;

-- 6.16. Собственный анализ: какие города дали выручку за полугодие? Этап — заказ
WITH period_orders AS (
 SELECT order_id,customer_id FROM lecture06.orders WHERE status IN ('paid','shipped')
 AND order_date>=TIMESTAMP '2026-01-01' AND order_date<TIMESTAMP '2026-07-01'
)
SELECT * FROM period_orders ORDER BY order_id;

-- 6.17. Второй этап собственного анализа: одна строка на заказ с суммой
WITH period_orders AS (
 SELECT order_id,customer_id FROM lecture06.orders WHERE status IN ('paid','shipped')
 AND order_date>=TIMESTAMP '2026-01-01' AND order_date<TIMESTAMP '2026-07-01'
), order_amounts AS (
 SELECT o.order_id,o.customer_id,SUM(i.quantity*i.unit_price) AS total
 FROM period_orders o JOIN lecture06.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id
)
SELECT * FROM order_amounts ORDER BY order_id;

-- 6.18. Итог собственного анализа: одна строка на город
WITH period_orders AS (
 SELECT order_id,customer_id FROM lecture06.orders WHERE status IN ('paid','shipped')
 AND order_date>=TIMESTAMP '2026-01-01' AND order_date<TIMESTAMP '2026-07-01'
), order_amounts AS (
 SELECT o.order_id,o.customer_id,SUM(i.quantity*i.unit_price) AS total
 FROM period_orders o JOIN lecture06.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id
)
SELECT c.city,COUNT(*) AS orders_count,SUM(a.total) AS revenue
FROM order_amounts a JOIN lecture06.customers c USING(customer_id)
GROUP BY c.city ORDER BY revenue DESC,c.city;

-- 6.19. Сверка собственного анализа с исходными позициями
WITH period_orders AS (
 SELECT order_id,customer_id FROM lecture06.orders WHERE status IN ('paid','shipped')
 AND order_date>=TIMESTAMP '2026-01-01' AND order_date<TIMESTAMP '2026-07-01'
), order_amounts AS (
 SELECT o.order_id,o.customer_id,SUM(i.quantity*i.unit_price) AS total
 FROM period_orders o JOIN lecture06.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id
)
SELECT (SELECT COUNT(*) FROM period_orders) AS selected_orders,
       (SELECT COUNT(*) FROM order_amounts) AS grouped_orders,
       (SELECT SUM(total) FROM order_amounts) AS grouped_sum,
       (SELECT SUM(i.quantity*i.unit_price) FROM period_orders o JOIN lecture06.order_items i USING(order_id)) AS source_sum;

-- 6.20. Продажи товаров: промежуточный CTE
WITH product_sales AS (
 SELECT i.product_id,COUNT(DISTINCT o.order_id) AS orders_count,
        SUM(i.quantity) AS units,SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture06.orders o JOIN lecture06.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped') GROUP BY i.product_id
)
SELECT * FROM product_sales ORDER BY product_id;

-- 6.21. Полный каталог с продажами и нулевыми товарами
WITH product_sales AS (
 SELECT i.product_id,COUNT(DISTINCT o.order_id) AS orders_count,
        SUM(i.quantity) AS units,SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture06.orders o JOIN lecture06.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped') GROUP BY i.product_id
)
SELECT p.product_id,p.product_name,p.category,COALESCE(s.orders_count,0) AS orders_count,
       COALESCE(s.units,0) AS units,COALESCE(s.revenue,0) AS revenue
FROM lecture06.products p LEFT JOIN product_sales s USING(product_id) ORDER BY p.product_id;

-- 6.22. Контроль товарного отчёта
WITH product_sales AS (
 SELECT i.product_id,COUNT(DISTINCT o.order_id) AS orders_count,
        SUM(i.quantity) AS units,SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture06.orders o JOIN lecture06.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped') GROUP BY i.product_id
)
SELECT COUNT(*) AS catalog_count,COUNT(s.product_id) AS sold_products,
       SUM(COALESCE(s.revenue,0)) AS report_total,
       (SELECT SUM(i.quantity*i.unit_price) FROM lecture06.orders o JOIN lecture06.order_items i USING(order_id)
        WHERE o.status IN ('paid','shipped')) AS source_total
FROM lecture06.products p LEFT JOIN product_sales s USING(product_id);

-- 6.23. Третий этап анализа за полугодие: статистика клиентов
WITH period_orders AS (
 SELECT order_id,customer_id FROM lecture06.orders WHERE status IN ('paid','shipped')
 AND order_date>=TIMESTAMP '2026-01-01' AND order_date<TIMESTAMP '2026-07-01'
), order_amounts AS (
 SELECT o.order_id,o.customer_id,SUM(i.quantity*i.unit_price) AS total
 FROM period_orders o JOIN lecture06.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id
), customer_period AS (
 SELECT customer_id,COUNT(*) AS orders_count,SUM(total) AS revenue,
        AVG(total) AS avg_order
 FROM order_amounts GROUP BY customer_id
)
SELECT * FROM customer_period ORDER BY customer_id;

-- 6.24. Кто и на какую сумму покупал в первом полугодии 2026?
WITH period_orders AS (
 SELECT order_id,customer_id FROM lecture06.orders WHERE status IN ('paid','shipped')
 AND order_date>=TIMESTAMP '2026-01-01' AND order_date<TIMESTAMP '2026-07-01'
), order_amounts AS (
 SELECT o.order_id,o.customer_id,SUM(i.quantity*i.unit_price) AS total
 FROM period_orders o JOIN lecture06.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id
), customer_period AS (
 SELECT customer_id,COUNT(*) AS orders_count,SUM(total) AS revenue,
        AVG(total) AS avg_order
 FROM order_amounts GROUP BY customer_id
)
SELECT c.customer_id,c.full_name,COALESCE(p.orders_count,0) AS orders_count,
       COALESCE(p.revenue,0) AS revenue,ROUND(p.avg_order,2) AS avg_order
FROM lecture06.customers c LEFT JOIN customer_period p USING(customer_id)
ORDER BY revenue DESC,c.customer_id;

-- 6.25. Сверка трёх этапов анализа клиентов
WITH period_orders AS (
 SELECT order_id,customer_id FROM lecture06.orders WHERE status IN ('paid','shipped')
 AND order_date>=TIMESTAMP '2026-01-01' AND order_date<TIMESTAMP '2026-07-01'
), order_amounts AS (
 SELECT o.order_id,o.customer_id,SUM(i.quantity*i.unit_price) AS total
 FROM period_orders o JOIN lecture06.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id
), customer_period AS (
 SELECT customer_id,COUNT(*) AS orders_count,SUM(total) AS revenue,
        AVG(total) AS avg_order
 FROM order_amounts GROUP BY customer_id
)
SELECT (SELECT COUNT(*) FROM order_amounts) AS source_orders,
       SUM(orders_count) AS report_orders,SUM(revenue) AS report_total,
       (SELECT SUM(total) FROM order_amounts) AS source_total
FROM customer_period;
