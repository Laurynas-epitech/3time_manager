#!/usr/bin/env bash
# Reviewed one-time cutover for the owner's existing IP address.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.'; exit 1; }
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=/home/ubuntu/3time_manager
site=$(readlink -f /etc/nginx/sites-enabled/time-manager)
[[ "$site" == /etc/nginx/sites-available/time-manager ]] || { echo 'Unexpected Nginx site path.'; exit 1; }
docker inspect time_manager_db_secure --format '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}' | grep -Fx time_manager_postgres_secure_20261008 >/dev/null
[[ $(docker inspect time_manager_db --format '{{.State.Running}}') == false ]] || { echo 'Incident DB must remain stopped.'; exit 1; }
[[ ! -e "$repo/docker-compose.https.yml" ]] || { echo 'HTTPS overlay already exists; inspect before rerunning.'; exit 1; }
[[ ! -e /etc/time-manager-certbot-image ]] || { echo 'Certificate installation already exists; inspect before rerunning.'; exit 1; }
nginx -t
backup=/var/backups/time-manager-https-$(date -u +%Y%m%dT%H%M%SZ)
install -d -m 700 "$backup"
cp -a "$site" "$backup/nginx-before.conf"
cp -a "$repo/docker-compose.secure.yml" "$backup/docker-compose.secure.yml"
app_changed=false
rollback() {
  code=$?
  trap - EXIT
  if [[ $code -ne 0 ]]; then
    echo "HTTPS cutover failed; restoring previous app/proxy configuration from $backup" >&2
    systemctl disable --now time-manager-cert-renew.timer 2>/dev/null || true
    cp "$backup/nginx-before.conf" "$site"
    cp "$backup/docker-compose.secure.yml" "$repo/docker-compose.secure.yml"
    if [[ "$app_changed" == true ]]; then
      (cd "$repo" && docker compose -f docker-compose.secure.yml up -d --no-deps --no-build backend frontend) || true
    fi
    nginx -t && systemctl reload nginx || true
  fi
  exit "$code"
}
trap rollback EXIT

install -d -m 755 /var/www/time-manager-acme/.well-known/acme-challenge
install -d -m 700 /etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt
docker pull certbot/certbot:v5.8.0
image=$(docker image inspect certbot/certbot:v5.8.0 --format '{{index .RepoDigests 0}}')
[[ "$image" == certbot/certbot@sha256:* ]] || { echo 'Unexpected Certbot image digest.'; exit 1; }

# Keep HTTP application access during ACME validation.
cat > "$site" <<'NGINX'
server {
    listen 80;
    server_name 57.130.61.152;
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/time-manager-acme;
        default_type text/plain;
        try_files $uri =404;
    }
    location /api/ {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location / {
        proxy_pass http://127.0.0.1:5173;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX
nginx -t
systemctl reload nginx
certbot=(docker run --rm
  -v /etc/letsencrypt:/etc/letsencrypt
  -v /var/lib/letsencrypt:/var/lib/letsencrypt
  -v /var/log/letsencrypt:/var/log/letsencrypt
  -v /var/www/time-manager-acme:/var/www/time-manager-acme
  "$image" certonly --non-interactive --agree-tos --register-unsafely-without-email
  --required-profile shortlived --webroot -w /var/www/time-manager-acme
  --ip-address 57.130.61.152 --cert-name time-manager)
"${certbot[@]}" --staging --config-dir /etc/letsencrypt/time-manager-staging --work-dir /var/lib/letsencrypt/time-manager-staging --logs-dir /var/log/letsencrypt/time-manager-staging
"${certbot[@]}"
openssl x509 -in /etc/letsencrypt/live/time-manager/cert.pem -noout -checkip 57.130.61.152

cp "$source_dir/ops/nginx-time-manager-https.conf" "$site"
nginx -t
systemctl reload nginx
curl --fail --silent --show-error --resolve 57.130.61.152:443:127.0.0.1 https://57.130.61.152/login >/dev/null

# Recreate only frontend/backend using their current images; do not touch DB services.
cp "$source_dir/docker-compose.secure.yml" "$repo/docker-compose.secure.yml"
cp "$source_dir/docker-compose.https.yml" "$repo/docker-compose.https.yml"
cd "$repo"
docker compose -f docker-compose.secure.yml -f docker-compose.https.yml config --quiet
app_changed=true
docker compose -f docker-compose.secure.yml -f docker-compose.https.yml up -d --no-deps --no-build backend frontend
ready=false
for attempt in $(seq 1 30); do
  status=$(curl --silent --output /dev/null --write-out '%{http_code}' --resolve 57.130.61.152:443:127.0.0.1 https://57.130.61.152/api/auth/me || true)
  if [[ "$status" == 401 ]]; then ready=true; break; fi
  sleep 2
done
[[ "$ready" == true ]] || { echo 'HTTPS API readiness failed.'; exit 1; }
[[ $(docker exec time_manager_backend printenv SECURE_COOKIES) == true ]]
for container in time_manager_backend time_manager_frontend; do
  bindings=$(docker inspect "$container" --format '{{range .NetworkSettings.Ports}}{{range .}}{{.HostIp}}{{"\n"}}{{end}}{{end}}')
  if printf '%s\n' "$bindings" | grep -v '^$' | grep -Fxv 127.0.0.1; then
    echo 'Unexpected public app binding.'
    exit 1
  fi
done
printf '%s\n' "$image" > /etc/time-manager-certbot-image
chmod 600 /etc/time-manager-certbot-image
install -m 755 "$source_dir/ops/time-manager-cert-renew.sh" /usr/local/sbin/time-manager-cert-renew
install -m 644 "$source_dir/ops/time-manager-cert-renew.service" /etc/systemd/system/
install -m 644 "$source_dir/ops/time-manager-cert-renew.timer" /etc/systemd/system/
systemctl daemon-reload
/usr/local/sbin/time-manager-cert-renew --dry-run
systemctl enable --now time-manager-cert-renew.timer
trap - EXIT
echo "HTTPS enabled; configuration backup: $backup"
echo 'Verify external TLS trust, Secure/HttpOnly cookies, login/logout and renewal timer.'
