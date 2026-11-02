-- В исходном seed таблица l10_tasks отсутствует. Пустая таблица нужна только для COUNT(*) (слайды 26–27).
CREATE TABLE public.l10_tasks (
    task_id integer PRIMARY KEY,
    status text NOT NULL DEFAULT 'new'
);
SELECT COUNT(*) AS tasks_count FROM public.l10_tasks;
