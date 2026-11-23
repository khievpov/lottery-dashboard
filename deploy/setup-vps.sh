#!/usr/bin/env bash
# One-time setup for a fresh Hostinger VPS (Ubuntu 22.04 / 24.04).
# Run on the VPS as root:
#   curl -fsSL https://raw.githubusercontent.com/khievpov/lottery-dashboard/main/deploy/setup-vps.sh -o setup-vps.sh
#   sudo DOMAIN=example.com EMAIL=you@example.com bash setup-vps.sh
# DOMAIN and EMAIL are optional; with both set, HTTPS is enabled via Let's Encrypt.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/khievpov/lottery-dashboard.git}"
APP_DIR="${APP_DIR:-/var/www/lottery-dashboard}"
APP_USER="${APP_USER:-deploy}"
DB_NAME="lottery_dashboard"
DB_USER="lottery"
DOMAIN="${DOMAIN:-}"
EMAIL="${EMAIL:-}"

[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)."; exit 1; }

echo "==> Installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl git nginx postgresql ca-certificates
if ! command -v node >/dev/null || [ "$(node -p 'process.versions.node.split(".")[0]')" -lt 22 ]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi
npm install -g pm2

echo "==> Creating deploy user '$APP_USER'"
id "$APP_USER" >/dev/null 2>&1 || adduser --disabled-password --gecos "" "$APP_USER"
mkdir -p "/home/$APP_USER/.ssh" && chmod 700 "/home/$APP_USER/.ssh"
touch "/home/$APP_USER/.ssh/authorized_keys" && chmod 600 "/home/$APP_USER/.ssh/authorized_keys"
chown -R "$APP_USER:$APP_USER" "/home/$APP_USER/.ssh"

echo "==> Setting up PostgreSQL"
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  DB_PASS="$(openssl rand -hex 24)"
  sudo -u postgres psql -c "CREATE ROLE $DB_USER LOGIN PASSWORD '$DB_PASS'"
  sudo -u postgres createdb -O "$DB_USER" "$DB_NAME"
  NEW_DB=1
else
  NEW_DB=0
fi

echo "==> Cloning app to $APP_DIR"
mkdir -p "$(dirname "$APP_DIR")"
if [ ! -d "$APP_DIR/.git" ]; then
  git clone "$REPO_URL" "$APP_DIR"
fi
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

if [ "$NEW_DB" -eq 1 ]; then
  umask 077
  cat > "$APP_DIR/.env" <<EOF
DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME
PORT=3000
EOF
  chown "$APP_USER:$APP_USER" "$APP_DIR/.env"
  echo "==> Loading schema and sample data"
  sudo -u "$APP_USER" bash -c "cd '$APP_DIR' && PGPASSWORD='$DB_PASS' psql -h localhost -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -q -f db/schema.sql -f db/seed.sql"
fi

echo "==> Installing dependencies and starting with pm2"
sudo -u "$APP_USER" bash -c "cd '$APP_DIR' && npm ci --omit=dev && pm2 startOrReload ecosystem.config.cjs && pm2 save"
env PATH="$PATH:/usr/bin" pm2 startup systemd -u "$APP_USER" --hp "/home/$APP_USER" >/dev/null

echo "==> Configuring nginx"
cat > /etc/nginx/sites-available/lottery-dashboard <<EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
ln -sf /etc/nginx/sites-available/lottery-dashboard /etc/nginx/sites-enabled/lottery-dashboard
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

if [ -n "$DOMAIN" ] && [ -n "$EMAIL" ]; then
  echo "==> Enabling HTTPS for $DOMAIN"
  apt-get install -y certbot python3-certbot-nginx
  certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
fi

echo
echo "Done. Dashboard: http://${DOMAIN:-<your-vps-ip>}"
echo "Next: add the GitHub Actions public key to /home/$APP_USER/.ssh/authorized_keys (see README)."
