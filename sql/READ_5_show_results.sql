-- Работа 5. Запросы к готовым таблицам.

-- 5.01. Число строк до и после соединения
SELECT (SELECT COUNT(*) FROM lecture05.customers) AS customers,
       (SELECT COUNT(*) FROM lecture05.products) AS products,
       (SELECT COUNT(*) FROM lecture05.orders) AS orders,
       (SELECT COUNT(*) FROM lecture05.order_items) AS items,
       (SELECT COUNT(*) FROM lecture05.orders o JOIN lecture05.customers c USING(customer_id)) AS joined_orders,
       (SELECT COUNT(*) FROM lecture05.orders o JOIN lecture05.order_items i USING(order_id)
        JOIN lecture05.customers c USING(customer_id) JOIN lecture05.products p USING(product_id)) AS joined_items;

-- 5.02. Заказы и имена клиентов — INNER JOIN
SELECT o.order_id, o.order_date, c.full_name, o.status
FROM lecture05.orders o JOIN lecture05.customers c ON c.customer_id=o.customer_id
ORDER BY o.order_id;

-- 5.03. Клиент, заказ и товар — одна строка на позицию
SELECT c.full_name, o.order_id, p.product_name, i.quantity, i.unit_price,
       i.quantity*i.unit_price AS line_total
FROM lecture05.customers c JOIN lecture05.orders o ON o.customer_id=c.customer_id
JOIN lecture05.order_items i ON i.order_id=o.order_id
JOIN lecture05.products p ON p.product_id=i.product_id
ORDER BY o.order_id, i.order_item_id;

-- 5.04. Все клиенты и число заказов — LEFT JOIN
SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS orders_count
FROM lecture05.customers c LEFT JOIN lecture05.orders o ON o.customer_id=c.customer_id
GROUP BY c.customer_id, c.full_name ORDER BY c.customer_id;

-- 5.05. Клиенты без заказов
SELECT c.customer_id, c.full_name FROM lecture05.customers c
LEFT JOIN lecture05.orders o ON o.customer_id=c.customer_id
WHERE o.order_id IS NULL ORDER BY c.customer_id;

-- 5.06. Товары без продаж
SELECT p.product_id, p.product_name FROM lecture05.products p
LEFT JOIN lecture05.order_items i ON i.product_id=p.product_id
WHERE i.order_item_id IS NULL ORDER BY p.product_id;

-- 5.07. Фильтр в ON сохраняет клиентов без paid-заказов
SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS paid_orders
FROM lecture05.customers c LEFT JOIN lecture05.orders o
  ON o.customer_id=c.customer_id AND o.status='paid'
GROUP BY c.customer_id,c.full_name ORDER BY c.customer_id;

-- 5.08. Фильтр в WHERE исключает клиентов без paid-заказов
SELECT c.customer_id,c.full_name,COUNT(o.order_id) AS paid_orders
FROM lecture05.customers c LEFT JOIN lecture05.orders o ON o.customer_id=c.customer_id
WHERE o.status='paid'
GROUP BY c.customer_id,c.full_name ORDER BY c.customer_id;

-- 5.09. Сумма каждого заказа, включая все статусы
SELECT o.order_id,o.status,COALESCE(SUM(i.quantity*i.unit_price),0) AS order_total
FROM lecture05.orders o LEFT JOIN lecture05.order_items i ON i.order_id=o.order_id
GROUP BY o.order_id,o.status ORDER BY o.order_id;

-- 5.10. Количество заказов и сумма покупок каждого клиента
SELECT c.customer_id,c.full_name,COUNT(DISTINCT o.order_id) AS orders_count,
       COALESCE(SUM(i.quantity*i.unit_price),0) AS revenue
FROM lecture05.customers c LEFT JOIN lecture05.orders o
  ON o.customer_id=c.customer_id AND o.status IN ('paid','shipped')
LEFT JOIN lecture05.order_items i ON i.order_id=o.order_id
GROUP BY c.customer_id,c.full_name ORDER BY revenue DESC,c.customer_id;

-- 5.11. Проданные единицы и выручка по товарам
SELECT p.product_id,p.product_name,SUM(i.quantity) AS units,
       SUM(i.quantity*i.unit_price) AS revenue
FROM lecture05.products p JOIN lecture05.order_items i ON i.product_id=p.product_id
JOIN lecture05.orders o ON o.order_id=i.order_id
WHERE o.status IN ('paid','shipped')
GROUP BY p.product_id,p.product_name ORDER BY revenue DESC,p.product_id;

-- 5.12. Выручка по категориям: HAVING от 1 млн
SELECT p.category,SUM(i.quantity*i.unit_price) AS revenue
FROM lecture05.orders o JOIN lecture05.order_items i ON i.order_id=o.order_id
JOIN lecture05.products p ON p.product_id=i.product_id
WHERE o.status IN ('paid','shipped')
GROUP BY p.category HAVING SUM(i.quantity*i.unit_price)>=1000000
ORDER BY revenue DESC,p.category;

-- 5.13. Продажи по городам за первое полугодие 2026
SELECT c.city,COUNT(DISTINCT o.order_id) AS orders_count,
       SUM(i.quantity*i.unit_price) AS revenue
FROM lecture05.customers c JOIN lecture05.orders o ON o.customer_id=c.customer_id
JOIN lecture05.order_items i ON i.order_id=o.order_id
WHERE o.status IN ('paid','shipped')
  AND o.order_date>=TIMESTAMP '2026-01-01'
  AND o.order_date<TIMESTAMP '2026-07-01'
GROUP BY c.city ORDER BY revenue DESC,c.city;

-- 5.14. Полный каталог, включая нулевые продажи
SELECT p.product_id,p.product_name,
       COALESCE(SUM(i.quantity) FILTER (WHERE o.order_id IS NOT NULL),0) AS units,
       COALESCE(SUM(i.quantity*i.unit_price) FILTER (WHERE o.order_id IS NOT NULL),0) AS revenue
FROM lecture05.products p LEFT JOIN lecture05.order_items i ON i.product_id=p.product_id
LEFT JOIN lecture05.orders o ON o.order_id=i.order_id AND o.status IN ('paid','shipped')
GROUP BY p.product_id,p.product_name ORDER BY p.product_id;

-- 5.15. Детализация суммы заказа 552001
SELECT order_item_id,quantity,unit_price,quantity*unit_price AS line_total
FROM lecture05.order_items WHERE order_id=552001 ORDER BY order_item_id;

-- 5.16. Контроль суммы заказа 552001
SELECT SUM(quantity*unit_price) AS detail_total FROM lecture05.order_items WHERE order_id=552001;

-- 5.17. Детализация выручки категории Ноутбуки
SELECT o.order_id,i.order_item_id,p.product_name,i.quantity,i.unit_price,
       i.quantity*i.unit_price AS line_total
FROM lecture05.orders o JOIN lecture05.order_items i USING(order_id) JOIN lecture05.products p USING(product_id)
WHERE o.status IN ('paid','shipped') AND p.category='Ноутбуки'
ORDER BY o.order_id,i.order_item_id;

-- 5.18. Контроль выручки категории Ноутбуки
SELECT SUM(i.quantity*i.unit_price) AS detail_total
FROM lecture05.order_items i JOIN lecture05.orders o USING(order_id) JOIN lecture05.products p USING(product_id)
WHERE o.status IN ('paid','shipped') AND p.category='Ноутбуки';

-- 5.19. Контроль позиций, единиц и суммы до и после JOIN
WITH source AS (
SELECT COUNT(*) AS source_rows,SUM(quantity) AS source_units,
       SUM(quantity*unit_price) AS source_total FROM lecture05.order_items
), joined AS (
SELECT COUNT(*) AS joined_rows,SUM(i.quantity) AS joined_units,
       SUM(i.quantity*i.unit_price) AS joined_total
FROM lecture05.order_items i JOIN lecture05.orders o USING(order_id)
JOIN lecture05.customers c USING(customer_id) JOIN lecture05.products p USING(product_id)
)
SELECT * FROM source CROSS JOIN joined;
