# Local security assessment — October 13, 2026

## Scope and release distinction

This controlled assessment used disposable local PostgreSQL data and local HTTP/TLS
proxies. It did not flood or modify the deployed application. The deployed revision
is `87bc705`; the follow-up controller, pagination and frontend fixes described here
are local changes and require release verification before deployment.

## Findings and fixes

Malformed nested mutation bodies previously raised errors. Controllers now require
maps and return 400 for unsupported shapes. Invalid, incomplete or reversed attendance
filter periods previously returned unfiltered data; they now return 400. Offsets are
bounded to 1,000,000 to avoid oversized database integers and excessive offsets.

Large team directories created excessive browser elements by repeating the entire
member picker for every team. Team pages now render ten teams, admin pages render
50 users, and member pickers show at most 50 matches with a search field. The complete
authorized dataset remains available through paging and search.

## Recorded results

| Check | Result and limits |
|---|---|
| Backend `mix precommit` | 52 tests, zero failures; includes malformed shapes, SQL-style filters/credentials, ownership aliases, role mass assignment, sensitive paths and hostile offsets |
| Frontend | Production/PWA build and four pagination tests passed |
| Stored injection and list controls | Final Chromium run: 42 SVG/script/HTML cases across admin, manager and employee at 390px and 1440px; no execution or dialogs; bounded lists, user paging and member search passed |
| Offline role tampering | Local cached role could be edited; backend rejected privileged team creation with 403 and returned the real employee role |
| History integrity | All 2,001 fixture attendance sessions were present in the offline cache |
| Response caps | Users 500, teams 50, members 100, attendance/clocks 2,000; measured response bodies approximately 9–160 KB |
| Controlled reads | 40 requests, concurrency four; 402.47 ms total and 93.17 ms p95 in this local run; not a capacity guarantee |
| Write limit | 120 accepted writes, next write blocked; reads and logout remained available |
| Password hashing | Bcrypt cost 12; three samples 247.72, 238.284 and 244.171 ms on this environment |
| HTTP/TLS observer | Dummy credential marker visible over HTTP, absent from observed TLS bytes; untrusted certificate rejected, explicit local certificate trust succeeded |
| Narrow Git history scan | 344 fetched blobs; no matches for the scanned private-key/GitHub-token patterns; not a comprehensive secret audit |

The TLS test used an ephemeral localhost certificate and a TCP observer. It does
not prove resistance to a compromised device, trusted malicious certificate authority,
or every active interception scenario. The local HTTP proxy is a test fixture, not
a production configuration.

## Outstanding risks

A copied cookie together with its CSRF token still returned 200 after logout.
Logout clears the browser cookie but does not revoke the signed JWT. Password changes
also do not invalidate all existing JWTs. Session revocation remains unresolved.

Offline data is unencrypted and editable on the device. Physical-phone and shared-device
coverage, distributed denial of service, sustained resource tests and broader dependency
and infrastructure review remain open. These results do not establish a complete audit.

## Repeating the assessment

Use an isolated empty database named `time_manager_security_assessment`. The seed
`backend/priv/security_assessment_seed.exs` refuses to run unless
`SECURITY_ASSESSMENT_LOCAL=true`, the database name matches, and its users table is
empty. Set `SECURITY_ASSESSMENT_OUTPUT` to a private ignored directory; it writes
random disposable credentials to `fixtures.json`. Never commit that file or TLS keys.

Run backend `mix precommit`, frontend `npm ci`, `npm run build`, and
`node --test tests/pagination.test.js` using the project's normal test configuration.
Serve the candidate build and backend locally. Browser checks require Playwright and
Chromium; optionally set `BROWSER_EXECUTABLE_PATH` as supported by the script.

Set `SECURITY_ASSESSMENT_FIXTURES` to the private fixture JSON, then run:

```sh
node tests/security-assessment-browser.cjs
node tests/security-resource-assessment.cjs
```

The resource script mutates disposable data and deliberately reproduces the current
logout-replay behavior. Run it after the browser script, and reset fixtures before a
new assessment. Default URLs are localhost; scripts reject other hostnames.

For the transport check, use `frontend/tests/fixtures/assessment-nginx.conf` with
the production build, local backend and an ephemeral certificate/key. Set
`SECURITY_ASSESSMENT_CERT` to the certificate and run
`node tests/security-transport-assessment.cjs` in the local proxy network namespace.
It expects local HTTP port 5173 and TLS port 8443. Preserve only non-secret results
and stop the disposable services afterward.
