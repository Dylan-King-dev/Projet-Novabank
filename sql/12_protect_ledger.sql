SET ROLE bank_owner;

CREATE OR REPLACE FUNCTION core.prevent_ledger_modification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'Le journal comptable est immuable : modification ou suppression interdite.';
END;
$$;

CREATE TRIGGER trg_immutable_transactions
BEFORE UPDATE OR DELETE ON core.transactions
FOR EACH ROW
EXECUTE FUNCTION core.prevent_ledger_modification();

RESET ROLE;
