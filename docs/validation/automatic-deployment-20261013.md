# Authorized automatic release — October 13, 2026

The owner explicitly authorized host provisioning and deployment after the GitHub
secret setup. [Main workflow 38445232601](https://github.com/Laurynas-epitech/3time_manager/actions/runs/38445232601),
attempt 4, completed successfully for `215e8f82da1443912fb47762aaef8ee4fc352a1e`.
Frontend build/reporting/pagination, backend checks, both Docker builds, GHCR
publication and the deployment job passed. Rollout verified at 20:25 Europe/Paris
(18:25 UTC). No manual approval gate was added or removed.

## Provisioning and corrected configuration

Installed the reviewed root-owned rollout command at
`/usr/local/sbin/time-manager-deploy` after a successful backup. Its SHA-256 is
`413c53708f21ea8e8a1eedc832b1c9a927bf95071c4a3638bbc2bacb37bb0518`.
The existing `ubuntu` account/key is used; a separate restricted deployment identity
remains an operational improvement, not a claimed completed permission restriction.

Created a clearly labelled fictional verification team with one manager and three
employee fixtures. These four isolated accounts and three known working-time rows
are retained for subsequent automatic read-only release smoke tests. Root-only
mode-0600 `/etc/time-manager/release-smoke.json` holds their random credentials.
Credentials are absent from repository, reports and tool output. No existing user
was promoted or reassigned.

Attempts before completion failed because `DEPLOY_KNOWN_HOSTS` was absent and the
private-key secret was malformed. Saved the host key only after matching the owner's
verified fingerprint `SHA256:3G1n0tHqk4F1nABESz2osst6VRKTE2aPeiBSePh/Yc0`.
Encrypted the existing working SSH key directly into the production secret with
normalized line endings. No SSH key rotation, host-check bypass or secret exposure.
An initial provisioning helper could not rewrite a user-owned `/tmp` file under
Linux's protection; atomic root-owned installation corrected that before mutation.

## Release evidence

| Item | Observed result |
|---|---|
| Release directory | `/var/lib/time-manager/releases/215e8f82da1443912fb47762aaef8ee4fc352a1e`; `/var/lib/time-manager/current` resolves to it |
| Backend digest | `sha256:8b899af7b79b932a9db8c6903d33fbe991abb401d5a7562fdd1323112c1a07ea` |
| Frontend digest | `sha256:59bd9ad09a22dc5737e6a3d00f5a530d1bf3317917bff4fc41b7a1cb36848032` |
| Evidence directory | `/var/backups/time-manager-release-20261013T182502Z-215e8f82da1443912fb47762aaef8ee4fc352a1e` |
| Migration | `20261013162124` applied successfully; all eight required field catalog entries are NOT NULL, including the original status constraint |
| Database preservation | Original secure DB container ID and `time_manager_postgres_secure_20261008` volume unchanged; incident database remains stopped |
| Original data | Every original users/clocks/workingtime/teams/team_users row matches the pre-provisioning backup; restored counts 9/140/66/3/6 respectively |
| Restore | Restored `time_manager_dev-20261013T182021557522Z.dump` into a new disposable database, compared original rows, and removed only that verification DB |
| Backup SHA-256 | `69b579f8033da3574a2cfbcfda12b63039423717f9edc555d87e309e00bebddd` |

`independent-server-verification.json` in the evidence directory records container,
image, restore and catalog results. The rollout also saved its own pre-release dump,
catalog, previous image references and source archive. Application-image rollback is
prepared; an intentional failed-health rollout/recovery was **not exercised**.

## Independent live verification

- Trusted HTTPS, HTTP 308 redirect, anonymous API 401, Secure/HttpOnly JWT, CSRF and
  manager/employee role denial passed.
- Fictional three-member team produced independently expected daily averages
  **4h and 2h**, team total **18h**, and partial-week average **6h/member**.
- Daily bar, weekly line and weekday pie rendered/configured at 390px and 1440px;
  selected-user table total **14h**, required direct routes, chart reload and exact UTC
  working-time table passed with zero page errors.
- Live 390px offline reload/new-tab history persisted; reconnect automatically
  uploaded the original UUIDs/timestamps exactly once. Its temporary account and
  all related attendance were removed afterward.

The commands were the retained `live-remediation-check.cjs`,
`theme05-browser-check/ovh-integration-check.cjs` and `verify-release-server.py` in
ignored local artifacts, using only fictional fixture data. Private local fixture
copies are removed after verification; protected server fixtures remain for CI.

Whole-app offline reads, full accessibility/physical-device checks, broader security
assurance and optional JWT revocation remain outside these successful release checks.
Theme 04 stays excluded. The earlier requirement report's local-only deployment
labels are superseded by this authorized release where identified.
