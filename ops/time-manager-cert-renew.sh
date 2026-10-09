#!/usr/bin/env bash
set -euo pipefail
image=$(cat /etc/time-manager-certbot-image)
docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -v /var/log/letsencrypt:/var/log/letsencrypt \
  -v /var/www/time-manager-acme:/var/www/time-manager-acme \
  "$image" renew --no-random-sleep-on-renew --cert-name time-manager "$@"
nginx -t
systemctl reload nginx
