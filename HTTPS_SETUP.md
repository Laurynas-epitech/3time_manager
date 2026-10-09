# HTTPS for 57.130.61.152

## OVH cutover

Run `ops/enable-https.sh` only on the reviewed OVH host after owner approval. It configures host Nginx for the existing IP address and obtains a publicly trusted Let's Encrypt short-lived certificate. Certbot is version 5.8.0; its downloaded image digest is pinned for renewal. ACME registration accepts the CA subscriber agreement without submitting an email address. Certificates are public and the IP is submitted to Let's Encrypt for validation.

The script first requests a staging certificate, then a trusted production certificate. Port 80 must remain externally accessible for HTTP-01 validation; port 443 must be allowed by the OVH security group. It backs up the current Nginx and secured Compose configuration before changes, tests Nginx before reloading, and recreates only frontend/backend using existing images. It never migrates or recreates either database. Failed cutover attempts restore the prior app/proxy configuration and keep evidence/certificates for diagnosis.

The HTTPS Compose overlay enables Secure JWT cookies. The base secured Compose binds backend/frontend ports to localhost, so public access goes through Nginx. HTTP redirects to the fixed HTTPS address, except the ACME challenge path. Nginx provides forwarded scheme/client headers directly to the API. Certificate/private-key files stay on the server, outside Git.

## Deployment after cutover

Always include the HTTPS overlay:

```sh
cd /home/ubuntu/3time_manager
sudo docker compose -f docker-compose.secure.yml -f docker-compose.https.yml up -d --build
```

Using only the base Compose disables Secure-cookie mode. Do not run legacy deployment scripts without reviewing their Compose invocations. No volumes or orphans should be removed.

## Renewal

The IP certificate lasts approximately six days. `time-manager-cert-renew.timer` checks every four hours with a random delay of up to 15 minutes. Renewal uses the same HTTP webroot and pinned Certbot image, then validates/reloads host Nginx. The setup runs a staging renewal dry run before enabling the timer.

```sh
sudo systemctl list-timers time-manager-cert-renew.timer --all
sudo journalctl -u time-manager-cert-renew.service -n 30 --no-pager
sudo /usr/local/sbin/time-manager-cert-renew --dry-run
sudo openssl x509 -in /etc/letsencrypt/live/time-manager/cert.pem -noout -dates -ext subjectAltName
```

External expiry/failure notifications are not implemented. Monitor the timer/journal and update the Certbot image deliberately as security fixes become available.

## Validation and rollback

Verify a trusted TLS connection to `https://57.130.61.152/login`, HTTP redirect, anonymous API 401, Secure/HttpOnly JWT cookie, CSRF enforcement, login/logout, and loopback-only application bindings. Existing HTTP login sessions should be cleared by logging out and signing in again over HTTPS; localStorage is specific to each origin.

Configuration backups are in `/var/backups/time-manager-https-<UTC timestamp>/`. Restore its `nginx-before.conf` and `docker-compose.secure.yml`, then recreate only backend/frontend with `--no-deps --no-build` using the base Compose and validate/reload Nginx. This returns to the prior HTTP deployment; it does not restore data or undo migrations. The HTTPS overlay and certificate-installation files may remain after a failed attempt, so inspect before retrying. Do not expose real credentials over a rolled-back HTTP deployment.

## Sources

- [Let's Encrypt IP-address certificates and renewal requirements](https://letsencrypt.org/2026/03/11/shorter-certs-certbot)
- [Certbot Docker installation](https://eff-certbot.readthedocs.io/en/stable/install.html)
- [Certbot user guide](https://eff-certbot.readthedocs.io/en/stable/using.html)

## October 9, 2026 deployment evidence

- Owner requested "do https", superseding the earlier HTTPS deferral.
- OVH now serves trusted TLS at https://57.130.61.152/login; external curl verified HTTPS 200, HTTP 308 redirect, and anonymous HTTPS API 401 without bypassing certificate checks.
- Browser validation (`../_local_artifacts/theme05-browser-check/https-check.cjs`) passed registration/login/reload/logout, Secure/HttpOnly/SameSite=Lax JWT cookie and CSRF enforcement. Its temporary account was deleted after verification.
- App bindings are now 127.0.0.1:4000 and 127.0.0.1:5173. The clean database container/volume stayed in place; the incident database remains stopped. No database migration or application rebuild occurred.
- Rollback configuration backup: `/var/backups/time-manager-https-20261009T140237Z/`.
- Current certificate expires October 16, 2026 at 07:04:23 Europe/Paris (05:04:23 UTC).
- Renewal wrapper now uses `--no-random-sleep-on-renew`; the timer supplies the randomized delay. The initial dry run was already sleeping under the previous wrapper when this improvement was installed. Its simulated renewal succeeded and Nginx validation/reload passed; the four-hour renewal timer is enabled and active.
- The subsequent October 9 offline application release rebuilt frontend/backend and applied the UUID migration. Live offline reopening and automatic synchronization passed; see OFFLINE_SETUP.md.

Status: HTTPS deployed, trusted TLS/browser checks passed, renewal dry run passed and automatic renewal timer enabled/active. The subsequent offline application release is also deployed and verified.
