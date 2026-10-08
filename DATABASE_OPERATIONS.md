# Database operations after the October 8, 2026 cutover

The OVH application now uses a clean PostgreSQL 16 cluster. Deploy with:

```sh
cd /home/ubuntu/3time_manager
sudo docker compose -f docker-compose.secure.yml up -d --build
```

Do not use the old default Compose file on OVH: it contains malformed historical settings. Do not use `--remove-orphans`, `down -v`, or volume removal commands. The stopped `time_manager_db` container and `3time_manager_postgres_data` volume are incident evidence; never restart or write to them during normal deployment.

Active database: `time_manager_db_secure`, hostname `db_secure`, database `time_manager_dev`, external volume `time_manager_postgres_secure_20261008`. PostgreSQL has no host port. The backend uses the `time_manager_app` role, limited to SELECT/INSERT/UPDATE/DELETE on users, workingtime, clocks, and sequence usage. It cannot create roles, databases, tables, or operate on schema_migrations. Future tables require explicit grants after administrator migrations; this is intentional.

Distinct random passwords are stored only on OVH in `.secrets/db_admin_password` and `.secrets/db_app_password` (directory 700, files 600). Use sudo for Compose because secret source files are root-only. The backend mounts only the application password. Keep these files out of Git, images, logs, and incident downloads. Local copies of this Compose configuration need their own securely generated password files and an explicitly created empty secure volume before first use. Never reuse an incident volume for initialization.

For reviewed migrations, use the administrator password only in a temporary migration container, not in the long-running backend:

```sh
sudo docker compose -f docker-compose.secure.yml build backend
sudo docker run --rm --network 3time_manager_default \
  --mount type=bind,src=/home/ubuntu/3time_manager/.secrets/db_admin_password,dst=/run/secrets/db_admin_password,readonly \
  -e MIX_ENV=dev -e DB_USERNAME=postgres \
  -e DB_PASSWORD_FILE=/run/secrets/db_admin_password \
  -e DB_HOST=db_secure -e DB_NAME=time_manager_dev \
  3time_manager-backend mix ecto.migrate
```

Then review and grant application permissions only on any newly added application tables/sequences. Tables and database remain administrator-owned; application credentials must not be used for migrations.

Verification after cutover: all three migrations applied; API user CRUD passed with the temporary verification user removed; application DDL, role creation, and migration-table reads were denied; old cluster stopped with restart policy disabled. Passwords on the stopped compromised cluster were not modified: access was retired by stopping that cluster, rather than attempting to repair its abnormal duplicate postgres roles. Its incident archive remains preserved.

Authentication/authorization and scheduled, tested backups were subsequently implemented; see AUTHENTICATION_SETUP.md for the deployment record. HTTPS, host-compromise assessment, independent off-server automated backups, and failure alerts remain outstanding. This does not establish that the host itself is trusted.

## Automated daily backups

Installed on OVH: `/usr/local/sbin/time-manager-backup`, `time-manager-backup.service`, and `time-manager-backup.timer`. Source definitions are tracked under `ops/` (currently uncommitted).

Schedule: daily at 03:00 Europe/Paris (DST aware). Persistent timer runs a missed backup after the server comes back online. Keeps the latest 30 successful custom-format PostgreSQL dumps and SHA-256 checksum files in `/var/backups/time-manager-daily/`. Directory 700; files 600. Retention affects only this dedicated daily directory and precisely named daily backup files; incident archives are excluded. Failed dumps are never retained as successful backups; previous completed backups remain available. Successful jobs log the filename and size, not database contents or passwords. Failures appear in the systemd journal; external failure alerts are not configured.

On the OVH server:

```sh
# Next scheduled run
sudo systemctl list-timers time-manager-backup.timer --all

# Recent results (successful oneshot service is normally inactive afterward)
sudo journalctl -u time-manager-backup.service -n 20 --no-pager

# Run an extra backup now
sudo systemctl start time-manager-backup.service

# List backups
sudo ls -lh /var/backups/time-manager-daily/
```

From Windows PowerShell, prefix a server command with:

```powershell
ssh -i .\time ubuntu@57.130.61.152 "sudo systemctl list-timers time-manager-backup.timer --all"
```

Initial backup on October 8, 2026 passed checksum verification and restored into a disposable PostgreSQL 16 container using `--network none` and tmpfs storage. Verified three migrations, all application tables, and limited-role ACLs; restored counts were users=1, workingtime=0, clocks=0. The temporary container was removed. The live database and original incident volume were not used as restore targets.

Dumps include application schema, data, and permissions, but not cluster-wide role passwords. Provision roles/secrets separately before a real restore. Existing administrator and application password files must be retained securely outside Git. PostgreSQL dump format documentation: https://www.postgresql.org/docs/16/app-pgdump.html

These automated backups are stored on the same OVH host as the application. Independent off-server backup storage and automatic failure notifications remain outstanding; server loss can remove both the live database and these daily backups. Do not treat same-server copies as protection against host loss. Inspect any future restore only on a separate trusted cluster before authorizing a production restore.
