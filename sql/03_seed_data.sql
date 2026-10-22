SET ROLE bank_owner;

INSERT INTO core.customers (
    first_name,
    last_name,
    email,
    phone,
    birth_date,
    kyc_status,
    risk_level
)
SELECT
    'Prenom' || i,
    'Client' || i,
    'client' || i || '@novabank.test',
    '060000' || LPAD(i::TEXT, 4, '0'),
    DATE '1980-01-01' + (i % 10000),
    'verified',
    'low'
FROM generate_series(1, 1000) AS s(i);

INSERT INTO core.accounts (
    customer_id,
    iban,
    account_type,
    balance,
    status
)
SELECT
    customer_id,
    'FR76' || LPAD(customer_id::TEXT, 23, '0'),
    CASE
        WHEN customer_id % 2 = 0 THEN 'checking'
        ELSE 'savings'
    END,
    10000.00,
    'active'
FROM core.customers;

WITH generated AS (
    SELECT
        n,
        ((n - 1) % 1000) + 1 AS account_id,
        ((n - 1) / 1000)::INTEGER AS cycle
    FROM generate_series(1, 1000000) AS s(n)
),
typed AS (
    SELECT
        n,
        account_id,
        CASE
            WHEN (cycle + account_id) % 2 = 0
                THEN 'deposit'
            ELSE 'withdrawal'
        END AS tx_type
    FROM generated
),
ledger AS (
    SELECT
        n,
        account_id,
        tx_type,
	CASE
		WHEN tx_type = 'deposit' THEN 10.00
		ELSE -10.00
        END::NUMERIC(18,2) AS amount,
        10000.00
        + SUM(
            CASE
                WHEN tx_type = 'deposit' THEN 10.00
                ELSE -10.00
            END
          ) OVER (
              PARTITION BY account_id
              ORDER BY n
          ) AS balance_after
    FROM typed
)
INSERT INTO core.transactions (
    account_id,
    tx_type,
    amount,
    balance_after,
    created_at
)
SELECT
    account_id,
    tx_type,
    amount,
    balance_after,
    CURRENT_TIMESTAMP - ((1000000 - n) * INTERVAL '1 second')
FROM ledger;

RESET ROLE;
