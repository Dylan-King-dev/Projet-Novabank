SET ROLE bank_owner;

CREATE OR REPLACE FUNCTION core.update_account_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE core.accounts
    SET balance = balance + NEW.amount
    WHERE account_id = NEW.account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Compte introuvable : %', NEW.account_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_account_balance
AFTER INSERT ON core.transactions
FOR EACH ROW
EXECUTE FUNCTION core.update_account_balance();

RESET ROLE;
