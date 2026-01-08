CREATE TABLE
  IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    balance INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT positive_balance CHECK (balance >= 0)
  );

CREATE TABLE
  IF NOT EXISTS transaction_logs (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts (id),
    description TEXT,
    amount INTEGER,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

-- Seeding some data
INSERT INTO
  accounts (name, balance)
VALUES
  ('Max', 1000),
  ('Helen', 1000),
  ('Bob', 0);