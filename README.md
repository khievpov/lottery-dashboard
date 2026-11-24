# Lottery Monitoring Dashboard

Node + Express + PostgreSQL. The UI is in `public/index.html` and uses Chart.js.

## Setup (local, macOS with Postgres.app)
This Mac also runs other PostgreSQL servers on port 5432, so the app's database runs from Postgres.app on port **5434**.
```bash
npm install
cp .env.example .env   # DATABASE_URL=postgres://localhost:5434/lottery_dashboard
npm run db:start       # start Postgres.app's data on port 5434 (once after each restart)
npm start              # http://localhost:3000
```
First time only: `createdb -h localhost -p 5434 lottery_dashboard && npm run db:init` (drops existing tables).
Stop the database with `npm run db:stop`.

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

## Deploy to Hostinger VPS

Every push to `main` deploys automatically through GitHub Actions ([.github/workflows/deploy.yml](.github/workflows/deploy.yml)).

### 1. One-time VPS setup
In Hostinger hPanel → VPS, choose an **Ubuntu 22.04/24.04** OS and note the IP. SSH in as root and run:
```bash
curl -fsSL https://raw.githubusercontent.com/khievpov/lottery-dashboard/main/deploy/setup-vps.sh -o setup-vps.sh
sudo bash setup-vps.sh
```
With a domain pointed at the VPS (an A record to the VPS IP), add HTTPS:
```bash
sudo DOMAIN=dashboard.example.com EMAIL=you@example.com bash setup-vps.sh
```
The script installs Node 22, PostgreSQL, nginx and pm2, creates a `deploy` user and a database with a random password (saved in `/var/www/lottery-dashboard/.env`), loads the sample data, and serves the app on port 80.

### 2. Give GitHub an SSH key for the VPS
On your computer:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/lottery_deploy -N "" -C "github-actions-deploy"
```
Copy the contents of `~/.ssh/lottery_deploy.pub` into `/home/deploy/.ssh/authorized_keys` on the VPS.

### 3. Add repository secrets
GitHub → repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|---|---|
| `VPS_HOST` | VPS IP address |
| `VPS_USER` | `deploy` |
| `VPS_SSH_KEY` | contents of `~/.ssh/lottery_deploy` (the private key) |
| `VPS_PORT` | optional, defaults to `22` |

Then push to `main`, or run the workflow from the **Actions** tab. The last step checks that `/api/summary` responds.

Note: `npm run db:init` drops all tables. Don't run it on the VPS after real data exists.
