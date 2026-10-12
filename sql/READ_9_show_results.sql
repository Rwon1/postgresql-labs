-- Краткий показ дневной витрины.
SELECT day,orders_count,revenue,ROUND(avg_order,2) AS avg_order
FROM lecture09.mv_l09_daily_sales ORDER BY day LIMIT 8;

-- Работа 9. Запросы к готовым представлениям.

-- 9.04. Гранулярность и общая сумма заказов
SELECT COUNT(*) AS rows_count,COUNT(DISTINCT order_id) AS unique_orders,
       SUM(total) AS view_total,
       (SELECT SUM(quantity*unit_price) FROM lecture08.order_items) AS source_total
FROM lecture09.v_l09_order_totals;

-- 9.05. Сверка одного заказа по его позициям
SELECT v.order_id,v.total AS view_total,COUNT(*) AS positions,
       SUM(i.quantity*i.unit_price) AS source_total
FROM lecture09.v_l09_order_totals v
JOIN lecture08.order_items i USING(order_id)
WHERE v.order_id=(SELECT MIN(order_id) FROM lecture08.orders)
GROUP BY v.order_id,v.total;

-- 9.07. Все клиенты сохранены; клиенты без состоявшихся продаж имеют нулевые показатели
SELECT COUNT(*) AS rows_count,COUNT(DISTINCT customer_id) AS unique_customers,
       COUNT(*) FILTER (WHERE orders_count=0) AS zero_customers,
       SUM(revenue) AS revenue,
       (SELECT COUNT(*) FROM lecture08.customers) AS source_customers
FROM lecture09.v_l09_customer_metrics;

-- 9.08. Клиенты с нулём
SELECT * FROM lecture09.v_l09_customer_metrics
WHERE orders_count=0 ORDER BY customer_id;

-- 9.12. Контроль выручки на всех уровнях с одинаковыми статусами
WITH monthly AS (
 SELECT DATE_TRUNC('month',day) AS month,SUM(revenue) AS revenue
 FROM lecture09.mv_l09_daily_sales GROUP BY 1
)
SELECT (SELECT SUM(i.quantity*i.unit_price) FROM lecture08.orders o
        JOIN lecture08.order_items i USING(order_id)
        WHERE o.status IN ('paid','completed')) AS source_total,
       (SELECT SUM(total) FROM lecture09.v_l09_order_totals
        WHERE status IN ('paid','completed')) AS order_total,
       (SELECT SUM(revenue) FROM lecture09.v_l09_customer_metrics) AS customer_total,
       (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_sales) AS daily_total,
       (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_category) AS category_total,
       (SELECT SUM(revenue) FROM monthly) AS monthly_total;

-- 9.13. Сверка каждого дня с источником в обе стороны
WITH source AS (
 SELECT o.order_date::date AS day,COUNT(DISTINCT o.order_id) AS orders_count,
        SUM(i.quantity*i.unit_price) AS revenue
 FROM lecture08.orders o JOIN lecture08.order_items i USING(order_id)
 WHERE o.status IN ('paid','completed') GROUP BY 1
), daily AS (SELECT day,orders_count,revenue FROM lecture09.mv_l09_daily_sales),
diff AS ((SELECT * FROM source EXCEPT ALL SELECT * FROM daily)
 UNION ALL (SELECT * FROM daily EXCEPT ALL SELECT * FROM source))
SELECT COUNT(*) AS differences FROM diff;

-- 9.14. Проверка уникальности ключей MV и границ дат
SELECT COUNT(*) AS days,COUNT(DISTINCT day) AS unique_days,
       MIN(day) AS first_day,MAX(day) AS last_day,SUM(revenue) AS revenue,
       (SELECT COUNT(*) FROM lecture09.mv_l09_daily_category) AS category_rows,
       (SELECT COUNT(DISTINCT (day,category)) FROM lecture09.mv_l09_daily_category) AS category_keys
FROM lecture09.mv_l09_daily_sales;

-- 9.17. Рейтинг категорий внутри каждого дня
SELECT day,category,orders_count,units,revenue,
       DENSE_RANK() OVER(PARTITION BY day ORDER BY revenue DESC) AS revenue_rank
FROM lecture09.mv_l09_daily_category ORDER BY day,revenue_rank,category;

-- 9.18. Среднее за семь календарных дней: сначала заполняем пропуски календаря
WITH calendar AS (
 SELECT generate_series(MIN(day),MAX(day),INTERVAL '1 day')::date AS day
 FROM lecture09.mv_l09_daily_sales
), daily AS (
 SELECT c.day,COALESCE(v.revenue,0) AS revenue
 FROM calendar c LEFT JOIN lecture09.mv_l09_daily_sales v USING(day)
)
SELECT day,revenue,ROUND(AVG(revenue) OVER(
 ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS avg_7_days
FROM daily ORDER BY day;
