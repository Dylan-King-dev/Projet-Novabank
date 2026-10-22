SET ROLE bank_owner;

CREATE VIEW core.v_customers_masked AS
SELECT
	customer_id,
	first_name,
	LEFT(last_name, 1) || '***' AS last_name_masked,
	LEFT(email, 1) || '***@' || SPLIT_PART(email, '@', 2) AS email_masked,
	CASE
		WHEN phone IS NOT NULL THEN '******' || RIGHT(phone, 2)
		ELSE NULL
	END AS phone_masked,
	kyc_status,
	risk_level,
	created_at
FROM core.customers;

GRANT SELECT ON core.v_customers_masked TO support;

RESET ROLE;
