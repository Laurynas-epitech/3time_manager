#!/usr/bin/env bash
# Prepared automatic release; host provisioning and production authorization are separate.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo'; exit 1; }
bundle=${1:?bundle}; sha=${2:?SHA}; image_root=${3:?registry image root}
[[ $sha =~ ^[0-9a-f]{40}$ && $image_root =~ ^ghcr.io/[a-z0-9_.-]+/[a-z0-9_.-]+$ ]] || exit 1
[[ $bundle == /tmp/time-manager-$sha.tar.gz && -f $bundle && ! -L $bundle ]] || { echo 'Unexpected release bundle'; exit 1; }
exec 9>/var/lock/time-manager-deploy.lock
flock -x 9
repo=/home/ubuntu/3time_manager
release=/var/lib/time-manager/releases/$sha
evidence=/var/backups/time-manager-release-$(date -u +%Y%m%dT%H%M%SZ)-$sha
[[ ! -e $release ]] || { echo 'Release directory exists; inspect the previous attempt before retrying'; exit 1; }
test -s /etc/time-manager/release-smoke.json
test -x /usr/local/sbin/time-manager-backup
docker inspect time_manager_db_secure >/dev/null
volume=$(docker inspect time_manager_db_secure --format '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}')
[[ $volume == time_manager_postgres_secure_20261008 ]] || { echo 'Unexpected database volume'; exit 1; }
[[ $(docker inspect time_manager_db --format '{{.State.Running}}') == false ]] || { echo 'Incident database must stay stopped'; exit 1; }
nginx -t
install -d -m 700 "$release" "$evidence"
tar -xzf "$bundle" -C "$release"
ln -s "$repo/.secrets" "$release/.secrets"
docker inspect time_manager_backend --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n '/^TRUSTED_PROXY_IPS=/p' > "$release/release.env"
for service in backend frontend; do
  docker pull "$image_root-$service:$sha"
  docker inspect "time_manager_$service" --format '{{.Image}}' > "$evidence/previous-$service"
  docker image inspect "$image_root-$service:$sha" --format '{{json .RepoDigests}}' > "$evidence/digest-$service"
done
cat > "$release/images.yml" <<YAML
services:
  backend:
    image: $image_root-backend:$sha
  frontend:
    image: $image_root-frontend:$sha
YAML
cat > "$evidence/rollback.yml" <<YAML
services:
  backend:
    image: $(cat "$evidence/previous-backend")
  frontend:
    image: $(cat "$evidence/previous-frontend")
YAML
compose=(docker compose --env-file "$release/release.env" --project-name 3time_manager -f "$release/docker-compose.secure.yml" -f "$release/docker-compose.https.yml")
"${compose[@]}" -f "$release/images.yml" config --quiet
/usr/local/sbin/time-manager-backup
docker exec time_manager_db_secure pg_dump -U postgres -d time_manager_dev -Fc > "$evidence/database.dump"
test -s "$evidence/database.dump"
docker exec -i time_manager_db_secure pg_restore --list < "$evidence/database.dump" > "$evidence/backup-catalog.txt"
tar --exclude='.secrets' --exclude='.env*' --exclude='node_modules' --exclude='_build' --exclude='deps' -czf "$evidence/source-before.tar.gz" -C "$repo" backend frontend docker-compose.secure.yml docker-compose.https.yml
# Additive NOT NULL migration: older images remain compatible after a successful migration.
# A failed preflight is transactional and stops the rollout without modifying application services.
docker run --rm --network 3time_manager_default \
  --mount "type=bind,src=$repo/.secrets/db_admin_password,dst=/run/secrets/db_admin_password,readonly" \
  --mount "type=bind,src=$repo/.secrets/jwt_secret,dst=/run/secrets/jwt_secret,readonly" \
  -e MIX_ENV=dev -e DB_USERNAME=postgres -e DB_PASSWORD_FILE=/run/secrets/db_admin_password \
  -e DB_HOST=db_secure -e DB_NAME=time_manager_dev -e JWT_SECRET_FILE=/run/secrets/jwt_secret \
  "$image_root-backend:$sha" mix ecto.migrate
rollback() {
  echo 'Release failed; restoring previous compatible application images. Schema is retained.'
  "${compose[@]}" -f "$evidence/rollback.yml" up -d --no-deps --no-build backend frontend
}
trap rollback ERR
"${compose[@]}" -f "$release/images.yml" up -d --no-deps --no-build backend frontend
python3 "$release/ops/release-smoke.py" /etc/time-manager/release-smoke.json
[[ $(docker inspect time_manager_db_secure --format '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}') == "$volume" ]]
printf '%s\n' "$sha" > "$evidence/revision"
ln -sfn "$release" /var/lib/time-manager/current
trap - ERR
echo "Release verified: $sha; evidence: $evidence"
