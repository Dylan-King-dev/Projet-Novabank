SET ROLE bank_owner;

-- Clients
CREATE TABLE core.customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(30),
    birth_date DATE NOT NULL,
    kyc_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    risk_level VARCHAR(20) NOT NULL DEFAULT 'low',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT customers_email_format
        CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),

    CONSTRAINT customers_kyc_status
        CHECK (kyc_status IN ('pending', 'verified', 'rejected')),

    CONSTRAINT customers_risk_level
        CHECK (risk_level IN ('low', 'medium', 'high'))
);

-- Comptes bancaires
CREATE TABLE core.accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES core.customers(customer_id),
    iban VARCHAR(34) NOT NULL UNIQUE,
    account_type VARCHAR(20) NOT NULL,
    balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    opened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT accounts_balance_nonnegative
        CHECK (balance >= 0),

    CONSTRAINT accounts_type
        CHECK (account_type IN ('checking', 'savings')),

    CONSTRAINT accounts_status
        CHECK (status IN ('active', 'blocked', 'closed'))
);

-- Virements
CREATE TABLE core.transfers (
    transfer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_account_id BIGINT NOT NULL REFERENCES core.accounts(account_id),
    to_account_id BIGINT NOT NULL REFERENCES core.accounts(account_id),
    amount NUMERIC(18,2) NOT NULL,
    label TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT transfers_amount_positive
        CHECK (amount > 0),

    CONSTRAINT transfers_different_accounts
        CHECK (from_account_id <> to_account_id)
);

-- Journal comptable des transactions
CREATE TABLE core.transactions (
    tx_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES core.accounts(account_id),
    tx_type VARCHAR(20) NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    balance_after NUMERIC(18,2) NOT NULL,
    transfer_id BIGINT REFERENCES core.transfers(transfer_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT transactions_type
        CHECK (tx_type IN ('deposit', 'withdrawal', 'transfer_in', 'transfer_out')),

    CONSTRAINT transactions_amount_nonzero
        CHECK (amount <> 0),

    CONSTRAINT transactions_balance_nonnegative
        CHECK (balance_after >= 0)
);

-- Alertes de fraude
CREATE TABLE core.fraud_alerts (
    alert_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES core.accounts(account_id),
    tx_id BIGINT REFERENCES core.transactions(tx_id),
    rule_code VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fraud_alerts_status
        CHECK (status IN ('open', 'investigating', 'closed'))
);

-- Journal d'audit
CREATE TABLE audit.audit_log (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    db_user TEXT NOT NULL DEFAULT CURRENT_USER,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT audit_log_operation
        CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

RESET ROLE;
