-- Краткий показ трёх рейтингов на одной категории.
SELECT product_id,price,
 ROW_NUMBER() OVER (ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (ORDER BY price DESC) AS drnk
FROM lecture07.products WHERE category='Ноутбуки'
ORDER BY price DESC,product_id LIMIT 8;

-- Работа 7. Запросы к готовым таблицам.

-- 7.01. Количество строк в четырёх таблицах
SELECT 'customers' AS table_name,COUNT(*) AS rows_count FROM lecture07.customers
UNION ALL SELECT 'products',COUNT(*) FROM lecture07.products
UNION ALL SELECT 'orders',COUNT(*) FROM lecture07.orders
UNION ALL SELECT 'order_items',COUNT(*) FROM lecture07.order_items;

-- 7.02. Одна строка результата означает заказ; окна сохраняют детализацию
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,o.status,
        COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM lecture07.orders o LEFT JOIN lecture07.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id,o.order_date,o.status
)
SELECT order_id,customer_id,total,COUNT(*) OVER () AS all_orders,
       COUNT(*) OVER (PARTITION BY customer_id) AS customer_orders,
       SUM(total) OVER (PARTITION BY customer_id) AS customer_total,
       ROUND(AVG(total) OVER (PARTITION BY customer_id),2) AS customer_avg
FROM order_totals ORDER BY customer_id,order_id;

-- 7.03. Контроль order_totals: уникальность заказов и сумма позиций
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,o.status,
        COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM lecture07.orders o LEFT JOIN lecture07.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id,o.order_date,o.status
)
SELECT COUNT(*) AS orders,COUNT(DISTINCT order_id) AS unique_orders,SUM(total) AS total,
       (SELECT SUM(quantity*unit_price) FROM lecture07.order_items) AS source_total
FROM order_totals;

-- 7.04. Сверка одной секции окна: клиент 770001
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,o.status,
        COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM lecture07.orders o LEFT JOIN lecture07.order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id,o.order_date,o.status
)
SELECT customer_id,COUNT(*) AS customer_orders,SUM(total) AS customer_total,
       ROUND(AVG(total),2) AS customer_avg
FROM order_totals WHERE customer_id=770001 GROUP BY customer_id;

-- 7.05. Одна строка результата означает товар с тремя номерами рейтинга
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM lecture07.products
)
SELECT * FROM ranking ORDER BY category,price DESC,product_id;

-- 7.06. Одна строка результата означает товар в top-3; ROW_NUMBER: ровно три товара
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM lecture07.products
)
SELECT * FROM ranking WHERE rn<=3 ORDER BY category,price DESC,product_id;

-- 7.07. Одна строка результата означает товар в top-3; RANK: первые три места с ничьими и пропусками
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM lecture07.products
)
SELECT * FROM ranking WHERE rnk<=3 ORDER BY category,price DESC,product_id;

-- 7.08. Одна строка результата означает товар в top-3; DENSE_RANK: три уровня цены с ничьими
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM lecture07.products
)
SELECT * FROM ranking WHERE drnk<=3 ORDER BY category,price DESC,product_id;

-- 7.09. Контроль размеров top-3 и количества уровней цены
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM lecture07.products
)
SELECT category,COUNT(*) FILTER (WHERE rn<=3) AS row_number_top,
 COUNT(*) FILTER (WHERE rnk<=3) AS rank_top,
 COUNT(*) FILTER (WHERE drnk<=3) AS dense_rank_top,
 COUNT(DISTINCT price) FILTER (WHERE drnk<=3) AS price_levels
FROM ranking GROUP BY category ORDER BY category;

-- 7.10. Одна строка результата означает календарный месяц состоявшихся продаж
WITH monthly AS (
 SELECT DATE_TRUNC('month',o.order_date)::date AS month,
        SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture07.orders o JOIN lecture07.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped') GROUP BY 1
), calendar AS (
 SELECT g::date AS month FROM generate_series(
 (SELECT MIN(month) FROM monthly),(SELECT MAX(month) FROM monthly),INTERVAL '1 month') g
), series AS (
 SELECT c.month,COALESCE(m.revenue,0) AS revenue
 FROM calendar c LEFT JOIN monthly m USING(month)
), windows AS (
 SELECT month,revenue,LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
 SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
 AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
 FROM series
)
SELECT month,revenue,prev_revenue,revenue-prev_revenue AS delta,
       ROUND(100*(revenue-prev_revenue)/NULLIF(prev_revenue,0),2) AS change_pct,
       running_total,ROUND(moving_avg,2) AS moving_avg_3
FROM windows ORDER BY month;

-- 7.11. Контроль последнего накопительного итога и исходной суммы
WITH monthly AS (
 SELECT DATE_TRUNC('month',o.order_date)::date AS month,
        SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture07.orders o JOIN lecture07.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped') GROUP BY 1
), calendar AS (
 SELECT g::date AS month FROM generate_series(
 (SELECT MIN(month) FROM monthly),(SELECT MAX(month) FROM monthly),INTERVAL '1 month') g
), series AS (
 SELECT c.month,COALESCE(m.revenue,0) AS revenue
 FROM calendar c LEFT JOIN monthly m USING(month)
), windows AS (
 SELECT month,revenue,LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
 SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
 AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
 FROM series
)
SELECT (SELECT COUNT(*) FROM series) AS months,
       (SELECT SUM(revenue) FROM series) AS monthly_sum,
       (SELECT running_total FROM windows ORDER BY month DESC LIMIT 1) AS last_running,
       (SELECT SUM(i.quantity*i.unit_price) FROM lecture07.orders o JOIN lecture07.order_items i USING(order_id)
        WHERE o.status IN ('paid','shipped')) AS source_sum;

-- 7.12. Сверка скользящего среднего третьего месяца с первыми тремя строками
WITH monthly AS (
 SELECT DATE_TRUNC('month',o.order_date)::date AS month,
        SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture07.orders o JOIN lecture07.order_items i USING(order_id)
 WHERE o.status IN ('paid','shipped') GROUP BY 1
), calendar AS (
 SELECT g::date AS month FROM generate_series(
 (SELECT MIN(month) FROM monthly),(SELECT MAX(month) FROM monthly),INTERVAL '1 month') g
), series AS (
 SELECT c.month,COALESCE(m.revenue,0) AS revenue
 FROM calendar c LEFT JOIN monthly m USING(month)
), windows AS (
 SELECT month,revenue,LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
 SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
 AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
 FROM series
)
SELECT (SELECT ROUND(moving_avg,2) FROM windows ORDER BY month OFFSET 2 LIMIT 1) AS window_avg,
       (SELECT ROUND(AVG(revenue),2) FROM (SELECT revenue FROM series ORDER BY month LIMIT 3) x) AS direct_avg;

-- 7.13. Одна строка результата означает месяц и категорию; три разных окна
WITH monthly_category AS (
 SELECT DATE_TRUNC('month',o.order_date)::date AS month,p.category,
        SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture07.orders o JOIN lecture07.order_items i USING(order_id) JOIN lecture07.products p USING(product_id)
 WHERE o.status IN ('paid','shipped') GROUP BY 1,2
), grid AS (
 SELECT g::date AS month,c.category
 FROM generate_series((SELECT MIN(month) FROM monthly_category),
      (SELECT MAX(month) FROM monthly_category),INTERVAL '1 month') g
 CROSS JOIN (SELECT DISTINCT category FROM lecture07.products) c
), series AS (
 SELECT g.month,g.category,COALESCE(m.revenue,0) AS revenue
 FROM grid g LEFT JOIN monthly_category m
 ON m.month=g.month AND m.category IS NOT DISTINCT FROM g.category
), report AS (
 SELECT month,category,revenue,
 LAG(revenue) OVER (PARTITION BY category ORDER BY month) AS prev_revenue,
 SUM(revenue) OVER (PARTITION BY category ORDER BY month
     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
 RANK() OVER (PARTITION BY month ORDER BY revenue DESC) AS rank_in_month
 FROM series
)
SELECT month,category,revenue,revenue-prev_revenue AS delta,running_total,rank_in_month
FROM report ORDER BY month,rank_in_month,category;

-- 7.14. Контроль комплексного отчёта по каждой категории
WITH monthly_category AS (
 SELECT DATE_TRUNC('month',o.order_date)::date AS month,p.category,
        SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture07.orders o JOIN lecture07.order_items i USING(order_id) JOIN lecture07.products p USING(product_id)
 WHERE o.status IN ('paid','shipped') GROUP BY 1,2
), grid AS (
 SELECT g::date AS month,c.category
 FROM generate_series((SELECT MIN(month) FROM monthly_category),
      (SELECT MAX(month) FROM monthly_category),INTERVAL '1 month') g
 CROSS JOIN (SELECT DISTINCT category FROM lecture07.products) c
), series AS (
 SELECT g.month,g.category,COALESCE(m.revenue,0) AS revenue
 FROM grid g LEFT JOIN monthly_category m
 ON m.month=g.month AND m.category IS NOT DISTINCT FROM g.category
), report AS (
 SELECT month,category,revenue,
 LAG(revenue) OVER (PARTITION BY category ORDER BY month) AS prev_revenue,
 SUM(revenue) OVER (PARTITION BY category ORDER BY month
     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
 RANK() OVER (PARTITION BY month ORDER BY revenue DESC) AS rank_in_month
 FROM series
)
SELECT category,SUM(revenue) AS category_sum,MAX(running_total) AS last_running,
 COUNT(*) AS months,COUNT(DISTINCT month) AS unique_months
FROM report GROUP BY category ORDER BY category;
