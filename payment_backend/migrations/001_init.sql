CREATE TABLE IF NOT EXISTS payment_orders (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  sku VARCHAR(64) NOT NULL,
  order_type VARCHAR(32) NOT NULL,
  channel VARCHAR(32) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  amount_fen INTEGER NOT NULL,
  status VARCHAR(32) NOT NULL,
  provider_txn_id VARCHAR(128),
  paid_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  raw_notify JSONB,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_payment_orders_user_created
  ON payment_orders(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_orders_status
  ON payment_orders(status);
CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_orders_provider_txn
  ON payment_orders(provider_txn_id) WHERE provider_txn_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS user_memberships (
  user_id VARCHAR(64) PRIMARY KEY,
  sku VARCHAR(64) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_lifetime BOOLEAN NOT NULL DEFAULT FALSE,
  start_at TIMESTAMPTZ,
  expire_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS user_word_wallets (
  user_id VARCHAR(64) PRIMARY KEY,
  vip_gift_words BIGINT NOT NULL DEFAULT 0,
  purchased_words BIGINT NOT NULL DEFAULT 0,
  reward_words BIGINT NOT NULL DEFAULT 0,
  consumed_words BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS user_word_lots (
  id UUID PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  order_id VARCHAR(64) NOT NULL,
  words BIGINT NOT NULL,
  purchased_at TIMESTAMPTZ NOT NULL,
  expire_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_user_word_lots_user_expire
  ON user_word_lots(user_id, expire_at DESC);
