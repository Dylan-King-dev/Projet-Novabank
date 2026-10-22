
SET ROLE bank_owner;

CREATE OR REPLACE PROCEDURE core.execute_transfer(
    p_from_account_id BIGINT,
    p_to_account_id BIGINT,
    p_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_balance NUMERIC(18,2);
    v_to_balance NUMERIC(18,2);
    v_transfer_id BIGINT;
    v_account_count INTEGER;
BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'Le montant du virement doit être positif.';
    END IF;

    IF p_from_account_id = p_to_account_id THEN
        RAISE EXCEPTION 'Les comptes source et destination doivent être différents.';
    END IF;

    PERFORM account_id
    FROM core.accounts
    WHERE account_id IN (p_from_account_id, p_to_account_id)
    ORDER BY account_id
    FOR UPDATE;

    SELECT COUNT(*)
    INTO v_account_count
    FROM core.accounts
    WHERE account_id IN (p_from_account_id, p_to_account_id);

    IF v_account_count <> 2 THEN
        RAISE EXCEPTION 'Compte source ou destination introuvable.';
    END IF;

    SELECT balance INTO v_from_balance
    FROM core.accounts
    WHERE account_id = p_from_account_id;

    SELECT balance INTO v_to_balance
    FROM core.accounts
    WHERE account_id = p_to_account_id;

    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Solde insuffisant.';
    END IF;

    INSERT INTO core.transfers (
        from_account_id,
        to_account_id,
        amount
    )
    VALUES (
        p_from_account_id,
        p_to_account_id,
        p_amount
    )
    RETURNING transfer_id INTO v_transfer_id;

    INSERT INTO core.transactions (
        account_id,
        tx_type,
        amount,
        balance_after,
        transfer_id
    )
    VALUES (
        p_from_account_id,
        'transfer_out',
        -p_amount,
        v_from_balance - p_amount,
        v_transfer_id
    );

    INSERT INTO core.transactions (
        account_id,
        tx_type,
        amount,
        balance_after,
        transfer_id
    )
    VALUES (
        p_to_account_id,
        'transfer_in',
        p_amount,
        v_to_balance + p_amount,
        v_transfer_id
    );
END;
$$;

ALTER PROCEDURE core.execute_transfer(BIGINT, BIGINT, NUMERIC)
	SECURITY DEFINER;

ALTER PROCEDURE core.execute_transfer(BIGINT, BIGINT, NUMERIC)
	SET search_path TO pg_catalog, core, audit;

GRANT EXECUTE ON PROCEDURE
	core.execute_transfer(BIGINT, BIGINT, NUMERIC)
TO app;

REVOKE ALL ON PROCEDURE
    core.execute_transfer(BIGINT, BIGINT, NUMERIC)
FROM PUBLIC;

RESET ROLE;
