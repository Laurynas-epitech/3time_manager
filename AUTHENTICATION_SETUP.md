# Authentication integration and deployment

Local main now includes GitHub authentication PR #2 plus integration fixes. PostgreSQL administrator credentials and application login credentials are different.

## Verified behavior

27 backend tests pass (revalidated with mix precommit on October 8, 2026). Browser checks cover registration, login/logout, protected pages, session reload, HttpOnly JWT, missing-CSRF rejection, role promotion/demotion, and team creation. Tests use isolated staging, never the production database. Existing user data was retained while migrating a copy of a daily backup. Existing users get the employee role; passwords are never fabricated or silently assigned. An administrator must set their first password via the user update API, or they can use a new registered test account.

The secured Compose uses the existing secure volume and limited application database role. Migration and admin initialization run separately with administrator DB access. The long-running backend receives only the application DB password and JWT signing secret. No default administrator password or signing key is deployed, and deployment SQL debug logging is disabled. Duplicate membership adds are idempotent; demoted managers lose team-membership control; logout requires the JWT and matching CSRF header.

The built frontend serves static Vue assets, handles SPA deep links, and proxies /api to the backend on the internal network. This avoids cross-origin authentication on the existing port-80 public URL. Local npm development can still target port 4000 via src/api.js or VITE_API_URL.

## Production deployment completed — October 8, 2026

The prepared `ops/deploy-theme05.sh` takes a fresh backup, retains old source and running image IDs, creates private JWT/admin-login secrets, applies the four additional migrations, provisions admin@timemanager.local, grants only the new application table/sequence permissions, and restarts frontend/backend without recreating the database. The existing incident database stays stopped. It never removes volumes or orphans.

After approval, copy the script into the separate staging directory and run on OVH:

```sh
sudo bash /home/ubuntu/theme05-integrated/ops/deploy-theme05.sh admin@timemanager.local
```

It uses already tested `time-manager-theme05-integrated-backend` / `time-manager-theme05-integrated-frontend` images. Check it against current state before executing if there are subsequent edits. Secrets generated during deployment live in `/home/ubuntu/3time_manager/.secrets/jwt_secret` and `application_admin_password`, mode 600. Do not send them to logs/Git. Administrator email was selected by the owner for testing. Production application-admin and JWT secrets have been generated and deployed. Staging used a separate temporary account.

To retrieve the administrator login password after deployment from PowerShell:

```powershell
ssh -i .\time ubuntu@57.130.61.152 "sudo cat /home/ubuntu/3time_manager/.secrets/application_admin_password"
```

Post-deployment checks: anonymous API requests return 401; login cookie and CSRF work through the public UI; administrator can manage roles/teams; employee cannot access other users; DB has no public port; limited application role cannot perform DDL; daily backup still succeeds with new tables. Do not call the deployment complete before these checks pass.

## Rollback

Deployment retains old images and source under `/var/backups/time-manager-auth-deploy-<UTC timestamp>/`. If app rollback is necessary, use its `rollback-images.yml` with secured Compose and --no-build:

```sh
sudo docker compose -f docker-compose.secure.yml \
  -f /var/backups/time-manager-auth-deploy-<timestamp>/rollback-images.yml \
  up -d --no-deps --no-build backend frontend
```

This restores the old application (including its lack of auth) without dropping or reverting the database. Do not restore a database dump or run down migrations without separate approval. Disable public access first if authentication rollback would expose user data.

## Remaining limits

The current public endpoint is HTTP. HTTPS is still required before real credentials or sensitive employee data are used; secure-cookie mode must accompany HTTPS. Cookie logout clears the browser session but does not invalidate a previously copied JWT before its 24-hour expiry. Off-server automated backups and failure alerts remain outstanding. Changes are being published through the Theme 05 review branch; the preserved pre-integration stash is retained as an extra recovery point.

## Live verification results

Owner approved and deployment completed October 8, 2026. Login: http://57.130.61.152/login. Administrator email: admin@timemanager.local. Retrieve its password using the PowerShell command above; this is an application password, not the PostgreSQL password.

Pre-deploy backup completed. Rollback evidence: `/var/backups/time-manager-auth-deploy-20261008T113112Z/`. Four auth migrations applied; now 7 migrations total. Existing users/time/clock records preserved, and users assigned employee role without inventing passwords. Existing pre-auth users need their first password set before they can log in.

Live API verification passed: admin login, HttpOnly cookie, anonymous/missing-CSRF 401, employee 403 boundaries, manager team access, repeated membership, manager demotion and logout. Temporary accounts/teams removed. Public browser verification passed: registration, login/logout, profile deep links, reload, page restriction and HttpOnly cookie; temporary account removed.

Post-deployment backup `time_manager_dev-20261008T113342239577Z.dump` passed checksum and isolated restore with matching counts: 7 migrations, 2 users, 1 working-time record, 4 clocks. Application DB role can read roles but cannot write roles, create tables, or access schema_migrations. Backend does not receive DB admin password. Secret modes 600 confirmed; PostgreSQL has no published host port; original incident database remains stopped. Daily backup timer remains enabled at 03:00 Europe/Paris.

Temporary staging/test containers were retired after verification. Source, tests and rollback images retained. No commits or GitHub pushes performed.
