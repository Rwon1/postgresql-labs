-- Практическая работа 7. Егоров, 16М-нф26.
-- Исходные данные: lecture_07_seed.sql.
CREATE SCHEMA IF NOT EXISTS lecture07;
SET search_path TO lecture07;


CREATE TABLE IF NOT EXISTS customers (
 customer_id BIGINT PRIMARY KEY,
 full_name VARCHAR(150) NOT NULL,
 city VARCHAR(80),
 email VARCHAR(180),
 is_active BOOLEAN NOT NULL DEFAULT true,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS products (
 product_id BIGINT PRIMARY KEY,
 sku VARCHAR(40) NOT NULL UNIQUE,
 product_name VARCHAR(150) NOT NULL,
 category VARCHAR(80),
 price NUMERIC(12,2) NOT NULL CHECK(price>=0),
 stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity>=0),
 is_active BOOLEAN NOT NULL DEFAULT true,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS orders (
 order_id BIGINT PRIMARY KEY,
 customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
 order_date TIMESTAMP NOT NULL,
 status VARCHAR(20) NOT NULL CHECK(status IN ('new','paid','shipped','cancelled'))
);
CREATE TABLE IF NOT EXISTS order_items (
 order_item_id BIGINT PRIMARY KEY,
 order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
 product_id BIGINT NOT NULL REFERENCES products(product_id),
 quantity INTEGER NOT NULL CHECK(quantity>0),
 unit_price NUMERIC(12,2) NOT NULL CHECK(unit_price>=0)
);

WITH src AS (
 SELECT 770000+g customer_id,
        (ARRAY['Алексей','Мария','Иван','Анна','Дмитрий','Елена','Сергей','Ольга','Николай','Дарья'])[((g-1)%10)+1] || ' ' ||
        (ARRAY['Смирнов','Иванова','Кузнецов','Попова','Соколов','Лебедева','Козлов','Новикова','Морозов','Волкова'])[((g*7-1)%10)+1] || ' #' || g full_name,
        (ARRAY['Москва','Санкт-Петербург','Казань','Самара','Тула','Пермь','Омск','Уфа','Воронеж','Екатеринбург','Валенсия','Мадрид'])[((g*5-1)%12)+1] city,
        'l07_user_'||g||'@example.edu' email,
        (g%13<>0) is_active,
        TIMESTAMP '2024-01-01' + ((g*17)%700)*INTERVAL '1 day' created_at
 FROM generate_series(1,180) gs(g)
)
INSERT INTO customers SELECT * FROM src s
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id=s.customer_id);

WITH src AS (
 SELECT 780000+g product_id,
        'L07-'||lpad(g::text,4,'0') sku,
        (ARRAY['Ноутбук','Монитор','Клавиатура','Мышь','SSD','Роутер','Наушники','Камера','Док-станция','Микрофон'])[((g-1)%10)+1]||' '||
        (ARRAY['Basic','Pro','Mini','Max','Office','Gaming'])[((g*5-1)%6)+1]||' #'||g product_name,
        (ARRAY['Ноутбуки','Мониторы','Аксессуары','Накопители','Сеть','Аудио','Периферия','Видео'])[((g*3-1)%8)+1] category,
        (500 + ((g*37)%80)*250)::numeric(12,2) price,
        CASE WHEN g%17=0 THEN 0 ELSE (g*23)%160 END stock_quantity,
        (g%19<>0) is_active,
        TIMESTAMP '2024-02-01' + ((g*13)%650)*INTERVAL '1 day' created_at
 FROM generate_series(1,240) gs(g)
)
INSERT INTO products SELECT * FROM src s
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.product_id=s.product_id)
  AND NOT EXISTS (SELECT 1 FROM products p WHERE p.sku=s.sku);

WITH src AS (
 SELECT 790000+g order_id,
        770000 + 1 + ((g*37)%180) customer_id,
        TIMESTAMP '2025-01-01 09:00:00'
          + ((g*11)%730)*INTERVAL '1 day'
          + ((g%10)*INTERVAL '1 hour') order_date,
        (ARRAY['paid','shipped','paid','paid','new','shipped','cancelled'])[((g*5-1)%7)+1] status
 FROM generate_series(1,1200) gs(g)
)
INSERT INTO orders SELECT * FROM src s
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.order_id=s.order_id);

WITH src AS (
 SELECT 800000 + ((g-1)*4+k) order_item_id,
        790000+g order_id,
        780000 + 1 + (((g*17+k*29)-1)%240) product_id,
        1 + ((g+k)%5) quantity,
        (500 + ((((g*17+k*29)*37)%80)*250) + ((g+k)%4)*50)::numeric(12,2) unit_price
 FROM generate_series(1,1200) gs(g)
 CROSS JOIN generate_series(1,4) ks(k)
)
INSERT INTO order_items SELECT * FROM src s
WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.order_item_id=s.order_item_id);

SELECT 'customers' table_name, COUNT(*) rows_count FROM customers WHERE customer_id BETWEEN 770001 AND 770180
UNION ALL SELECT 'products',COUNT(*) FROM products WHERE product_id BETWEEN 780001 AND 780240
UNION ALL SELECT 'orders',COUNT(*) FROM orders WHERE order_id BETWEEN 790001 AND 791200
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items WHERE order_item_id BETWEEN 800001 AND 804800
ORDER BY table_name;

SELECT category, COUNT(*) products, COUNT(DISTINCT price) distinct_prices
FROM products WHERE product_id BETWEEN 780001 AND 780240 GROUP BY category ORDER BY category;

SELECT DATE_TRUNC('month',order_date) AS month, COUNT(*) orders_count
FROM orders WHERE order_id BETWEEN 790001 AND 791200 GROUP BY 1 ORDER BY 1;

-- ROW_NUMBER нумерует строки; RANK сохраняет ничьи с пропусками мест,
-- DENSE_RANK — без пропусков. product_id не включён в окно RANK, чтобы не убрать ничьи.
-- Временные отчёты учитывают paid + shipped; статистика заказов — все статусы.
-- 7.01. Количество строк в четырёх таблицах
SELECT 'customers' AS table_name,COUNT(*) AS rows_count FROM customers
UNION ALL SELECT 'products',COUNT(*) FROM products
UNION ALL SELECT 'orders',COUNT(*) FROM orders
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items;

-- 7.02. Одна строка результата означает заказ; окна сохраняют детализацию
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,o.status,
        COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM orders o LEFT JOIN order_items i USING(order_id)
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
 FROM orders o LEFT JOIN order_items i USING(order_id)
 GROUP BY o.order_id,o.customer_id,o.order_date,o.status
)
SELECT COUNT(*) AS orders,COUNT(DISTINCT order_id) AS unique_orders,SUM(total) AS total,
       (SELECT SUM(quantity*unit_price) FROM order_items) AS source_total
FROM order_totals;

-- 7.04. Сверка одной секции окна: клиент 770001
WITH order_totals AS (
 SELECT o.order_id,o.customer_id,o.order_date,o.status,
        COALESCE(SUM(i.quantity*i.unit_price),0) AS total
 FROM orders o LEFT JOIN order_items i USING(order_id)
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
 FROM products
)
SELECT * FROM ranking ORDER BY category,price DESC,product_id;

-- 7.06. Одна строка результата означает товар в top-3; ROW_NUMBER: ровно три товара
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM products
)
SELECT * FROM ranking WHERE rn<=3 ORDER BY category,price DESC,product_id;

-- 7.07. Одна строка результата означает товар в top-3; RANK: первые три места с ничьими и пропусками
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM products
)
SELECT * FROM ranking WHERE rnk<=3 ORDER BY category,price DESC,product_id;

-- 7.08. Одна строка результата означает товар в top-3; DENSE_RANK: три уровня цены с ничьими
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM products
)
SELECT * FROM ranking WHERE drnk<=3 ORDER BY category,price DESC,product_id;

-- 7.09. Контроль размеров top-3 и количества уровней цены
WITH ranking AS (
 SELECT product_id,product_name,category,price,
 ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC,product_id) AS rn,
 RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk,
 DENSE_RANK() OVER (PARTITION BY category ORDER BY price DESC) AS drnk
 FROM products
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
 FROM orders o JOIN order_items i USING(order_id)
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
 FROM orders o JOIN order_items i USING(order_id)
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
       (SELECT SUM(i.quantity*i.unit_price) FROM orders o JOIN order_items i USING(order_id)
        WHERE o.status IN ('paid','shipped')) AS source_sum;

-- 7.12. Сверка скользящего среднего третьего месяца с первыми тремя строками
WITH monthly AS (
 SELECT DATE_TRUNC('month',o.order_date)::date AS month,
        SUM(i.quantity*i.unit_price) AS revenue
 FROM orders o JOIN order_items i USING(order_id)
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
 FROM orders o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
 WHERE o.status IN ('paid','shipped') GROUP BY 1,2
), grid AS (
 SELECT g::date AS month,c.category
 FROM generate_series((SELECT MIN(month) FROM monthly_category),
      (SELECT MAX(month) FROM monthly_category),INTERVAL '1 month') g
 CROSS JOIN (SELECT DISTINCT category FROM products) c
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
 FROM orders o JOIN order_items i USING(order_id) JOIN products p USING(product_id)
 WHERE o.status IN ('paid','shipped') GROUP BY 1,2
), grid AS (
 SELECT g::date AS month,c.category
 FROM generate_series((SELECT MIN(month) FROM monthly_category),
      (SELECT MAX(month) FROM monthly_category),INTERVAL '1 month') g
 CROSS JOIN (SELECT DISTINCT category FROM products) c
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
