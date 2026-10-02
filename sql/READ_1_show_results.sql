-- Работа 1. Егоров, группа 16М-нф26.

-- 1.01. Какие клиенты есть в таблице?
SELECT * FROM lecture01.customers ORDER BY customer_id;

-- 1.02. Каковы имя, город и сумма каждого клиента?
SELECT full_name, city, total_spent FROM lecture01.customers ORDER BY customer_id;

-- 1.03. Какие клиенты живут в Москве?
SELECT * FROM lecture01.customers WHERE city = 'Москва' ORDER BY customer_id;

-- 1.04. Кто потратил больше 10000?
SELECT customer_id, full_name, total_spent FROM lecture01.customers
WHERE total_spent > 10000 ORDER BY customer_id;

-- 1.05. Кто из клиентов активен?
SELECT customer_id, full_name FROM lecture01.customers
WHERE is_active = true ORDER BY customer_id;

-- 1.06. Как выглядит список по убыванию суммы покупок?
SELECT customer_id, full_name, total_spent FROM lecture01.customers
ORDER BY total_spent DESC, customer_id;

-- 1.07. Кто входит в TOP-3 по сумме покупок?
SELECT customer_id, full_name, total_spent FROM lecture01.customers
ORDER BY total_spent DESC, customer_id LIMIT 3;

-- 1.08. Кто зарегистрировался начиная с апреля 2026 года?
SELECT customer_id, full_name, registration_date FROM lecture01.customers
WHERE registration_date >= DATE '2026-04-01' ORDER BY registration_date, customer_id;

-- 1.09. Какие активные клиенты Казани потратили больше 10000?
SELECT customer_id, full_name, total_spent FROM lecture01.customers
WHERE city = 'Казань' AND is_active = true AND total_spent > 10000
ORDER BY total_spent DESC, customer_id;

-- 1.10. Кто родился начиная с 2003 года?
SELECT customer_id, full_name, birth_date FROM lecture01.customers
WHERE birth_date >= DATE '2003-01-01' ORDER BY birth_date, customer_id;

-- 1.11. Выполнены ли требования к наполнению?
SELECT COUNT(*) AS clients, COUNT(DISTINCT city) AS cities,
COUNT(birth_date) AS birth_dates, COUNT(*) FILTER (WHERE is_active) AS active
FROM lecture01.customers;
