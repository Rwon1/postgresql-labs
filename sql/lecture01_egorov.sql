-- Практическая работа 1. Егоров, группа 16М-нф26.
-- Первый запуск в пустой базе; для повторного показа — READ-файлы.
BEGIN;
CREATE SCHEMA lecture01;
SET search_path TO lecture01;
CREATE TABLE customers (
  customer_id integer PRIMARY KEY,
  full_name varchar(100), city varchar(50),
  registration_date date, total_spent numeric(10,2),
  is_active boolean
);
INSERT INTO customers
  (customer_id, full_name, city, registration_date, total_spent, is_active)
VALUES
  (1, 'Анна Смирнова', 'Москва', '2026-01-15', 18500.5, true),
  (2, 'Иван Петров', 'Казань', '2026-02-03', 7200, true),
  (3, 'Мария Волкова', 'Москва', '2026-02-20', 31200.9, true),
  (4, 'Олег Соколов', 'Самара', '2026-03-01', 4900, false),
  (5, 'Елена Орлова', 'Казань', '2026-03-12', 12800.4, true),
  (6, 'Павел Учебный', 'Самара', '2026-04-01', 10000, true),
  (7, 'Ирина Примерова', 'Москва', '2026-04-05', 0, false),
  (8, 'Сергей Тестов', 'Казань', '2026-05-10', 42000, true),
  (9, 'Нина Учебная', 'Самара', '2026-06-15', 1500, true),
  (10, 'Алексей Примеров', 'Москва', '2026-07-20', 22000, true)
;
-- Дополнительное задание: дата рождения.
ALTER TABLE customers ADD COLUMN birth_date date;
SELECT * FROM customers WHERE customer_id BETWEEN 1 AND 10;
UPDATE customers AS c
SET birth_date = v.birth_date
FROM (VALUES
  (1, DATE '2001-05-10'),
  (2, DATE '2002-08-15'),
  (3, DATE '1999-11-03'),
  (4, DATE '1995-04-22'),
  (5, DATE '2000-12-01'),
  (6, DATE '2003-06-18'),
  (7, DATE '2004-02-09'),
  (8, DATE '1998-10-30'),
  (9, DATE '2005-03-14'),
  (10, DATE '1997-07-25')
) AS v(id,birth_date)
WHERE c.customer_id = v.id AND c.customer_id BETWEEN 1 AND 10;
COMMIT;
SET search_path TO lecture01;

-- 1.01. Какие клиенты есть в таблице?
SELECT * FROM customers ORDER BY customer_id;

-- 1.02. Каковы имя, город и сумма каждого клиента?
SELECT full_name, city, total_spent FROM customers ORDER BY customer_id;

-- 1.03. Какие клиенты живут в Москве?
SELECT * FROM customers WHERE city = 'Москва' ORDER BY customer_id;

-- 1.04. Кто потратил больше 10000?
SELECT customer_id, full_name, total_spent FROM customers
WHERE total_spent > 10000 ORDER BY customer_id;

-- 1.05. Кто из клиентов активен?
SELECT customer_id, full_name FROM customers
WHERE is_active = true ORDER BY customer_id;

-- 1.06. Как выглядит список по убыванию суммы покупок?
SELECT customer_id, full_name, total_spent FROM customers
ORDER BY total_spent DESC, customer_id;

-- 1.07. Кто входит в TOP-3 по сумме покупок?
SELECT customer_id, full_name, total_spent FROM customers
ORDER BY total_spent DESC, customer_id LIMIT 3;

-- 1.08. Кто зарегистрировался начиная с апреля 2026 года?
SELECT customer_id, full_name, registration_date FROM customers
WHERE registration_date >= DATE '2026-04-01' ORDER BY registration_date, customer_id;

-- 1.09. Какие активные клиенты Казани потратили больше 10000?
SELECT customer_id, full_name, total_spent FROM customers
WHERE city = 'Казань' AND is_active = true AND total_spent > 10000
ORDER BY total_spent DESC, customer_id;

-- 1.10. Кто родился начиная с 2003 года?
SELECT customer_id, full_name, birth_date FROM customers
WHERE birth_date >= DATE '2003-01-01' ORDER BY birth_date, customer_id;

-- 1.11. Выполнены ли требования к наполнению?
SELECT COUNT(*) AS clients, COUNT(DISTINCT city) AS cities,
COUNT(birth_date) AS birth_dates, COUNT(*) FILTER (WHERE is_active) AS active
FROM customers;
