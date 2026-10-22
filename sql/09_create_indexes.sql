SET ROLE bank_owner;

CREATE INDEX idx_accounts_customer_id
	on core.accounts (customer_id);

CREATE INDEX idx_transactions_account_created
	ON core.transactions (account_id, created_at DESC);

CREATE INDEX idx_transfers_from_account
	ON core.transfers (from_account_id);

CREATE INDEX idx_fraud_alerts_open_account
	ON core.fraud_alerts (account_id)
	WHERE status = 'open';

RESET ROLE
