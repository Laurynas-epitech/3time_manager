# Offline attendance

Implemented October 9, 2026. This is offline support for the existing Vue web app/PWA, not a separate native mobile application.

## Behavior

- Visit online and sign in once to download the app interface, your profile and attendance history.
- After the service worker finishes caching, the same URL can reopen offline, including after closing the tab. A first visit without connectivity cannot work.
- Your clock-in/out events and completed sessions are stored in IndexedDB. The interface shows pending actions and synchronization progress.
- Queued events keep their original UTC timestamps and upload in FIFO order on reconnect, startup, focus, returning to the app, or a 30-second retry. Synchronization requires the app to be open; closed-app background delivery is not implemented.
- Every event has a UUID. The backend returns an existing event for an identical retry, even after later transitions. Clock-out creates its working-time entry only once.
- Cached data and queues are scoped to the API instance and authenticated account. Other accounts cannot access or replay your queue. Backend permissions and the request's account owner are checked on upload. Supported browsers coordinate tabs using Web Locks and update attendance displays through BroadcastChannel.
- An expired/rejected session requires an online login. Pending attendance remains saved and resumes when the original account signs in. A network failure alone preserves offline access.
- Logout removes cached authentication access, including in other tabs, and retains pending actions. Offline logout cannot contact the server to clear its HttpOnly cookie; local CSRF/profile state is removed and an online login is required next time.
- Demo attendance remains in a separate database and is never synchronized.

Only attendance actions are queued. Registration, profile changes, team/admin operations and manual working-time edits require connectivity. Offline attendance for other employees is disabled when the browser reports offline. Browser data clearing removes local caches and unsent actions.

## Backend preparation

Deploy the updated backend and apply `backend/priv/repo/migrations/20261009131557_add_clock_client_action_id.exs` using the existing migration-capable database account and [database runbook](DATABASE_OPERATIONS.md) before releasing the frontend. The migration adds an optional UUID column and a unique `(user_id, client_action_id)` index without deleting existing records. Existing callers without an action ID continue to work.

The frontend refuses to acknowledge queued events if the response does not contain their action ID. An older backend cannot safely synchronize retries: update it first rather than experimenting with real attendance against the old API.

The server remains authoritative. Permission/transition/timestamp conflicts (403/422) stop FIFO delivery and retain the conflicting event and all subsequent events. The interface explains the error; retry after resolving the conflict. Actions are not silently discarded or rewritten. Automatic conflict resolution across devices is not implemented.

## Local offline check

Use a running updated backend at localhost port 4000. From `frontend`:

```powershell
npm.cmd run build
npm.cmd run preview -- --host 127.0.0.1 --port 5173 --strictPort
```

Use port 5173 because the existing backend CORS configuration allows it. Stop an existing dev server on that port first. Use the production preview for offline reopening; `npm run dev` depends on the Vite development server and does not provide the production service-worker behavior.

1. Open `http://127.0.0.1:5173`, sign in with a real account and wait for attendance to load.
2. In browser developer tools, verify that the service worker is activated and controls the page.
3. Enable network Offline, reload the page and record clock-in/out.
4. Close and reopen the tab: your profile, status, history and pending count should remain.
5. Restore connectivity and keep the app open. The pending count should reach zero and the backend should contain the original timestamps once each.

For a deployed domain, service-worker offline caching requires HTTPS. Localhost is suitable for local testing. HTTPS and the offline application/backend UUID migration are now deployed on OVH (October 9, 2026).

### Using the deployed app

1. While online, open `https://57.130.61.152`, refresh and sign in.
2. Wait for **App downloaded for offline use.** and for attendance to load.
3. Disconnect and reopen that exact HTTPS address in the same browser/profile. Use a normal reload; do not clear browser data.
4. Record attendance offline. Reconnect and keep the app open to synchronize automatically.

Typing the HTTP address while offline cannot reach the server's HTTPS redirect. A first visit on a new browser/device needs internet.

## Automated verification

`frontend/tests/offline-attendance.cjs` requires an isolated disposable backend/database. It creates test accounts and attendance records, so do not run it against production. Start the updated backend and the production preview above, then run:

```powershell
# Use an installed browser, or install Playwright's Chromium first.
$env:BROWSER_EXECUTABLE_PATH = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
npm.cmd run test:offline
```

Alternatively, run `npx playwright install chromium` and omit `BROWSER_EXECUTABLE_PATH`. `OFFLINE_TEST_URL` and `OFFLINE_TEST_API` override the default localhost addresses; their origins must be allowed by backend CORS.

The test covers production offline reload and tab reopening, mobile viewport, cross-tab attendance updates, persistent queue/history, ordered replay, original timestamps, lost-response retry without duplicates, expired sessions, account isolation, conflict retention and offline logout. Backend `mix precommit` also covers UUID validation, payload reuse rejection, owner/permission enforcement and legacy transitions. Use a separate disposable database partition for backend tests if the browser backend is running.

Production deployment completed October 9, 2026. The targeted live check `../_local_artifacts/theme05-browser-check/ovh-offline-check.cjs` passed trusted HTTPS, offline reload/new-tab reopening at a 390px viewport, persistent clock-in/out/history, and automatic reconnect replay with original UUIDs/timestamps exactly once. Its temporary account and attendance were deleted. Real-phone device validation remains outstanding.

Frontend/backend rebuilt with both secure and HTTPS Compose files; migration `20261009131557` applied with the administrator in a temporary migration container. The running backend retains its limited database role. Release backup: `/var/backups/time-manager-offline-20261009T142508Z/`; pre-release database dump and previous images retained. Active database stayed running; incident database stayed stopped. Local production build passed with the offline-ready message and service-worker cache headers.

## Integrated dashboard release (October 9, 2026)

Application commit `ecfc9ed` is published on GitHub branch `integration/offline-dashboard-20261009` and deployed to OVH. It combines origin/main `4168804` with offline attendance and HTTPS. Live `../_local_artifacts/theme05-browser-check/ovh-integration-check.cjs` passed offline reopening/new tab, persistent attendance, cached report period switching, 390px viewport fit and automatic exactly-once replay with original timestamps/UUIDs. Temporary test account/attendance removed. Backup: `/var/backups/time-manager-integration-20261009T145132Z/`; pre-release DB dump/images retained. Existing UUID migration was already applied; clean and incident databases preserved.
