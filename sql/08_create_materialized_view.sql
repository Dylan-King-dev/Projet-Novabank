SET ROLE bank_owner;

CREATE MATERIALIZED VIEW core.mv_account_summary AS
SELECT
	account_type,
	status,
	COUNT(*) AS account_count,
	SUM(balance) AS total_balance,
	AVG(balance) AS average_balance
FROM core.accounts
GROUP BY account_type, status;

GRANT SELECT ON core.mv_account_summary TO analyst;
GRANT SELECT ON core.mv_account_summary TO app;

RESET ROLE;
