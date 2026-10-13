# Automatic deployment — October 13, 2026

The existing workflow establishes `main` as the push/PR branch. This change retains
that policy: PRs validate only; a successful main push builds and publishes
SHA-tagged frontend/backend images to GHCR, then invokes the installed server
rollout command. Production deployments are serialized; stale main revisions are
rejected before uploading. No integration branch is automatically released.

The owner subsequently authorized provisioning and rollout. The main workflow
successfully published/deployed `215e8f8`; independent live checks, original-data
comparison and a disposable backup restore passed. See the
[release record](../validation/automatic-deployment-20261013.md). The original
preparation/provisioning instructions below remain the operating contract.

Provisioning requirements for a new host or replacement credentials:

- Repository/environment secrets `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`
  and pinned `DEPLOY_KNOWN_HOSTS`. Protect main and the production environment.
- A dedicated deployment SSH identity. Install the reviewed
  `ops/deploy-release.sh` root-owned as `/usr/local/sbin/time-manager-deploy`;
  grant sudo for that command only, without arbitrary shell or Docker access.
  The workflow never sudo-executes an uploaded script.
- Server read access to the two GHCR packages, preconfigured through the server's
  credential store if packages are private. GitHub's write token stays in CI.
- Root-owned mode-0600 `/etc/time-manager/release-smoke.json`, containing the
  trusted HTTPS origin, email/password of an explicitly approved fictional
  restricted manager, and its assigned `team_id`. Do not commit this file.
- Existing secure volume, stopped incident database, valid host TLS, secrets,
  database permissions and `/usr/local/sbin/time-manager-backup` as in the runbooks.

An environment with manual reviewers is gated deployment, not fully automatic.
Do not remove an existing approval rule without authorization. The pipeline cannot
be called complete until a real main push produces a successful deployment run.

The rollout locks the host, validates TLS/volume/configuration, saves previous image
IDs and new registry digests, runs the existing backup plus a custom-format database
dump/catalog check, explicitly migrates using database-admin credentials, starts
only the two application services, and runs trusted HTTPS authenticated report/clock
reads, cookie/CSRF and role-denial smoke checks. Trusted proxy peers are copied from
the running backend. Database services/volumes are not recreated.

On an application startup/smoke failure, previous compatible application images are
restored. The schema stays migrated. Releases and evidence are retained under
`/var/lib/time-manager/releases/<SHA>` and `/var/backups/time-manager-release-*`;
`/var/lib/time-manager/current` records the verified release. Future manual Compose
commands should use that release's secure/HTTPS/image configuration rather than
rebuilding older source from `/home/ubuntu/3time_manager`.

The required-field migration is transactional, additive, and compatible with the
previous application's valid writes. It takes PostgreSQL table locks; schedule it
for a low-traffic window. NULL legacy fields fail with an actionable preflight
error and no fabricated/deleted application data. Repair from verified source data,
then retry. Password/role legacy fields remain outside this migration. Downgrade
drops only the seven newly added NOT NULL constraints; the original clock-status
constraint and all foreign keys/cascade behavior remain. Overlaps and legacy
zero-duration clock sessions are retained. Manual writes require end > start;
same-second automatic clock pairs deliberately allow zero elapsed time.

The October 13 release establishes actual CI, image publication, successful rollout,
backup restore, live reporting and offline replay. An intentional failed-health
application rollback remains untested. The automatic smoke performs clock reads;
the separate live offline regression also verified punch/replay after this release.
The existing ubuntu identity is in use; a dedicated restricted identity is still a
future operational improvement.
