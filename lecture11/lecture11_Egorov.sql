-- Лекция 11. Егоров Дмитрий, 16М-нф26.
-- Клиент: psql. Запуск: psql -X -v ON_ERROR_STOP=1 -d <отдельная_учебная_БД> -f lecture11_Egorov.sql
-- Только учебные l11_* в public. Для исходного состояния нужна отдельная пустая база.
-- Повторный запуск безопасен для данных l11_*. Три экспериментальных индекса пересоздаются.
\set ON_ERROR_STOP on
\pset pager off
\pset format unaligned
\pset tuples_only on
SET client_encoding = 'UTF8';
SET search_path = public;
SET timezone = 'UTC';
SET statement_timeout = '60s';
SET lock_timeout = '10s';
SET application_name = 'lecture11_egorov';
\echo Подготовка и повторная загрузка seed
\ir lecture_11_seed.sql
CREATE TEMP TABLE seed_customers AS TABLE l11_customers;
CREATE TEMP TABLE seed_products AS TABLE l11_products;
CREATE TEMP TABLE seed_orders AS TABLE l11_orders;
CREATE TEMP TABLE seed_order_items AS TABLE l11_order_items;
\ir lecture_11_seed.sql
\echo @@BEGIN:seed_verification
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'l11_customers' AS table_name, (SELECT count(*) FROM l11_customers) AS row_count,
        (SELECT count(*) FROM (TABLE seed_customers EXCEPT ALL TABLE l11_customers) d) AS only_first,
        (SELECT count(*) FROM (TABLE l11_customers EXCEPT ALL TABLE seed_customers) d) AS only_second UNION ALL SELECT 'l11_products' AS table_name, (SELECT count(*) FROM l11_products) AS row_count,
        (SELECT count(*) FROM (TABLE seed_products EXCEPT ALL TABLE l11_products) d) AS only_first,
        (SELECT count(*) FROM (TABLE l11_products EXCEPT ALL TABLE seed_products) d) AS only_second UNION ALL SELECT 'l11_orders' AS table_name, (SELECT count(*) FROM l11_orders) AS row_count,
        (SELECT count(*) FROM (TABLE seed_orders EXCEPT ALL TABLE l11_orders) d) AS only_first,
        (SELECT count(*) FROM (TABLE l11_orders EXCEPT ALL TABLE seed_orders) d) AS only_second UNION ALL SELECT 'l11_order_items' AS table_name, (SELECT count(*) FROM l11_order_items) AS row_count,
        (SELECT count(*) FROM (TABLE seed_order_items EXCEPT ALL TABLE l11_order_items) d) AS only_first,
        (SELECT count(*) FROM (TABLE l11_order_items EXCEPT ALL TABLE seed_order_items) d) AS only_second) q;
\echo @@END:seed_verification
-- Удаляем только индексы этого эксперимента; PK/FK остаются.
DROP INDEX IF EXISTS l11_orders_customer_idx;
DROP INDEX IF EXISTS l11_orders_page_idx;
DROP INDEX IF EXISTS l11_orders_failed_idx;
-- После второй загрузки убираем мёртвые версии до всех измерений.
VACUUM (ANALYZE) l11_customers;
VACUUM (ANALYZE) l11_products;
VACUUM (ANALYZE) l11_orders;
VACUUM (ANALYZE) l11_order_items;
\echo @@BEGIN:environment
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT version() AS server_version,current_database() AS database_name,
    current_setting('server_version_num') AS server_version_num,current_setting('TimeZone') AS timezone,
    current_setting('work_mem') AS work_mem,current_setting('shared_buffers') AS shared_buffers,
    current_setting('random_page_cost') AS random_page_cost,current_setting('seq_page_cost') AS seq_page_cost,
    current_setting('max_parallel_workers_per_gather') AS max_parallel_workers_per_gather,
    current_setting('jit') AS jit,current_setting('enable_seqscan') AS enable_seqscan,
    current_setting('enable_indexscan') AS enable_indexscan,current_setting('enable_bitmapscan') AS enable_bitmapscan,
    current_timestamp AS measured_at) q;
\echo @@END:environment
\echo @@BEGIN:status_distribution
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT status,count(*) AS rows,round(100.0*count(*)/(SELECT count(*) FROM l11_orders),2) AS percent FROM l11_orders GROUP BY status ORDER BY status) q;
\echo @@END:status_distribution
\echo Измерение customer: до и после
CREATE TEMP TABLE before_customer AS SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@BEGIN:csv:customer:before
COPY (SELECT * FROM (SELECT * FROM l11_orders WHERE customer_id = 110001) result ORDER BY order_id) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:customer:before
\echo Прогрев customer/before: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@BEGIN:plan:customer:before:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@END:plan:customer:before:1
\echo @@BEGIN:plan:customer:before:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@END:plan:customer:before:2
\echo @@BEGIN:plan:customer:before:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@END:plan:customer:before:3
CREATE INDEX l11_orders_customer_idx ON l11_orders(customer_id);
\echo Прогрев customer/after: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@BEGIN:plan:customer:after:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@END:plan:customer:after:1
\echo @@BEGIN:plan:customer:after:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@END:plan:customer:after:2
\echo @@BEGIN:plan:customer:after:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE customer_id = 110001;
\echo @@END:plan:customer:after:3
\echo @@BEGIN:csv:customer:after
COPY (SELECT * FROM (SELECT * FROM l11_orders WHERE customer_id = 110001) result ORDER BY order_id) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:customer:after
\echo @@BEGIN:equality:customer
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'customer' AS query,
    (SELECT count(*) FROM (TABLE before_customer EXCEPT ALL (SELECT * FROM l11_orders WHERE customer_id = 110001)) d) AS only_before,
    (SELECT count(*) FROM ((SELECT * FROM l11_orders WHERE customer_id = 110001) EXCEPT ALL TABLE before_customer) d) AS only_after) q;
\echo @@END:equality:customer
\echo @@BEGIN:index:customer
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'l11_orders_customer_idx' AS index_name,pg_relation_size('l11_orders_customer_idx') AS bytes) q;
\echo @@END:index:customer
DROP INDEX l11_orders_customer_idx; -- Следующий опыт начинается без этого индекса.
\echo Измерение last20: до и после
CREATE TEMP TABLE before_last20 AS SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@BEGIN:csv:last20:before
COPY (SELECT * FROM (SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20) result ORDER BY created_at DESC,order_id DESC) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:last20:before
\echo Прогрев last20/before: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@BEGIN:plan:last20:before:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@END:plan:last20:before:1
\echo @@BEGIN:plan:last20:before:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@END:plan:last20:before:2
\echo @@BEGIN:plan:last20:before:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@END:plan:last20:before:3
CREATE INDEX l11_orders_page_idx ON l11_orders(created_at DESC,order_id DESC);
\echo Прогрев last20/after: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@BEGIN:plan:last20:after:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@END:plan:last20:after:1
\echo @@BEGIN:plan:last20:after:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@END:plan:last20:after:2
\echo @@BEGIN:plan:last20:after:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20;
\echo @@END:plan:last20:after:3
\echo @@BEGIN:csv:last20:after
COPY (SELECT * FROM (SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20) result ORDER BY created_at DESC,order_id DESC) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:last20:after
\echo @@BEGIN:equality:last20
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'last20' AS query,
    (SELECT count(*) FROM (TABLE before_last20 EXCEPT ALL (SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20)) d) AS only_before,
    (SELECT count(*) FROM ((SELECT order_id,created_at,total_amount FROM l11_orders ORDER BY created_at DESC,order_id DESC LIMIT 20) EXCEPT ALL TABLE before_last20) d) AS only_after) q;
\echo @@END:equality:last20
\echo @@BEGIN:index:last20
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'l11_orders_page_idx' AS index_name,pg_relation_size('l11_orders_page_idx') AS bytes) q;
\echo @@END:index:last20
DROP INDEX l11_orders_page_idx; -- Следующий опыт начинается без этого индекса.
\echo Измерение revenue: до и после
CREATE TEMP TABLE before_revenue AS SELECT o.customer_id,SUM(i.quantity*i.unit_price) AS revenue FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id GROUP BY o.customer_id;
\echo @@BEGIN:csv:revenue:before
COPY (SELECT * FROM (SELECT o.customer_id,SUM(i.quantity*i.unit_price) AS revenue FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id GROUP BY o.customer_id) result ORDER BY customer_id) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:revenue:before
\echo Прогрев revenue/before: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT o.customer_id,SUM(i.quantity*i.unit_price) AS revenue FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id GROUP BY o.customer_id;
\echo @@BEGIN:plan:revenue:before:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT o.customer_id,SUM(i.quantity*i.unit_price) AS revenue FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id GROUP BY o.customer_id;
\echo @@END:plan:revenue:before:1
\echo @@BEGIN:plan:revenue:before:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT o.customer_id,SUM(i.quantity*i.unit_price) AS revenue FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id GROUP BY o.customer_id;
\echo @@END:plan:revenue:before:2
\echo @@BEGIN:plan:revenue:before:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT o.customer_id,SUM(i.quantity*i.unit_price) AS revenue FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id GROUP BY o.customer_id;
\echo @@END:plan:revenue:before:3
-- Единственное изменение: предварительно суммируем позиции по order_id.
\echo Прогрев revenue/after: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT o.customer_id,SUM(s.order_revenue) AS revenue FROM l11_orders o JOIN (SELECT order_id,SUM(quantity*unit_price) AS order_revenue FROM l11_order_items GROUP BY order_id) s ON s.order_id=o.order_id GROUP BY o.customer_id;
\echo @@BEGIN:plan:revenue:after:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT o.customer_id,SUM(s.order_revenue) AS revenue FROM l11_orders o JOIN (SELECT order_id,SUM(quantity*unit_price) AS order_revenue FROM l11_order_items GROUP BY order_id) s ON s.order_id=o.order_id GROUP BY o.customer_id;
\echo @@END:plan:revenue:after:1
\echo @@BEGIN:plan:revenue:after:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT o.customer_id,SUM(s.order_revenue) AS revenue FROM l11_orders o JOIN (SELECT order_id,SUM(quantity*unit_price) AS order_revenue FROM l11_order_items GROUP BY order_id) s ON s.order_id=o.order_id GROUP BY o.customer_id;
\echo @@END:plan:revenue:after:2
\echo @@BEGIN:plan:revenue:after:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT o.customer_id,SUM(s.order_revenue) AS revenue FROM l11_orders o JOIN (SELECT order_id,SUM(quantity*unit_price) AS order_revenue FROM l11_order_items GROUP BY order_id) s ON s.order_id=o.order_id GROUP BY o.customer_id;
\echo @@END:plan:revenue:after:3
\echo @@BEGIN:csv:revenue:after
COPY (SELECT * FROM (SELECT o.customer_id,SUM(s.order_revenue) AS revenue FROM l11_orders o JOIN (SELECT order_id,SUM(quantity*unit_price) AS order_revenue FROM l11_order_items GROUP BY order_id) s ON s.order_id=o.order_id GROUP BY o.customer_id) result ORDER BY customer_id) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:revenue:after
\echo @@BEGIN:equality:revenue
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'revenue' AS query,
    (SELECT count(*) FROM (TABLE before_revenue EXCEPT ALL (SELECT o.customer_id,SUM(s.order_revenue) AS revenue FROM l11_orders o JOIN (SELECT order_id,SUM(quantity*unit_price) AS order_revenue FROM l11_order_items GROUP BY order_id) s ON s.order_id=o.order_id GROUP BY o.customer_id)) d) AS only_before,
    (SELECT count(*) FROM ((SELECT o.customer_id,SUM(s.order_revenue) AS revenue FROM l11_orders o JOIN (SELECT order_id,SUM(quantity*unit_price) AS order_revenue FROM l11_order_items GROUP BY order_id) s ON s.order_id=o.order_id GROUP BY o.customer_id) EXCEPT ALL TABLE before_revenue) d) AS only_after) q;
\echo @@END:equality:revenue
CREATE TEMP TABLE before_failed AS SELECT * FROM l11_orders WHERE status='failed';
\echo @@BEGIN:csv:failed:before
COPY (SELECT * FROM (SELECT * FROM l11_orders WHERE status='failed') result ORDER BY order_id) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:failed:before
\echo Прогрев failed/before: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='failed';
\echo @@BEGIN:plan:failed:before:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='failed';
\echo @@END:plan:failed:before:1
\echo @@BEGIN:plan:failed:before:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='failed';
\echo @@END:plan:failed:before:2
\echo @@BEGIN:plan:failed:before:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='failed';
\echo @@END:plan:failed:before:3
CREATE TEMP TABLE before_paid AS SELECT * FROM l11_orders WHERE status='paid';
\echo @@BEGIN:csv:paid:before
COPY (SELECT * FROM (SELECT * FROM l11_orders WHERE status='paid') result ORDER BY order_id) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:paid:before
\echo Прогрев paid/before: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='paid';
\echo @@BEGIN:plan:paid:before:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='paid';
\echo @@END:plan:paid:before:1
\echo @@BEGIN:plan:paid:before:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='paid';
\echo @@END:plan:paid:before:2
\echo @@BEGIN:plan:paid:before:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='paid';
\echo @@END:plan:paid:before:3
CREATE INDEX l11_orders_failed_idx ON l11_orders(created_at) WHERE status='failed';
ANALYZE l11_orders;
\echo Прогрев failed/after: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='failed';
\echo @@BEGIN:plan:failed:after:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='failed';
\echo @@END:plan:failed:after:1
\echo @@BEGIN:plan:failed:after:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='failed';
\echo @@END:plan:failed:after:2
\echo @@BEGIN:plan:failed:after:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='failed';
\echo @@END:plan:failed:after:3
\echo @@BEGIN:csv:failed:after
COPY (SELECT * FROM (SELECT * FROM l11_orders WHERE status='failed') result ORDER BY order_id) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:failed:after
\echo @@BEGIN:equality:failed
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'failed' AS query,
    (SELECT count(*) FROM (TABLE before_failed EXCEPT ALL (SELECT * FROM l11_orders WHERE status='failed')) d) AS only_before,
    (SELECT count(*) FROM ((SELECT * FROM l11_orders WHERE status='failed') EXCEPT ALL TABLE before_failed) d) AS only_after) q;
\echo @@END:equality:failed
\echo Прогрев paid/after: отдельный запуск, не входит в три измерения
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='paid';
\echo @@BEGIN:plan:paid:after:1
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='paid';
\echo @@END:plan:paid:after:1
\echo @@BEGIN:plan:paid:after:2
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='paid';
\echo @@END:plan:paid:after:2
\echo @@BEGIN:plan:paid:after:3
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT JSON) SELECT * FROM l11_orders WHERE status='paid';
\echo @@END:plan:paid:after:3
\echo @@BEGIN:csv:paid:after
COPY (SELECT * FROM (SELECT * FROM l11_orders WHERE status='paid') result ORDER BY order_id) TO STDOUT WITH (FORMAT CSV, HEADER TRUE);
\echo @@END:csv:paid:after
\echo @@BEGIN:equality:paid
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'paid' AS query,
    (SELECT count(*) FROM (TABLE before_paid EXCEPT ALL (SELECT * FROM l11_orders WHERE status='paid')) d) AS only_before,
    (SELECT count(*) FROM ((SELECT * FROM l11_orders WHERE status='paid') EXCEPT ALL TABLE before_paid) d) AS only_after) q;
\echo @@END:equality:paid
\echo @@BEGIN:index:failed
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT 'l11_orders_failed_idx' AS index_name,pg_relation_size('l11_orders_failed_idx') AS bytes) q;
\echo @@END:index:failed
\echo @@BEGIN:double_count
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT
    (SELECT count(*) FROM l11_order_items) AS item_rows,
    (SELECT count(*) FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id) AS join_rows,
    (SELECT count(DISTINCT i.item_id) FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id) AS distinct_join_items,
    (SELECT sum(quantity*unit_price) FROM l11_order_items) AS item_total,
    (SELECT sum(revenue) FROM before_revenue) AS grouped_total,
    (SELECT sum(total_amount) FROM l11_orders) AS order_total,
    (SELECT sum(o.total_amount) FROM l11_orders o JOIN l11_order_items i ON i.order_id=o.order_id) AS incorrect_sum_order_total_after_join,
    (SELECT count(*) FROM l11_orders o WHERE o.total_amount<>(SELECT sum(i.quantity*i.unit_price) FROM l11_order_items i WHERE i.order_id=o.order_id)) AS mismatched_orders) q;
\echo @@END:double_count
\echo @@BEGIN:final_indexes
SELECT coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) FROM (SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='public' AND tablename LIKE 'l11_%' ORDER BY indexname) q;
\echo @@END:final_indexes
\echo Лекция 11 завершена
