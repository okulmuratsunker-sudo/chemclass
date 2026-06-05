-- Kasa D1 Database Schema
-- Run in Cloudflare Dashboard → D1 → kasa-db → Console

CREATE TABLE IF NOT EXISTS users (
  id           TEXT PRIMARY KEY,
  email        TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  salt         TEXT NOT NULL,
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS bills (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL DEFAULT '',
  category    TEXT NOT NULL DEFAULT 'Diğer',
  amount      REAL NOT NULL DEFAULT 0,
  currency    TEXT NOT NULL DEFAULT 'TRY',
  bill_date   TEXT,
  due_date    TEXT,
  paid        INTEGER NOT NULL DEFAULT 0,
  notes       TEXT NOT NULL DEFAULT '',
  file_key    TEXT,
  file_name   TEXT,
  file_type   TEXT,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS identities (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL DEFAULT '',
  doc_type    TEXT NOT NULL DEFAULT 'Kimlik',
  doc_number  TEXT NOT NULL DEFAULT '',
  issuer      TEXT NOT NULL DEFAULT '',
  issue_date  TEXT,
  expiry_date TEXT,
  notes       TEXT NOT NULL DEFAULT '',
  file_key    TEXT,
  file_name   TEXT,
  file_type   TEXT,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_bills_user     ON bills(user_id);
CREATE INDEX IF NOT EXISTS idx_bills_due      ON bills(due_date);
CREATE INDEX IF NOT EXISTS idx_ids_user       ON identities(user_id);
CREATE INDEX IF NOT EXISTS idx_ids_expiry     ON identities(expiry_date);
