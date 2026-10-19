-- V1__init_baseline.sql
-- Baseline schema: revoked tokens for JWT logout & invalidation

CREATE TABLE IF NOT EXISTS revoked_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    token_hash VARCHAR(64) NOT NULL,
    user_id BIGINT NOT NULL,
    expiry_date DATETIME(6) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT uk_revoked_tokens_hash UNIQUE (token_hash),
    INDEX idx_revoked_tokens_user (user_id),
    INDEX idx_revoked_tokens_expiry (expiry_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
