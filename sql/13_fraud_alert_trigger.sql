SET ROLE bank_owner;

CREATE OR REPLACE FUNCTION core.check_fraud_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    
    IF NEW.tx_type = 'withdrawal' AND ABS(NEW.amount) >= 5000 THEN
        INSERT INTO core.fraud_alerts (
            account_id, tx_id, rule_code, status
        )
        VALUES (
            NEW.account_id,
            NEW.tx_id,
            'LARGE_WITHDRAWAL',
            'open'
        );
    END IF;

    IF NEW.tx_type = 'transfer_out' THEN
        IF (
            SELECT COUNT(*)
            FROM core.transactions t
            WHERE t.account_id = NEW.account_id
              AND t.tx_type = 'transfer_out'
              AND t.created_at >= NEW.created_at - INTERVAL '10 minutes'
              AND t.created_at <= NEW.created_at
        ) >= 5 THEN
            INSERT INTO core.fraud_alerts (
                account_id, tx_id, rule_code, status
            )
            VALUES (
                NEW.account_id,
                NEW.tx_id,
                'FREQUENT_TRANSFERS',
                'open'
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_fraud_rules
AFTER INSERT ON core.transactions
FOR EACH ROW
EXECUTE FUNCTION core.check_fraud_rules();

RESET ROLE;
