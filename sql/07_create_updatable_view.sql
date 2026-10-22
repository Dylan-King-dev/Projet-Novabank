SET ROLE bank_owner;

CREATE VIEW core.v_customer_kyc AS
SELECT
	customer_id,
	kyc_status
FROM core.customers
WHERE kyc_status IN ('pending', 'verified')
WITH LOCAL CHECK OPTION;

GRANT SELECT ON core.v_customer_kyc TO support;
GRANT UPDATE (kyc_status) ON core.v_customer_kyc TO support;

RESET ROLE;
