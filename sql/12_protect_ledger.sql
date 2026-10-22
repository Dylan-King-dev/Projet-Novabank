
SET ROLE bank_owner;

CREATE OR REPLACE FUNCTION core.prevent_ledger_modification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'Le journal comptable est immuable : modification, suppression ou TRUNCATE interdit.';
END;
$$;

CREATE TRIGGER trg_immutable_transactions
BEFORE UPDATE OR DELETE ON core.transactions
FOR EACH ROW
EXECUTE FUNCTION core.prevent_ledger_modification();

CREATE TRIGGER trg_immutable_transactions_truncate
BEFORE TRUNCATE ON core.transactions
FOR EACH STATEMENT
EXECUTE FUNCTION core.prevent_ledger_modification();

RESET ROLE;
