# Security release — October 13, 2026

Deployed GitHub merge revision `87bc705e313c79c0ef8aab2619bc66dceaf441e0`
(PR #6) at [the HTTPS application](https://57.130.61.152).

## Release and preservation

- Source: `/home/ubuntu/time-manager-releases/security-87bc705`.
- Compose project: `3time_manager`, secured configuration plus HTTPS overlay.
- Exact trusted proxy peer: `172.18.0.1`, verified from the backend network gateway;
  persisted in the release's private `.env` configuration.
- Secrets remain in the existing private directory; the release references it
  through a symlink. No secret values were printed or committed.
- Backup: `/var/backups/time-manager-security-20261013T115856Z`, with pre-release
  database dump, original source/proxy/Compose configuration, retained image tags
  and `rollback-images.yml`. Daily backup succeeded before deployment.
- Only backend/frontend were recreated. The healthy clean database container and
  volume were preserved; the incident database stayed stopped. No migration added.
- Existing certificate remains trusted and valid through October 19, 2026 UTC.
  Backup and certificate-renewal timers remain active.

The old source directory had uncommitted deployment files and was preserved.
Archive extraction initially restricted public SVG permissions, preventing service
worker installation. Restoring archive file modes with `tar --same-permissions`
and rebuilding the frontend corrected this; subsequent offline checks passed.

## Live verification

- Trusted HTTPS login; HTTP 308 redirect to HTTPS.
- Browser registration/login/reload/logout; Secure/HttpOnly/SameSite=Lax JWT cookie;
  cookie inaccessible through page JS; missing CSRF rejected. Test account deleted.
- Anonymous API 401 and malformed JSON 400 retain `nosniff`; frontend hardening
  headers present. The two proxy layers currently emit duplicate identical frontend
  hardening headers; this did not prevent the verified browser/service-worker behavior.
- Controlled proxy test: 10 invalid login attempts for a reserved test client IP,
  then 429 with Retry-After; a second reserved client IP remained independently usable.
- Public proxy test: rotating supplied X-Real-IP did not evade the auth limit.
  These were bounded invalid-login checks, not a load/flooding test.
- Direct backend diagnostic/sensitive paths returned 404; app ports remain bound
  to 127.0.0.1:4000 and 127.0.0.1:5173.
- 390px PWA offline reload/new tab, persistent attendance/history, cached period
  switching and automatic original-UUID/timestamp replay exactly once passed.
  Temporary account and attendance records were removed.

## Subsequent deployment commands

Use the release project name and persisted proxy configuration:

```sh
cd /home/ubuntu/time-manager-releases/security-87bc705
sudo docker compose -p 3time_manager --env-file .env \
  -f docker-compose.secure.yml -f docker-compose.https.yml \
  up -d --no-deps --build backend frontend
```

New revisions should use reviewed release directories, backups and appropriate
proxy settings; do not deploy by overwriting the preserved old source or recreating
database services. Do not remove volumes or the stopped incident container.

For application-image rollback, use the preserved old source configuration with
the explicit rollback image override:

```sh
cd /home/ubuntu/3time_manager
sudo docker compose -p 3time_manager \
  -f docker-compose.secure.yml -f docker-compose.https.yml \
  -f /var/backups/time-manager-security-20261013T115856Z/rollback-images.yml \
  up -d --no-deps --no-build backend frontend
```

Restore `nginx-before.conf` if reverting the proxy as well, validate with `nginx -t`
and reload Nginx. Rollback must retain HTTPS and the existing database. No database
restore is required for this application-only release.

Full penetration/load/interception and real-device/shared-device assessment,
copied-token revocation and host incident investigation remain open. These checks
establish the targeted release behavior, not universal security.
