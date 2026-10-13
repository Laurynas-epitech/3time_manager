# Security

## Authentication and permissions

Passwords use Bcrypt; new passwords require at least eight characters and at most
72 bytes. Joken signs the JWT stored in an HttpOnly, SameSite=Lax cookie. The HTTPS
deployment enables Secure cookies. Protected requests require a matching CSRF
header. JWTs expire after 24 hours; each request reloads the current database role.

Employees access their own attendance. Managers access themselves and members of
teams they manage. Only administrators can grant a new person assignment; managers
may reuse people already assigned to their existing teams. Directory `scope=all`
cannot expand a manager's access.

Online logout clears the browser cookie. A copied JWT is not revoked before expiry,
and password changes do not invalidate all previous JWTs. Offline data is isolated
by account but is not encrypted or resistant to local device tampering.

## Request and resource limits

- Public registration/login: 10 requests per client IP per minute.
- Authenticated writes: 120 per account per minute. Reads/logout remain available.
  Blocked requests return 429 with Retry-After; saved offline actions remain queued.
- Body limit: 1,000,000 bytes. Parser errors return generic responses with headers.
- Username maximum 50 characters; team name maximum 100 characters.
- Per-request list caps: users 500, teams 50, members 100, clocks/working times 2,000.
  Frontend pages retrieve complete histories/directories before replacing caches.
- Large teams expose bounded previews and `members_has_more`. Authorized clients
  fetch subsequent members from `/api/teams/:id/members`.

The limiter is single-node/in-memory and resets on restart. Distributed registration
and host bandwidth exhaustion need further assessment. Offset pages are not a
transactional snapshot during concurrent imports/deletions. Downloads over 100,000
records fail visibly; large histories should eventually use server-side period reports.

## Proxy and deployment

`TRUSTED_PROXY_IPS` is a comma-separated list of exact controlled TCP peer addresses
as seen by the backend. Only these peers may supply one valid X-Real-IP address;
other headers fall back to the actual peer. Trusted proxies must overwrite the header.

Host Nginx may appear as the Docker network gateway, rather than 127.0.0.1. Inspect
the actual deployment before setting this variable. Without configured peers,
protection remains active but users behind a proxy share its auth bucket.

Both Compose variants bind the backend host port to loopback. Frontend requests use
same-origin `/api`; the secure deployment includes the HTTPS overlay. Credentials
stay in private external secret files, outside Git. Development code reloading is
disabled; diagnostic routes require an explicit `ENABLE_DEV_ROUTES=true` compile-time
override. Leave it unset and rebuild for public deployments.

Frontend/backend responses include browser hardening headers. See
[HTTPS operations](operations/https.md) for host proxy configuration.

## Verification and remaining work

October 13 local checks passed for proxy spoofing, membership authorization, bounded
reads, write limits, malformed bodies, stored SVG/script/HTML escaping, a SQL-style
filter payload, CSRF/role rejection, sensitive-path 404s and offline account isolation.
See [testing](testing.md) for commands and scope.

The latest fixes are not deployed. Release checks must verify actual-client limiting,
loopback access, HTTPS/cookie/header behavior, diagnostics and offline replay through
the configured public proxy. Full pentest, controlled sustained resource testing,
interception and real-device/shared-device assessment remain open. Targeted regression
results do not establish a complete security audit.
