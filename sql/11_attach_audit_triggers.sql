SET ROLE bank_owner;

CREATE TRIGGER trg_audit_customers
AFTER INSERT OR UPDATE OR DELETE ON core.customers
FOR EACH ROW
EXECUTE FUNCTION audit.log_change();

CREATE TRIGGER trg_audit_accounts
AFTER INSERT OR UPDATE OR DELETE ON core.accounts
FOR EACH ROW
EXECUTE FUNCTION audit.log_change();

CREATE TRIGGER trg_audit_transfers
AFTER INSERT OR UPDATE OR DELETE ON core.transfers
FOR EACH ROW
EXECUTE FUNCTION audit.log_change();

RESET ROLE;
