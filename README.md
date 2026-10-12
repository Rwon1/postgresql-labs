# Практические работы по PostgreSQL

Технологии и средства анализа больших данных.

Егоров, группа 16М-нф26.

| Работа | SQL | Скриншот |
|---|---|---|
| 1. Таблица клиентов | [Код](sql/lecture01_egorov.sql) | [Результат](screenshots/practice-1.png) |
| 2. Создание и изменение данных | [Код](sql/lecture02.sql) | [Результат](screenshots/practice-2.png) |
| 3. Фильтрация и сортировка | [Код](sql/lecture03_egorov.sql) | [Результат](screenshots/practice-3.png) |
| 4. Агрегатные функции | [Код](sql/lecture04_egorov.sql) | [Результат](screenshots/practice-4.png) |
| 5. Соединения таблиц | [Код](sql/lecture05_egorov.sql) | [Результат](screenshots/practice-5.png) |
| 6. Подзапросы и CTE | [Код](sql/lecture06_egorov.sql) | [Результат](screenshots/practice-6.png) |
| 7. Оконные функции | [Код](sql/lecture07_egorov.sql) | [Результат](screenshots/practice-7.png) |
| 8. Индексы и EXPLAIN | [Код](sql/lecture08_egorov.sql) | [Результат](screenshots/practice-8.png) |
| 9. VIEW и MATERIALIZED VIEW | [Код](sql/lecture09_egorov.sql) | [Результат](screenshots/practice-9.png) |

SQL выполнен в PostgreSQL 16 через pgAdmin. Полные файлы запускаются по порядку;
`READ_1`–`READ_9` содержат запросы к готовой базе.

Планы и выводы: [работа 8](results/lecture08/analysis.md), [работа 9](results/lecture09/analysis.md).

Работа 9 использует данные работы 8: `lecture_09_seed.sql` в материалах отсутствует.

Для работы 2 путь к папке CSV задаётся в начале сеанса:
`SET coursework.data_dir = 'C:/pg_lab/data';`.
