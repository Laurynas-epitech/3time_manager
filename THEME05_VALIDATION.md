# Theme 05 validation — October 8, 2026

## Current verification

- Frontend: `npm run build` passed locally (107 modules transformed).
- Backend: `mix precommit` passed against the current backend source in the existing Elixir test-cache image on OVH: 27 tests, 0 failures. This includes compilation with warnings treated as errors, unused dependency check, formatting, and tests.
- Backend validation used disposable containers, a PostgreSQL 16 database on tmpfs, no published ports, and no production data or volume mounts. Production containers were not changed by these checks.
- `git diff --check` passed. Deployment shell syntax passed with local Git Bash; backup Python syntax passed with Python AST parsing. These checks do not execute deployment or backup operations.
- Authentication integration/browser and production verification recorded earlier are documented in AUTHENTICATION_SETUP.md; browser checks were not repeated in this validation pass.

## Theme 05 evidence

| Criterion | Implementation/evidence |
|---|---|
| Password hashing | Bcrypt registration/password changesets; accounts tests |
| JWT with Joken | `backend/lib/time_manager/auth/token.ex`; expiry and invalid-token tests |
| HttpOnly JWT cookie and returned CSRF token | AuthController/AuthCookie; authentication controller tests |
| Request CSRF matches JWT claim | Authenticate plug checks cookie and header on protected routes, including logout; rejection tests |
| User identity and role | JWT claims plus current user/role loaded from database on each protected request |
| Predefined read-only roles | Migration seeds roles; router exposes GET roles, no role CRUD |
| Administrator bootstrap | Explicit ADMIN_EMAIL/password input in seeds; no default login password |
| Multiple teams | team_users relationship; team and permission tests |
| Login/logout | Vue authentication state/views and protected logout route |
| Promotion/demotion | Administrator-only role update; permission tests include stale-manager demotion |
| Page restrictions | Vue Router beforeEach role/auth guards plus backend authorization |
| Clocking history | Three controller regression tests verify completed sessions, invalid transitions, and same-second ordering |

Protected routes require CSRF. Public login/registration are bootstrap exceptions because no JWT exists yet. The implementation supports the Theme 05 criteria; the permission matrix is an application choice where the criteria are unspecified.

## Publication and operational limits

Review this branch through a PR against main and require GitHub CI before merging. A Git push is not an OVH deployment. Migrations/admin bootstrap run separately with administrator DB access; the running backend uses a limited application role.

HTTPS and secure-cookie mode, independent off-server automated backups, failure notifications, and host-compromise assessment remain outstanding operational work. Logout clears the browser cookie but cannot revoke a copied JWT before expiry. Do not claim those limitations are resolved by passing Theme 05 tests.