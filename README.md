# Time Manager

Employee attendance and working-time management with a Vue 3 PWA, Phoenix/Elixir
JSON API and PostgreSQL 16.

Employees clock in/out and view their own working history and daily/weekly hours.
Managers view assigned teams and manage working times. Administrators manage
accounts, roles, teams and initial assignments. Attendance recorded offline after
an online visit synchronizes automatically with its original timestamp.

## Repository

| Folder | Contents |
|---|---|
| `frontend/` | Vue interface, offline storage/synchronization and browser tests |
| `backend/` | Phoenix API, permissions, schemas, migrations and ExUnit tests |
| `docs/` | Features, security, testing, operational guides and dated validation |
| `ops/` | Deployment, Nginx, certificate-renewal and database-backup scripts |
| `.github/workflows/` | Frontend/backend checks and Docker image builds |

## Local setup

Requires Docker with Compose. Generate a private JWT signing secret before starting
the development configuration.

PowerShell:

```powershell
$jwtBytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($jwtBytes)
$env:JWT_SECRET = [Convert]::ToBase64String($jwtBytes)
```

Bash:

```sh
export JWT_SECRET="$(openssl rand -base64 32)"
```

From the repository root:

```sh
docker compose build
docker compose up -d db
docker compose run --rm backend mix ecto.migrate
docker compose up -d backend frontend
```

Open [localhost:5173](http://localhost:5173) and register an employee account.
The frontend proxies `/api`; the backend host port is bound to loopback. Development
uses local demonstration database credentials and a persistent Docker volume. Hosted
installations use the separate secured deployment guides.

For an administrator, set `ADMIN_PASSWORD` in your shell to a private password of
at least eight characters, then run:

```sh
docker compose run --rm -e ADMIN_EMAIL=admin@example.invalid -e ADMIN_PASSWORD backend mix run priv/repo/seeds.exs
```

There is no default administrator password. Database credentials and application
login credentials are separate.

## Documentation and verification

- [Documentation index](docs/README.md)
- [Security and release checks](docs/security.md)
- [Tests and recorded results](docs/testing.md)
- [Offline attendance](docs/features/offline.md)
- [Known limitations](docs/limitations.md)
- [Authentication operations](docs/operations/authentication.md),
  [database operations](docs/operations/database.md),
  [HTTPS operations](docs/operations/https.md)

Latest local checks, October 13, 2026: 61 backend tests, four pagination tests,
three reporting tests, production/PWA build, required-route/chart browser checks,
targeted security browser checks, migration checks and offline regression passed.
Revision `215e8f8` was deployed through the successful main workflow after authorized
host/secret provisioning. Live reporting, charts, HTTPS/authentication, offline replay,
database preservation and a disposable backup restore passed; see the
[automatic release record](docs/validation/automatic-deployment-20261013.md). See the
[requirement report](docs/validation/remediation-verification-20261013.md) and
[deployment runbook](docs/operations/automatic-deployment.md) for operation and
remaining verification boundaries.
