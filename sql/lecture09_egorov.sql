-- Практическая работа 9. Егоров, группа 16М-нф26.
-- lecture_09_seed.sql не предоставлен: использованы данные работы 8 (lecture08).
-- Сначала выполнить lecture08_egorov.sql. Исходные таблицы не удаляются.
-- VIEW хранит запрос и читает актуальные данные; MV хранит результат до REFRESH.
-- Выручка = quantity * unit_price, статусы paid + completed; день = дата заказа.
-- Зависимости: orders/items -> order_totals -> customer_metrics и daily_sales.
-- orders/items/products -> daily_category. Между двумя MV зависимости нет.

-- 9.01. Исходные данные
SELECT 'customers' AS table_name,COUNT(*) AS rows_count FROM lecture08.customers
UNION ALL SELECT 'products',COUNT(*) FROM lecture08.products
UNION ALL SELECT 'orders',COUNT(*) FROM lecture08.orders
UNION ALL SELECT 'order_items',COUNT(*) FROM lecture08.order_items;

-- 9.02. Объекты работы: удаление в порядке зависимостей
CREATE SCHEMA IF NOT EXISTS lecture09;
DROP MATERIALIZED VIEW IF EXISTS lecture09.mv_l09_daily_category;
DROP MATERIALIZED VIEW IF EXISTS lecture09.mv_l09_daily_sales;
DROP VIEW IF EXISTS lecture09.v_l09_customer_metrics;
DROP VIEW IF EXISTS lecture09.v_l09_order_totals;

-- 9.03. Одна строка VIEW означает один заказ, включая все статусы
CREATE VIEW lecture09.v_l09_order_totals AS
SELECT o.order_id,o.customer_id,o.order_date,o.status,
       SUM(i.quantity*i.unit_price) AS total
FROM lecture08.orders o JOIN lecture08.order_items i USING(order_id)
GROUP BY o.order_id,o.customer_id,o.order_date,o.status;

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

-- 9.06. Одна строка означает клиента. Фильтр в ON сохраняет клиентов без продаж
CREATE VIEW lecture09.v_l09_customer_metrics AS
SELECT c.customer_id,c.full_name,COUNT(v.order_id) AS orders_count,
       COALESCE(SUM(v.total),0) AS revenue
FROM lecture08.customers c
LEFT JOIN lecture09.v_l09_order_totals v
  ON v.customer_id=c.customer_id AND v.status IN ('paid','completed')
GROUP BY c.customer_id,c.full_name;

-- 9.07. Все клиенты сохранены; клиенты без состоявшихся продаж имеют нулевые показатели
SELECT COUNT(*) AS rows_count,COUNT(DISTINCT customer_id) AS unique_customers,
       COUNT(*) FILTER (WHERE orders_count=0) AS zero_customers,
       SUM(revenue) AS revenue,
       (SELECT COUNT(*) FROM lecture08.customers) AS source_customers
FROM lecture09.v_l09_customer_metrics;

-- 9.08. Клиенты с нулём
SELECT * FROM lecture09.v_l09_customer_metrics
WHERE orders_count=0 ORDER BY customer_id;

-- 9.09. Дневная MV: одна строка означает дату заказа с состоявшимися продажами
CREATE MATERIALIZED VIEW lecture09.mv_l09_daily_sales AS
SELECT order_date::date AS day,COUNT(*) AS orders_count,
       SUM(total) AS revenue,AVG(total) AS avg_order
FROM lecture09.v_l09_order_totals
WHERE status IN ('paid','completed') GROUP BY 1;
CREATE UNIQUE INDEX ux_l09_daily_sales_day ON lecture09.mv_l09_daily_sales(day);

-- 9.10. Вторая MV: одна строка означает день и категорию; DISTINCT не считает позиции как заказы
CREATE MATERIALIZED VIEW lecture09.mv_l09_daily_category AS
SELECT o.order_date::date AS day,p.category,
       COUNT(DISTINCT o.order_id) AS orders_count,SUM(i.quantity) AS units,
       SUM(i.quantity*i.unit_price) AS revenue
FROM lecture08.orders o
JOIN lecture08.order_items i USING(order_id)
JOIN lecture08.products p USING(product_id)
WHERE o.status IN ('paid','completed') GROUP BY 1,2;
CREATE UNIQUE INDEX ux_l09_daily_category ON lecture09.mv_l09_daily_category(day,category);

-- 9.11. Обычное обновление и CONCURRENTLY; уникальные индексы покрывают все строки
REFRESH MATERIALIZED VIEW lecture09.mv_l09_daily_sales;
REFRESH MATERIALIZED VIEW CONCURRENTLY lecture09.mv_l09_daily_sales;
REFRESH MATERIALIZED VIEW CONCURRENTLY lecture09.mv_l09_daily_category;
ANALYZE lecture09.mv_l09_daily_sales;
ANALYZE lecture09.mv_l09_daily_category;

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

-- 9.15. План расчёта дневной выручки через VIEW
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_date::date AS day,SUM(total) AS revenue
FROM lecture09.v_l09_order_totals WHERE status IN ('paid','completed') GROUP BY 1;

-- 9.16. План чтения сохранённой дневной выручки — те же столбцы
EXPLAIN (ANALYZE, BUFFERS)
SELECT day,revenue FROM lecture09.mv_l09_daily_sales;

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

-- 9.19. Свежесть: тестовое изменение и оба REFRESH отменяются ROLLBACK
BEGIN;
SELECT 'before' AS stage,
 (SELECT SUM(total) FROM lecture09.v_l09_order_totals WHERE status IN ('paid','completed')) AS source_total,
 (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_sales) AS daily_total,
 (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_category) AS category_total,
 (SELECT COUNT(*) FROM lecture09.mv_l09_daily_sales) AS days,
 (SELECT MIN(day) FROM lecture09.mv_l09_daily_sales) AS first_day,
 (SELECT MAX(day) FROM lecture09.mv_l09_daily_sales) AS last_day;
UPDATE lecture08.order_items SET unit_price=unit_price+1
WHERE order_item_id=(
 SELECT MIN(i.order_item_id) FROM lecture08.order_items i
 JOIN lecture08.orders o USING(order_id) WHERE o.status IN ('paid','completed'));
SELECT 'stale' AS stage,
 (SELECT SUM(total) FROM lecture09.v_l09_order_totals WHERE status IN ('paid','completed')) AS source_total,
 (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_sales) AS daily_total,
 (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_category) AS category_total,
 (SELECT COUNT(*) FROM lecture09.mv_l09_daily_sales) AS days,
 (SELECT MIN(day) FROM lecture09.mv_l09_daily_sales) AS first_day,
 (SELECT MAX(day) FROM lecture09.mv_l09_daily_sales) AS last_day;
REFRESH MATERIALIZED VIEW lecture09.mv_l09_daily_sales;
REFRESH MATERIALIZED VIEW CONCURRENTLY lecture09.mv_l09_daily_category;
SELECT 'refreshed' AS stage,
 (SELECT SUM(total) FROM lecture09.v_l09_order_totals WHERE status IN ('paid','completed')) AS source_total,
 (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_sales) AS daily_total,
 (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_category) AS category_total,
 (SELECT COUNT(*) FROM lecture09.mv_l09_daily_sales) AS days,
 (SELECT MIN(day) FROM lecture09.mv_l09_daily_sales) AS first_day,
 (SELECT MAX(day) FROM lecture09.mv_l09_daily_sales) AS last_day;
ROLLBACK;
SELECT 'restored' AS stage,
 (SELECT SUM(total) FROM lecture09.v_l09_order_totals WHERE status IN ('paid','completed')) AS source_total,
 (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_sales) AS daily_total,
 (SELECT SUM(revenue) FROM lecture09.mv_l09_daily_category) AS category_total,
 (SELECT COUNT(*) FROM lecture09.mv_l09_daily_sales) AS days,
 (SELECT MIN(day) FROM lecture09.mv_l09_daily_sales) AS first_day,
 (SELECT MAX(day) FROM lecture09.mv_l09_daily_sales) AS last_day;
