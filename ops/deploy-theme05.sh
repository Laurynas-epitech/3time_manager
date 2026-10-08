#!/usr/bin/env bash
# Run only after owner approves the reviewed authentication deployment.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.'; exit 1; }
repo=/home/ubuntu/3time_manager
stage=/home/ubuntu/theme05-integrated
admin_email=${1:?Pass the approved administrator email}
cd "$repo"
docker inspect time_manager_db_secure >/dev/null
docker image inspect time-manager-theme05-integrated-backend time-manager-theme05-integrated-frontend >/dev/null
docker inspect time_manager_db_secure --format '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}' | grep -Fx time_manager_postgres_secure_20261008 >/dev/null
[[ $(docker inspect time_manager_db --format '{{.State.Running}}') == false ]] || { echo 'Incident DB must remain stopped.'; exit 1; }
/usr/local/sbin/time-manager-backup
stamp=$(date -u +%Y%m%dT%H%M%SZ)
evidence=/var/backups/time-manager-auth-deploy-$stamp
install -d -m 700 "$evidence"
tar --exclude='.secrets' --exclude='.env*' --exclude='node_modules' --exclude='_build' --exclude='deps' -czf "$evidence/source-before-auth.tar.gz" backend frontend docker-compose.secure.yml
docker tag "$(docker inspect time_manager_backend --format '{{.Image}}')" "time-manager-before-auth-backend:$stamp"
docker tag "$(docker inspect time_manager_frontend --format '{{.Image}}')" "time-manager-before-auth-frontend:$stamp"
python3 - <<'PY'
import secrets, os
from pathlib import Path
root=Path('/home/ubuntu/3time_manager/.secrets')
for name in ('jwt_secret', 'application_admin_password'):
    p=root/name
    if p.exists():
        if p.is_symlink() or p.stat().st_uid != 0:
            raise RuntimeError('Unexpected secret path or owner')
        continue
    fd=os.open(p,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    with os.fdopen(fd,'w') as f:
        f.write(secrets.token_hex(32)+'\n')
PY
migration=(docker run --rm --network 3time_manager_default
  --mount "type=bind,src=$repo/.secrets/db_admin_password,dst=/run/secrets/db_admin_password,readonly"
  --mount "type=bind,src=$repo/.secrets/jwt_secret,dst=/run/secrets/jwt_secret,readonly"
  --mount "type=bind,src=$repo/.secrets/application_admin_password,dst=/run/secrets/application_admin_password,readonly"
  -e MIX_ENV=dev -e DB_USERNAME=postgres -e DB_PASSWORD_FILE=/run/secrets/db_admin_password
  -e DB_HOST=db_secure -e DB_NAME=time_manager_dev -e JWT_SECRET_FILE=/run/secrets/jwt_secret)
"${migration[@]}" time-manager-theme05-integrated-backend mix ecto.migrate
"${migration[@]}" -e "ADMIN_EMAIL=$admin_email" -e ADMIN_PASSWORD_FILE=/run/secrets/application_admin_password time-manager-theme05-integrated-backend mix run priv/repo/seeds.exs
docker exec time_manager_db_secure psql -U postgres -d time_manager_dev -v ON_ERROR_STOP=1 -c 'GRANT SELECT ON roles TO time_manager_app; GRANT SELECT, INSERT, UPDATE, DELETE ON teams, team_users TO time_manager_app; GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO time_manager_app;'
# Preserve originals in the archive; synchronize reviewed source only.
cp -a "$stage/backend/." "$repo/backend/"
cp -a "$stage/frontend/." "$repo/frontend/"
cp "$stage/docker-compose.secure.yml" "$repo/docker-compose.secure.yml"
# Remove only obsolete tracked files removed by the reviewed upstream authentication commit.
for obsolete in backend/test/time_manager/time_tracking_test.exs backend/test/time_manager_web/controllers/user_controller_test.exs backend/test/time_manager_web/controllers/working_time_controller_test.exs frontend/src/components/user.vue frontend/src/components/HelloWorld.vue; do
  rm -f -- "$repo/$obsolete"
done
docker tag time-manager-theme05-integrated-backend 3time_manager-backend:latest
docker tag time-manager-theme05-integrated-frontend 3time_manager-frontend:latest
docker compose -f docker-compose.secure.yml config --quiet
cat > "$evidence/rollback-images.yml" <<YAML
services:
  backend:
    image: time-manager-before-auth-backend:$stamp
  frontend:
    image: time-manager-before-auth-frontend:$stamp
YAML
docker compose -f docker-compose.secure.yml up -d --no-deps --no-build backend frontend
echo "Deployment applied; rollback image override: $evidence/rollback-images.yml"
echo 'Verify login, anonymous 401, application privileges, public UI and daily backup before marking complete.'
