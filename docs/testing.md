# Testing and verification

## Backend

Use Elixir 1.17, Erlang/OTP 27 and disposable PostgreSQL 16 on localhost:5432.
`config/test.exs` uses username/password `postgres`, creates/migrates
`time_manager_test`, and supports a `MIX_TEST_PARTITION` database suffix. Never use
production data. From `backend/`:

```sh
mix deps.get
MIX_ENV=test mix precommit
```

PowerShell: set `$env:MIX_ENV = 'test'` before `mix precommit`. The alias compiles
with warnings-as-errors, checks unused dependencies, formats code and runs ExUnit.
Tests cover auth, permissions, proxy trust, membership eligibility, bounded member
queries, write/input limits and parser error headers.

## Frontend

From `frontend/`, with Node.js 20 or newer:

```sh
npm ci
npm run test:security
npm run build
```

Pagination tests cover complete multi-page downloads, time ordering, boundaries and
failure handling. `npm audit` queries the advisory registry. Windows users can use
`npm.cmd` when script policy blocks `npm.ps1`.

## Browser checks

Start an updated backend on localhost:4000 with a separate disposable development
database. Apply migrations as described in the [local setup](../README.md).
Build the frontend, then start its preview in a separate terminal:

```sh
npm run preview -- --host 127.0.0.1 --port 5173 --strictPort
```

The preview proxies `/api` to the backend. Install a browser and run:

```sh
npx playwright install chromium
npm run test:offline
node tests/security-browser.cjs
```

Alternatively set `BROWSER_EXECUTABLE_PATH` to an installed Chromium/Edge executable.
The security script permits only localhost targets and deletes its temporary account.
The offline script creates accounts/attendance and retains conflict fixtures: discard
its test database afterward. Neither script should run against production.

- Offline: 390px viewport, offline reopening, persistent queue/history, cross-tab
  state, FIFO/original timestamps, duplicate retries, expiry/account isolation,
  conflict retention and offline logout.
- Security: stored SVG/script/HTML values render as text at 390px/1440px; JWT is
  HttpOnly and absent from page-readable storage; SQL-style filter input, role
  escalation and missing CSRF fail; selected backend configuration/diagnostic paths
  return 404.

## Recorded local results — October 13, 2026

| Check | Result |
|---|---|
| `mix precommit` | 42 tests, zero failures |
| Pagination tests | Four passed |
| Production/PWA build | Passed, service worker generated |
| Offline browser regression | Passed in Edge at 390px |
| Targeted security browser checks | Passed in Edge at 390px/1440px |
| Frontend Nginx syntax / secured Compose configuration | Passed |
| Frontend advisory audit | Zero reported vulnerabilities |

Backend checks used disposable Docker/PostgreSQL. Dependency compilation emitted two
Phoenix dependency warnings; project warnings-as-errors compilation passed. Results
precede the documentation organization, which changes no application behavior.

GitHub CI runs frontend build, backend tests and Docker image builds for main pushes
and pull requests to main. These local results do not establish fresh CI, deployment,
comprehensive pentest/load assessment or real-device usability.
