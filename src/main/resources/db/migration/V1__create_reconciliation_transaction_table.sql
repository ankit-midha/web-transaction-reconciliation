-- V1: Create base reconciliation_transaction table with all columns, indexes, and grants

CREATE TABLE reconciliation_transaction (
    id BIGSERIAL PRIMARY KEY,
    reference VARCHAR(255) UNIQUE NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    external_reference_type VARCHAR(50) NOT NULL,
    external_reference VARCHAR(255),
    amount DECIMAL(19,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT DEFAULT 0 NOT NULL
);

CREATE INDEX idx_reference ON reconciliation_transaction(reference);
CREATE INDEX idx_external_ref ON reconciliation_transaction(external_reference);

GRANT SELECT, INSERT, UPDATE, DELETE ON reconciliation_transaction TO postgres;
GRANT USAGE, SELECT ON SEQUENCE reconciliation_transaction_id_seq TO postgres;
