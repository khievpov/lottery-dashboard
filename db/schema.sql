-- Lottery Monitoring Dashboard — PostgreSQL schema
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS lotteries;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS lottery_status;
DROP TYPE IF EXISTS ticket_status;

CREATE TYPE lottery_status AS ENUM ('Open', 'Closed');
CREATE TYPE ticket_status  AS ENUM ('Sold', 'Canceled');

CREATE TABLE users (
  id          SERIAL PRIMARY KEY,
  username    VARCHAR(50)  NOT NULL UNIQUE,
  full_name   VARCHAR(100) NOT NULL,
  role        VARCHAR(20)  NOT NULL DEFAULT 'Admin',
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE lotteries (
  id          SERIAL PRIMARY KEY,
  sort_order  INT          NOT NULL UNIQUE,
  name        VARCHAR(100) NOT NULL UNIQUE,
  status      lottery_status NOT NULL DEFAULT 'Open',
  result      VARCHAR(20),               -- NULL = "Waiting for winner..."
  color       VARCHAR(9)   NOT NULL DEFAULT '#c5d08d',  -- chart bar color
  close_time  TIME,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE tickets (
  id          BIGSERIAL PRIMARY KEY,
  lottery_id  INT NOT NULL REFERENCES lotteries(id) ON DELETE CASCADE,
  sold_by     INT REFERENCES users(id),
  amount      NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  status      ticket_status NOT NULL DEFAULT 'Sold',
  sold_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
  canceled_at TIMESTAMPTZ
);

CREATE INDEX idx_tickets_lottery ON tickets(lottery_id);
CREATE INDEX idx_tickets_sold_at ON tickets(sold_at);
