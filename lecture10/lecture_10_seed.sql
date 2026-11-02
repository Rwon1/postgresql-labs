-- Lecture 10: safe repeatable data generation for PostgreSQL
BEGIN;
CREATE TABLE IF NOT EXISTS l10_accounts (account_id integer PRIMARY KEY, customer_id integer, balance numeric(14,2) NOT NULL DEFAULT 0, updated_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE l10_accounts ADD COLUMN IF NOT EXISTS customer_id integer;
ALTER TABLE l10_accounts ADD COLUMN IF NOT EXISTS balance numeric(14,2) NOT NULL DEFAULT 0;
ALTER TABLE l10_accounts ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();
CREATE TABLE IF NOT EXISTS l10_transfers (transfer_id integer PRIMARY KEY, from_account_id integer NOT NULL, to_account_id integer NOT NULL, amount numeric(14,2) NOT NULL CHECK(amount>0), created_at timestamptz NOT NULL DEFAULT now(), status text NOT NULL DEFAULT 'completed');
CREATE TABLE IF NOT EXISTS l10_audit (audit_id integer PRIMARY KEY, account_id integer NOT NULL, event_type text NOT NULL, delta numeric(14,2) NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
INSERT INTO l10_accounts(account_id,customer_id,balance,updated_at)
SELECT 101000+g, 101000+g, (5000+(g*37)%12000)::numeric(14,2), TIMESTAMPTZ '2026-01-01 00:00:00+00'+(g%200)*INTERVAL '1 day'
FROM generate_series(1,500) AS g WHERE NOT EXISTS(SELECT 1 FROM l10_accounts a WHERE a.account_id=101000+g);
INSERT INTO l10_transfers(transfer_id,from_account_id,to_account_id,amount,created_at,status)
SELECT 102000+g,101001+(g%480),101001+((g+17)%480),(20+(g*19)%500)::numeric(14,2),TIMESTAMPTZ '2026-01-01 00:00:00+00'+(g%240)*INTERVAL '1 day',CASE WHEN g%11=0 THEN 'pending' ELSE 'completed' END
FROM generate_series(1,3000) AS g WHERE NOT EXISTS(SELECT 1 FROM l10_transfers t WHERE t.transfer_id=102000+g);
INSERT INTO l10_audit(audit_id,account_id,event_type,delta,created_at)
SELECT 106000+g,101001+(g%480),CASE WHEN g%3=0 THEN 'deposit' WHEN g%3=1 THEN 'withdrawal' ELSE 'adjustment' END,((g*13)%200-80)::numeric(14,2),TIMESTAMPTZ '2026-01-01 00:00:00+00'+(g%240)*INTERVAL '1 day'
FROM generate_series(1,5000) AS g WHERE NOT EXISTS(SELECT 1 FROM l10_audit a WHERE a.audit_id=106000+g);
COMMIT;
SELECT 'l10_accounts' AS table_name,COUNT(*) AS rows FROM l10_accounts
UNION ALL SELECT 'l10_transfers',COUNT(*) FROM l10_transfers
UNION ALL SELECT 'l10_audit',COUNT(*) FROM l10_audit;
SELECT SUM(balance) AS baseline_total FROM l10_accounts WHERE account_id BETWEEN 101001 AND 101500;
-- Two-session experiment: use IDs 101001 and 101002, not 1 and 2.
-- SESSION A: BEGIN; UPDATE l10_accounts SET balance=balance-100 WHERE account_id=101001;
-- SESSION B: SELECT balance FROM l10_accounts WHERE account_id=101001; (different connection)
-- SESSION A: UPDATE l10_accounts SET balance=balance+100 WHERE account_id=101002; COMMIT;
-- Control: the sum of both balances must remain unchanged.
