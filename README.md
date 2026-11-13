# Lottery Monitoring Dashboard

Node + Express + PostgreSQL. The UI is in `public/index.html` and uses Chart.js.

## Setup
```bash
createdb -h localhost lottery_dashboard
npm install
npm run db:init      # creates tables + loads sample data (drops existing tables)
npm start            # http://localhost:3000
```
Set `DATABASE_URL` to use a different database, e.g. `postgres://user:pass@host:5432/db`.

## Tables
- `users` — admin users (`j.diaz`)
- `lotteries` — sort_order, name, status (Open/Closed), result, chart color, close_time
- `tickets` — lottery_id, sold_by, amount, status (Sold/Canceled), sold_at, canceled_at

## API
| Method | Path | Purpose |
|---|---|---|
| GET | `/api/summary` | Total sales, ticket count, canceled count |
| GET | `/api/lotteries?sort=order\|name&dir=asc\|desc` | Lottery status table |
| GET | `/api/sales-by-lottery` | Sales + sold tickets per lottery (charts) |
| PATCH | `/api/lotteries/:id` | `{status}` and/or `{result}` |
| POST | `/api/tickets` | `{lottery_id, amount}` record a sale |
| POST | `/api/tickets/:id/cancel` | Cancel a ticket |
