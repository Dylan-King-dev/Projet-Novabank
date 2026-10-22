CREATE EXTENSION IF NOT EXISTS pg_trgm;

SET ROLE bank_owner;

CREATE INDEX idx_accounts_customer_id
    ON core.accounts (customer_id);

CREATE INDEX idx_transactions_account_created
    ON core.transactions (account_id, created_at DESC);

CREATE INDEX idx_transfers_from_account
    ON core.transfers (from_account_id);

CREATE INDEX idx_fraud_alerts_open_account
    ON core.fraud_alerts (account_id)
    WHERE status = 'open';

CREATE INDEX idx_customers_lower_last_name
    ON core.customers (LOWER(last_name));

CREATE INDEX idx_transactions_created_brin
    ON core.transactions USING BRIN (created_at);

CREATE INDEX idx_transfers_label_trgm
    ON core.transfers USING GIN (label gin_trgm_ops);

RESET ROLE;
