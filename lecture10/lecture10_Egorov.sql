-- Егоров Дмитрий, 16М-нф26. PostgreSQL 16.
-- Последовательно выполняйте пронумерованные шаги в трёх подключениях A/B/M к одной новой учебной базе.
-- Сначала выполните lecture_10_seed.sql и setup_l10_tasks.sql. Этот сценарий целиком одной кнопкой не запускать.
-- Для фонового запроса переключитесь в другое окно, пока прежнее ожидает.
-- Ошибки P0001, 55P03 и 40P01 намеренные; затем обязательно ROLLBACK в указанном сеансе.
-- При любой неожиданной ошибке: ROLLBACK в A и B; эксперимент прекратить.

-- Шаг 1. СЕАНС A
SELECT pg_backend_pid() AS session_pid;

-- Шаг 2. СЕАНС B
SELECT pg_backend_pid() AS session_pid;

-- Шаг 3. СЕАНС M
SELECT pg_backend_pid() AS session_pid;

-- Шаг 4. СЕАНС A
SELECT version(), current_database(), current_schema(), current_user;

-- Шаг 5. СЕАНС A
SET search_path = public; SET statement_timeout = '3min'; SET lock_timeout = '2min'; SET idle_in_transaction_session_timeout = '10min';

-- Шаг 6. СЕАНС B
SET search_path = public; SET statement_timeout = '3min'; SET lock_timeout = '2min'; SET idle_in_transaction_session_timeout = '10min';

-- Шаг 7. СЕАНС M
SET search_path = public; SET statement_timeout = '3min'; SET lock_timeout = '2min'; SET idle_in_transaction_session_timeout = '10min';

-- Шаг 8. СЕАНС A
SELECT COUNT(*) AS accounts_count FROM public.l10_accounts;

-- Шаг 9. СЕАНС A
SELECT COUNT(*) AS tasks_count FROM public.l10_tasks;

-- Шаг 10. СЕАНС A
SELECT 'accounts' AS table_name, COUNT(*) FROM public.l10_accounts UNION ALL SELECT 'tasks', COUNT(*) FROM public.l10_tasks UNION ALL SELECT 'transfers', COUNT(*) FROM public.l10_transfers UNION ALL SELECT 'audit', COUNT(*) FROM public.l10_audit;

-- Шаг 11. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 12. СЕАНС A
SELECT SUM(balance) AS total_balance FROM public.l10_accounts;

-- Шаг 13. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 14. СЕАНС A
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 15. СЕАНС A
DO $transfer$
DECLARE
    before_total numeric;
    after_total numeric;
    updated_id integer;
BEGIN
    IF 100 <= 0 OR 101001 = 101002 THEN
        RAISE EXCEPTION 'Некорректные параметры перевода';
    END IF;
    PERFORM account_id FROM public.l10_accounts
        WHERE account_id IN (101001, 101002) ORDER BY account_id FOR UPDATE;
    SELECT SUM(balance) INTO before_total FROM public.l10_accounts;
    UPDATE public.l10_accounts SET balance = balance - 100
        WHERE account_id = 101001 AND balance >= 100
        RETURNING account_id INTO updated_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Отправитель отсутствует или недостаточно средств'; END IF;
    UPDATE public.l10_accounts SET balance = balance + 100
        WHERE account_id = 101002
        RETURNING account_id INTO updated_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Получатель отсутствует'; END IF;
    SELECT SUM(balance) INTO after_total FROM public.l10_accounts;
    IF after_total IS DISTINCT FROM before_total THEN RAISE EXCEPTION 'Нарушена сумма балансов'; END IF;
END
$transfer$;

-- Шаг 16. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 17. СЕАНС A
SELECT SUM(balance) AS total_balance FROM public.l10_accounts;

-- Шаг 18. СЕАНС A
COMMIT;

-- Шаг 19. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 20. СЕАНС A
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 21. СЕАНС A: Намеренная ошибка получателя; следующим шагом ROLLBACK.
DO $transfer$
DECLARE
    before_total numeric;
    after_total numeric;
    updated_id integer;
BEGIN
    IF 100 <= 0 OR 101001 = 999999 THEN
        RAISE EXCEPTION 'Некорректные параметры перевода';
    END IF;
    PERFORM account_id FROM public.l10_accounts
        WHERE account_id IN (101001, 999999) ORDER BY account_id FOR UPDATE;
    SELECT SUM(balance) INTO before_total FROM public.l10_accounts;
    UPDATE public.l10_accounts SET balance = balance - 100
        WHERE account_id = 101001 AND balance >= 100
        RETURNING account_id INTO updated_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Отправитель отсутствует или недостаточно средств'; END IF;
    UPDATE public.l10_accounts SET balance = balance + 100
        WHERE account_id = 999999
        RETURNING account_id INTO updated_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Получатель отсутствует'; END IF;
    SELECT SUM(balance) INTO after_total FROM public.l10_accounts;
    IF after_total IS DISTINCT FROM before_total THEN RAISE EXCEPTION 'Нарушена сумма балансов'; END IF;
END
$transfer$;

-- Шаг 22. СЕАНС A
ROLLBACK;

-- Шаг 23. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 24. СЕАНС A
SELECT SUM(balance) AS total_balance FROM public.l10_accounts;

-- Шаг 25. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 26. СЕАНС A
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 27. СЕАНС A
UPDATE public.l10_accounts SET balance = balance - 100 WHERE account_id = 101001 RETURNING account_id, balance;

-- Шаг 28. СЕАНС A
SELECT balance FROM public.l10_accounts WHERE account_id = 101001;

-- Шаг 29. СЕАНС B
SELECT balance FROM public.l10_accounts WHERE account_id = 101001;

-- Шаг 30. СЕАНС A
ROLLBACK;

-- Шаг 31. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 32. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 33. СЕАНС A
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 34. СЕАНС A
SELECT balance FROM public.l10_accounts WHERE account_id = 101001;

-- Шаг 35. СЕАНС B
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 36. СЕАНС B
DO $transfer$
DECLARE
    before_total numeric;
    after_total numeric;
    updated_id integer;
BEGIN
    IF 5 <= 0 OR 101001 = 101002 THEN
        RAISE EXCEPTION 'Некорректные параметры перевода';
    END IF;
    PERFORM account_id FROM public.l10_accounts
        WHERE account_id IN (101001, 101002) ORDER BY account_id FOR UPDATE;
    SELECT SUM(balance) INTO before_total FROM public.l10_accounts;
    UPDATE public.l10_accounts SET balance = balance - 5
        WHERE account_id = 101001 AND balance >= 5
        RETURNING account_id INTO updated_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Отправитель отсутствует или недостаточно средств'; END IF;
    UPDATE public.l10_accounts SET balance = balance + 5
        WHERE account_id = 101002
        RETURNING account_id INTO updated_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Получатель отсутствует'; END IF;
    SELECT SUM(balance) INTO after_total FROM public.l10_accounts;
    IF after_total IS DISTINCT FROM before_total THEN RAISE EXCEPTION 'Нарушена сумма балансов'; END IF;
END
$transfer$;

-- Шаг 37. СЕАНС B
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 38. СЕАНС B
SELECT SUM(balance) AS total_balance FROM public.l10_accounts;

-- Шаг 39. СЕАНС B
COMMIT;

-- Шаг 40. СЕАНС A
SELECT balance FROM public.l10_accounts WHERE account_id = 101001;

-- Шаг 41. СЕАНС A
COMMIT;

-- Шаг 42. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 43. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 44. СЕАНС A
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- Шаг 45. СЕАНС A
SELECT balance FROM public.l10_accounts WHERE account_id = 101001;

-- Шаг 46. СЕАНС B
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 47. СЕАНС B
DO $transfer$
DECLARE
    before_total numeric;
    after_total numeric;
    updated_id integer;
BEGIN
    IF 9 <= 0 OR 101001 = 101002 THEN
        RAISE EXCEPTION 'Некорректные параметры перевода';
    END IF;
    PERFORM account_id FROM public.l10_accounts
        WHERE account_id IN (101001, 101002) ORDER BY account_id FOR UPDATE;
    SELECT SUM(balance) INTO before_total FROM public.l10_accounts;
    UPDATE public.l10_accounts SET balance = balance - 9
        WHERE account_id = 101001 AND balance >= 9
        RETURNING account_id INTO updated_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Отправитель отсутствует или недостаточно средств'; END IF;
    UPDATE public.l10_accounts SET balance = balance + 9
        WHERE account_id = 101002
        RETURNING account_id INTO updated_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Получатель отсутствует'; END IF;
    SELECT SUM(balance) INTO after_total FROM public.l10_accounts;
    IF after_total IS DISTINCT FROM before_total THEN RAISE EXCEPTION 'Нарушена сумма балансов'; END IF;
END
$transfer$;

-- Шаг 48. СЕАНС B
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 49. СЕАНС B
SELECT SUM(balance) AS total_balance FROM public.l10_accounts;

-- Шаг 50. СЕАНС B
COMMIT;

-- Шаг 51. СЕАНС A
SELECT balance FROM public.l10_accounts WHERE account_id = 101001;

-- Шаг 52. СЕАНС A
COMMIT;

-- Шаг 53. СЕАНС A
SELECT balance FROM public.l10_accounts WHERE account_id = 101001;

-- Шаг 54. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 55. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 56. СЕАНС A
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 57. СЕАНС A
UPDATE public.l10_accounts SET balance = balance - 3 WHERE account_id = 101001 AND balance >= 3 RETURNING account_id, balance;

-- Шаг 58. СЕАНС B
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 59. СЕАНС B: Запустить и оставить ожидающим; перейти в M, затем A.
UPDATE public.l10_accounts SET balance = balance + 2 WHERE account_id = 101001 RETURNING account_id, balance;

-- Шаг 60. СЕАНС M
SELECT pid, application_name, state, wait_event_type, wait_event, pg_blocking_pids(pid) AS blockers FROM pg_stat_activity WHERE datname = current_database() ORDER BY pid;

-- Шаг 61. СЕАНС M
SELECT pid, locktype, mode, granted, transactionid FROM pg_locks WHERE pid IN (SELECT pid FROM pg_stat_activity WHERE datname = current_database()) ORDER BY pid, locktype, granted;

-- Шаг 62. СЕАНС A
UPDATE public.l10_accounts SET balance = balance + 3 WHERE account_id = 101002 RETURNING account_id, balance;

-- Шаг 63. СЕАНС A
DO $check$
BEGIN
    IF (SELECT SUM(balance) FROM public.l10_accounts) IS DISTINCT FROM 5022250.00::numeric
    THEN RAISE EXCEPTION 'Нарушена сумма балансов'; END IF;
END
$check$;

-- Шаг 64. СЕАНС A: Освободить строку: ожидающий UPDATE B продолжится.
COMMIT;

-- Шаг 65. СЕАНС B
UPDATE public.l10_accounts SET balance = balance - 2 WHERE account_id = 101002 AND balance >= 2 RETURNING account_id, balance;

-- Шаг 66. СЕАНС B
DO $check$
BEGIN
    IF (SELECT SUM(balance) FROM public.l10_accounts) IS DISTINCT FROM 5022250.00::numeric
    THEN RAISE EXCEPTION 'Нарушена сумма балансов'; END IF;
END
$check$;

-- Шаг 67. СЕАНС B
COMMIT;

-- Шаг 68. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 69. СЕАНС A
SELECT SUM(balance) AS total_balance FROM public.l10_accounts;

-- Шаг 70. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 71. СЕАНС A
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 72. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id = 101001 FOR UPDATE;

-- Шаг 73. СЕАНС B
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 74. СЕАНС B
SET LOCAL lock_timeout = '2s';

-- Шаг 75. СЕАНС B: Ожидается 55P03; после ошибки выполнить ROLLBACK B.
SELECT account_id FROM public.l10_accounts WHERE account_id = 101001 FOR UPDATE NOWAIT;

-- Шаг 76. СЕАНС B
ROLLBACK;

-- Шаг 77. СЕАНС A
ROLLBACK;

-- Шаг 78. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 79. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 80. СЕАНС A
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 81. СЕАНС A
UPDATE public.l10_accounts SET balance = balance + 1 WHERE account_id = 101001 RETURNING account_id, balance;

-- Шаг 82. СЕАНС B
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Шаг 83. СЕАНС B
UPDATE public.l10_accounts SET balance = balance + 1 WHERE account_id = 101002 RETURNING account_id, balance;

-- Шаг 84. СЕАНС A: Оставить ожидающим; перейти в M, затем B.
UPDATE public.l10_accounts SET balance = balance + 1 WHERE account_id = 101002 RETURNING account_id, balance;

-- Шаг 85. СЕАНС M
SELECT pid, application_name, state, wait_event_type, wait_event, pg_blocking_pids(pid) AS blockers FROM pg_stat_activity WHERE datname = current_database() ORDER BY pid;

-- Шаг 86. СЕАНС M
SELECT pid, locktype, mode, granted, transactionid FROM pg_locks WHERE pid IN (SELECT pid FROM pg_stat_activity WHERE datname = current_database()) ORDER BY pid, locktype, granted;

-- Шаг 87. СЕАНС B: Оставить ожидающим; сразу перейти в M. PostgreSQL выберет жертву deadlock.
UPDATE public.l10_accounts SET balance = balance + 1 WHERE account_id = 101001 RETURNING account_id, balance;

-- Шаг 88. СЕАНС M
SELECT pid, application_name, state, wait_event_type, wait_event, pg_blocking_pids(pid) AS blockers FROM pg_stat_activity WHERE datname = current_database() ORDER BY pid;

-- Шаг 89. СЕАНС M
SELECT pid, locktype, mode, granted, transactionid FROM pg_locks WHERE pid IN (SELECT pid FROM pg_stat_activity WHERE datname = current_database()) ORDER BY pid, locktype, granted;

-- Шаг 90. СЕАНС A: Откатить и жертву, и продолжившуюся транзакцию; жертва может отличаться при повторе.
ROLLBACK;

-- Шаг 91. СЕАНС B
ROLLBACK;

-- Шаг 92. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 93. СЕАНС A
SELECT SUM(balance) AS total_balance FROM public.l10_accounts;

-- Шаг 94. СЕАНС A
SELECT account_id, balance FROM public.l10_accounts WHERE account_id IN (101001, 101002) ORDER BY account_id;

-- Шаг 95. СЕАНС A
SELECT SUM(balance) AS total_balance FROM public.l10_accounts;

-- Шаг 96. СЕАНС M
SELECT COUNT(*) AS open_user_transactions FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid() AND (xact_start IS NOT NULL OR state LIKE 'idle in transaction%');

-- Шаг 97. СЕАНС M
SELECT pid, application_name, state, wait_event_type, wait_event, pg_blocking_pids(pid) AS blockers FROM pg_stat_activity WHERE datname = current_database() ORDER BY pid;

-- Шаг 98. СЕАНС A
SELECT COUNT(*) AS negative_balances FROM public.l10_accounts WHERE balance < 0;
