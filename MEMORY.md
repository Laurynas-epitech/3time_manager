# Time Manager — Project memory and plan

Updated: October 9, 2026 (Europe/Paris).

## Status legend and ongoing update rule

| Checklist marker | Meaning | When to use it |
|---|---|---|
| `[x]` **[PASS] - DONE** | Completed and verified. | The full requirement has supporting code, tests, deployment evidence or a deliverable. |
| `[ ]` **[PARTIAL] - PARTLY DONE** | Some work is implemented, but the requirement is incomplete. | State what already works and exactly what remains. |
| `[ ]` **[FAIL] - TO DO / FIX** | Missing or confirmed incorrect. | State the missing behavior or defect. This is a work status, not a claim that the whole theme failed. |
| `[ ]` **[NOT VERIFIED] - TO CHECK** | Evidence is insufficient. | Inspect or test before deciding whether implementation is complete or missing. |
| `[ ]` **[NOT APPLICABLE] - N/A** | A conditional requirement does not apply. | Explain why; exclude it from completion targets. |

Deferred work keeps its actual status and explicitly says **DEFERRED** in its note. Bootstrap-only, recommended and optional criteria retain their classification and are counted separately from mandatory work.

**Apply this rule after every project task:**

1. Read this memory before starting; identify the affected criteria and persistent user decisions.
2. After implementation, verification, deployment or a planning decision, update the affected checklist entries using the legend. For PARTIAL items, retain both completed work and the remaining gap.
3. Record the evidence: relevant file paths, test results, CI/PR/commit links, deployment results and the date. Distinguish prepared code, verified code and deployed behavior.
4. Recalculate the status totals whenever an item's status changes. Update remaining priorities and the baseline if the task changes them.
5. Add a short dated entry to the progress log. If no criteria changed, say so; do not mark unrelated work complete.
6. Never mark PASS merely because code was written, a PR was merged or a file exists. Never overwrite user deferrals or treat optional criteria as mandatory failures.

### Progress log

| Date | Work completed | Verification / remaining work |
|---|---|---|
| October 9, 2026 | Owner requested GitHub push and OVH deployment of the resolved integration. | Pushed ecfc9ed to origin/integration/offline-dashboard-20261009 (includes origin/main 4168804). Rebuilt frontend/backend with HTTPS overlay; migration already applied. Live ovh-integration-check.cjs passed trusted TLS, 390px fit, cached hours-report period switching, offline reload/new-tab attendance persistence and automatic exactly-once original UUID/timestamp replay. Temporary account/attendance removed. Backup /var/backups/time-manager-integration-20261009T145132Z; pre-release DB dump and images retained. Clean DB stayed running; incident DB stayed stopped; Secure cookies/renewal timer preserved. No checklist status change; totals remain 118/39/15/22/1 (mandatory 108/34/10/18/1). GitHub main is unchanged; integration branch is published. |
| October 9, 2026 | Integrated GitHub origin/main 4168804 (colleague dashboard/daily-weekly redesign) with local HTTPS and offline work on integration/offline-dashboard-20261009. | Resolved six conflicts in MEMORY, App, ClockManager, WorkingTimes, Dashboard and deleted style.css; kept design tokens/header/toasts/team navigation plus IndexedDB queue/auth/sync. Reports and team status use attendance snapshots; pending/offline punches cannot be edited. Frontend production/PWA build and backend Docker build passed. Updated frontend/tests/offline-attendance.cjs passed offline reload/new-tab persistence, 390px fit, cached report period switching, cross-tab clock, FIFO/original timestamps, duplicate retry, normal reconnect, expiry/account isolation, conflicts and offline logout against disposable local PostgreSQL. Test fixtures stayed local; test containers/network removed. Recovery stash offline-https-before-colleague-integration-20261009 retained. Four colleague criteria retained as PARTIAL; recomputed totals: 118 PASS, 39 PARTIAL, 15 FAIL, 22 NOT VERIFIED, 1 N/A; mandatory 108/34/10/18/1. Integrated redesign has not been deployed or pushed. |
| October 9, 2026 | Deployed the offline attendance application on OVH at the owner's request. | Frontend/backend production images rebuilt with HTTPS overlay; UUID migration 20261009131557 applied; clean DB retained and incident DB stopped. Backup /var/backups/time-manager-offline-20261009T142508Z; previous images and pre-release dump retained. Local build passed. Live ovh-offline-check.cjs passed offline reload/new-tab reopening, persistent clock-in/out/history and automatic exactly-once synchronization of original UUIDs/timestamps at 390px. Temporary live account/attendance removed. Added offline-ready message and service-worker cache headers. Real-phone/native/full-page coverage remains outstanding; statuses/totals unchanged: 118 PASS, 35 PARTIAL, 19 FAIL, 22 NOT VERIFIED, 1 N/A. |
| October 9, 2026 | Frontend only: daily/weekly hours over a selected period, "Punch Card" redesign (design-handoff/) of the app shell, Employee Today and Manager My team (`/team`, admins: "Dashboards" incl. "Everyone"), read-only Teams page for employees, punch edit fixes (scroll/inline edit, visible errors), toasts. No backend change. | Checked locally in headless Chromium (desktop 1440px + mobile 390px, no horizontal overflow; add/edit/delete punch, role redirects, employee team edits rejected by the API with 403). 4 items FAIL → PARTIAL (period/daily/weekly dashboards, individual hours); totals updated. Remaining redesign screens: Teams, People, Profile. ChartManager no longer rendered (Theme 02 decision pending). Not deployed to OVH. |
| October 9, 2026 | Owner requested "do https", authorizing and applying the prepared OVH HTTPS cutover. | Trusted external TLS, HTTP 308 redirect, anonymous API 401 and browser registration/login/reload/logout, Secure/HttpOnly cookie and CSRF checks passed; temporary validation account removed. App ports are loopback-only; clean DB unchanged and incident DB still stopped. Configuration backup: /var/backups/time-manager-https-20261009T140237Z. Simulated certificate renewal passed; renewal timer enabled/active. See HTTPS_SETUP.md. Password transmission and HTTPS enforcement now PASS: 118 PASS, 35 PARTIAL, 19 FAIL, 22 NOT VERIFIED, 1 N/A. Local offline application/migration remains undeployed. |
| October 9, 2026 | Implemented real-account offline attendance and automatic synchronization in the Vue PWA. | Production build/service worker passed; frontend npm run test:offline passed offline reload/tab reopening, 390px viewport, cross-tab attendance, local history/queue, FIFO original timestamps, automatic reconnect, lost-response deduplication, expiry/reauthentication, account isolation, conflict retention and offline logout. Backend mix precommit passed 29 tests in a separate disposable database partition. New UUID migration generated with mix ecto.gen.migration; OFFLINE_SETUP.md documents release order and limits. 10 criteria now PASS and 5 PARTIAL: totals 116 PASS, 36 PARTIAL, 20 FAIL, 22 NOT VERIFIED, 1 NOT APPLICABLE. Production deployment, HTTPS and real-phone/native assignment verification remain outstanding; HTTPS stays deferred. |
| October 9, 2026 | Fixed development Demo Mode attendance saving without a backend. | services/demoAttendance.js stores clock state and completed sessions transactionally in a separate time-manager-demo IndexedDB database, isolated from real pendingActions. ClockManager, WorkingTimes, ChartManager and DashboardView use local demo data. Production build passed; ../_local_artifacts/theme05-browser-check/demo-clock-check.cjs passed clock-in/out, reload, history and logout/login persistence with zero API requests or browser errors. Real authenticated offline attendance and synchronization remain incomplete; mandatory checklist statuses/totals unchanged. |
| October 9, 2026 | Completed the user's development demo-login integration and restored the original App.vue interface from its commented copy. | Added LoginView handler, development-only guards, session restoration/logout handling and demo-safe 401 routing. Removed duplicate registerSW import; installed missing vite-plugin-pwa and idb dependencies used by existing user edits. Vue component compilation and full production build passed, including generated service worker. Browser demo/login/reload/logout checks remain unverified. Actual dashboard offline persistence/replay is not connected; checklist statuses/totals unchanged. npm audit reports one high source-map-js advisory; no unrelated dependency upgrades applied. |
| October 9, 2026 | Clarified the Vue frontend stylesheet location for manual mobile CSS edits. | frontend/src/main.js imports frontend/src/style.css; backend/assets/css/app.css belongs to Phoenix assets. Existing responsive rules also appear in frontend/src/App.vue. Source inspection only; requirement statuses and totals unchanged. |
| October 9, 2026 | Reviewed how authentication can coexist with offline use and automatic synchronization. | Source inspection: frontend/src/auth.js restores sessions through the API and clears session state on request failure; no offline queue or persistence implementation found in frontend source. Explained prior online login, local data/action persistence and authenticated replay on reconnect. No implementation or checklist status/totals changed. |
| October 9, 2026 | Audited and annotated all 195 checklist items; added evidence notes and remaining priorities. | 106 PASS, 31 PARTIAL, 35 FAIL, 22 NOT VERIFIED, 1 NOT APPLICABLE. Existing test/CI evidence is dated October 8; no fresh full live audit was run. |
| October 9, 2026 | Added this legend and the persistent checklist-update workflow. | Documentation change only; implementation statuses and totals are unchanged. HTTPS remains deferred. |
| October 9, 2026 | Organized 16 workspace artifacts into ../_local_artifacts and prepared team-facing plan/instructions and Git ignore rules. | Keys remain in the workspace root. Ignore checks and staged-content scan passed; no requirement statuses changed. Deferred HTTPS changes remain unstaged; no push/deployment performed. |

| October 9, 2026 | Fetched GitHub and compared current branch and local main with origin/main. | Both comparisons: 0 ahead, 0 behind at fd75089. Local staged/untracked work is not published; checklist statuses unchanged. |

| October 9, 2026 | Owner authorized committing and pushing the team plan, progress instructions and ignore rules on chore/project-plan-and-gitignore. | Staged files reviewed and diff checks passed. Deferred HTTPS changes excluded; application criteria/totals unchanged. |

## User-approved scope and priorities

Use the final checklist below as the project plan: Main Project and Themes 01, 02, 03, 05, 06, 07. Theme 04 is excluded. Source: `C:\Users\laury\Downloads\TIME_MANAGER_FINAL_CHECKLIST.md`. The full checklist with inspected status is included below so the plan does not depend on the Downloads file remaining available.

The source checklist says it has not been independently reverified against assignment documents. Consult the original brief when an exact criterion or conflict needs clarification. Mandatory requirements determine assignment completion. Track bootstrap-specific items, recommendations and optional enhancements separately; do not turn them into mandatory failures.

## Persistent user decision: HTTPS authorized and enabled

On October 9, 2026 the user explicitly requested "do https", replacing the earlier deferral and authorizing the prepared OVH HTTPS cutover. Trusted HTTPS is now serving https://57.130.61.152 with HTTP redirects, Secure/HttpOnly JWT cookies and loopback-only frontend/backend bindings. Keep password hashing, CSRF checks, backend permissions and both existing databases intact. The HTTPS cutover used existing images; the subsequent authorized October 9 application release deployed the offline frontend/backend and UUID migration, with live offline reopening and synchronization verified.

HTTPS enforcement and password transmission were verified using external trusted TLS and a temporary browser test account, removed after validation. Certificate renewal verification is recorded in HTTPS_SETUP.md. A complete Theme 07 interception/penetration assessment remains outstanding; enabling HTTPS does not complete that assessment.

## Current implementation baseline and evidence

- Theme 05 integration PR #4 was merged. Local main was fast-forwarded to `fd75089` (merge of `2160cfc`).
- Backend `mix precommit`: 27 tests, zero failures, in disposable PostgreSQL 16 containers without production mounts.
- Frontend production build passed. PR #4 GitHub CI passed frontend build, backend tests, and Docker image builds.
- See `THEME05_VALIDATION.md`, `AUTHENTICATION_SETUP.md`, and `DATABASE_OPERATIONS.md` for detailed validation and deployment records. These records support specific findings, not blanket completion of every final checklist item.
- The clean application database and authentication were deployed earlier; original incident database/evidence remains preserved. Never delete or initialize incident volumes.
- HTTPS configuration is applied to OVH following the owner's October 9 request. Keep the HTTPS Compose overlay in future deployments and preserve the incident database/volume. The offline application and UUID migration are now deployed and live-tested. See HTTPS_SETUP.md for verification and rollback evidence.
- Existing implementation uses `employee`, `manager`, `admin` roles. The Main Project checklist names Employee, Manager, General Manager. Verify semantic coverage and required naming before marking this criterion PASS.
- The existing Vue PWA now has locally and production-verified offline attendance and automatic synchronization on OVH; separate native mobile application, real-phone validation and completed Theme 07 penetration assessment remain unverified.
- CI is verified; automatic CD remains outstanding in the available evidence.
- The older `../_local_artifacts/EPITECH_TIME_MANAGER_CURRENT_HANDOFF.md` describes an earlier incident/recovery checkpoint and is stale where it conflicts with later deployment records.

## Workspace organization and team publication

- Application repository: `3time_manager` (this folder). Run Git commands here, not from the outer workspace.
- Temporary validation folders, archives, deployment helpers and historical handoffs: `../_local_artifacts/`, preserved outside the repository.
- SSH keys: `../time` and `../time.pub`; left in place to keep existing SSH commands working. Never stage them.
- Team documents: `MEMORY.md`, `AGENTS.md`, authentication/database runbooks and validation notes. Keep these tracked.
- Repository `.gitignore` excludes secrets, private keys, backups/archives, incident evidence and generated outputs. Existing dependency/build ignores remain; lockfiles, migrations, source and `.env.example` remain eligible for tracking.
- The outer workspace `.gitignore` provides an additional guard if someone initializes Git there; it is outside this repository and is not part of its team commit.
- HTTPS and offline integration are deployed and committed on integration/offline-dashboard-20261009, published to GitHub. Review explicit staged files rather than using `git add .`; never publish keys or server certificate files.

## Checklist status and remaining work

Checked boxes mean PASS. Unchecked boxes distinguish PARTIAL, FAIL, NOT VERIFIED and NOT APPLICABLE; they do not all mean missing implementation. This is a repository/evidence audit, not a fresh live-server or full browser/security test run. Previous passing checks are dated October 8, 2026.

| Scope | PASS | PARTIAL | FAIL | NOT VERIFIED | NOT APPLICABLE |
|---|---:|---:|---:|---:|---:|
| All checklist items | 118 | 39 | 15 | 22 | 1 |
| Mandatory items only | 108 | 34 | 10 | 18 | 1 |

### Concrete remaining priorities

1. Reconcile General Manager/admin naming and responsibilities; manager team creation is admin-only while managers can manage memberships.
2. Complete individual daily/weekly report arithmetic/coverage verification; integrated views are deployed. Team-wide daily/weekly averages and General Manager naming remain outstanding.
3. Enforce database NOT NULL constraints for required fields with reviewed data-preserving migrations; tighten email validation to the required format.
4. Reconcile the Theme 02 named routes/User component criteria with the later authentication views; add needed compatibility routes and exact date/time presentation, plus chart controls and accessibility verification.
5. Add safe automatic CD; existing CI already passes.
6. Validate the original Theme 06 mobile brief against the deployed Vue PWA; verify real phones and all required pages. Backend/migration and frontend are now released over HTTPS with live offline attendance verification.
7. Complete Theme 07 assessment/fixes/retests, including mobile and interception coverage; HTTPS is enabled and must be preserved.
8. Collect missing Postman, UX, accessibility and employee-protection evidence. Bootstrap-only mismatches are tracked separately and do not by themselves invalidate Theme 05.

### Evidence keys used below

- **E1 - API/data:** `backend/lib/time_manager_web/router.ex`, user/clock/working-time schemas, `backend/priv/repo/migrations/`, API controller/tests; `DATABASE_OPERATIONS.md` migration/restore record. The required local port is configured, not freshly exercised on Windows.
- **E2 - Account/role/team behavior:** `backend/lib/time_manager_web/authorization.ex`, UserController/TeamController, `frontend/src/views/ProfileView.vue`, AdminView, TeamsView, DashboardView; `backend/test/time_manager_web/controllers/permissions_test.exs`. General Manager-specific items remain PARTIAL because the implemented role is named admin. Profile self-deletion exists in code; every-role browser deletion was not repeated.
- **E3 - Web/chart evidence:** `frontend/src/App.vue`, `frontend/src/router.js`, `frontend/src/components/{WorkingTimes,WorkingTime,ClockManager,ChartManager}.vue`, `frontend/src/views/`; frontend build and prior UI checks in `AUTHENTICATION_SETUP.md`. The colleague's HoursReport/Today/MyTeam redesign provides individual daily/weekly aggregates and period selection; integrated with offline snapshots and deployed to OVH; live cached reports and attendance verification passed. ChartManager remains in source but is not rendered by the redesign, so its current UI/route coverage still needs review.
- **E4 - Infrastructure:** `docker-compose.yml`, `docker-compose.secure.yml`, Dockerfiles, `.github/workflows/ci.yml`, `DATABASE_OPERATIONS.md`, `AUTHENTICATION_SETUP.md`; successful [PR #4 CI run](https://github.com/Laurynas-epitech/3time_manager/actions/runs/37793116761). October 9 HTTPS cutover is now deployed and externally TLS/browser verified; see HTTPS_SETUP.md for certificate, renewal and rollback evidence.
- **E5 - Authentication:** `THEME05_VALIDATION.md`, `AUTHENTICATION_SETUP.md`, `backend/lib/time_manager/auth/token.ex`, AuthCookie/Authenticate, seeds, role/team migrations, `frontend/src/auth.js`, API/router/views and backend tests. 27 tests passed. JWT includes the issued role; request authorization reloads current role from DB so demotions take effect. Logout clears the cookie but cannot revoke an already copied JWT.
- **E6 - Mobile/offline:** October 9 implementation: frontend/src/services/{attendance,offlineSession,demoAttendance}.js, auth.js, ClockManager/WorkingTimes/ChartManager, App.vue sync status and vite.config.js PWA caching. Backend clock UUID migration/schema/JSON and transactional record_clock enforce idempotent retries and request ownership/permissions. Production build and frontend/tests/offline-attendance.cjs passed on localhost with a 390px browser viewport and a disposable real backend/database; backend mix precommit passed 29 tests in a separate disposable partition. OFFLINE_SETUP.md records behavior, commands, release order and limits. Local and live OVH offline attendance are verified. The October 9 release applied the UUID migration and rebuilt frontend/backend with the HTTPS overlay, preserving both databases and limited app role. Live ../_local_artifacts/theme05-browser-check/ovh-offline-check.cjs passed offline reload/new-tab reopening and automatic exactly-once replay of original timestamps/UUIDs; temporary account/attendance removed. Backup /var/backups/time-manager-offline-20261009T142508Z. Real-phone/native brief coverage and every mobile page remain incomplete.
- **E7 - Security:** incident/auth records document some issues; no complete Theme 07 penetration-test/injection/DoS/mobile report was found. Unverified security criteria must be investigated on authorized isolated targets, not assumed passed.

## Next work sequence

1. Audit the current Main Project and Themes 01/02/03/05 against the final checklist. Record PASS, PARTIAL, FAIL, NOT VERIFIED, or NOT APPLICABLE with evidence. Do not infer completion from filenames or merged PRs alone.
2. Resolve confirmed mandatory gaps, including dashboards/team aggregates, route/component compatibility and automatic deployment where required. Do not redesign features solely for optional recommendations.
3. Review original Theme 06 documents before implementation choices; build the required mobile pages/authentication and offline clocking/persistence/synchronization. Keep bootstrap FIFO/progress/error requirements separately classified.
4. Perform Theme 07 security testing against authorized isolated/test targets; patch and verify findings. Include mobile and preserve the now-enabled HTTPS deployment. A checklist entry does not authorize flooding or denial-of-service testing against the live OVH service.
5. Complete the final evidence audit and deliverables. Mark checkboxes only after verification, preserving supporting paths/results.

This file records the plan; creating it does not start implementation of all checklist items, deploy HTTPS, or authorize destructive database operations.

---

## Final checklist - inspected status (October 9, 2026)

# Time Manager — Final Project Criteria Checklist

**Date:** October 9, 2026
**Scope:** Main Project + Themes 01, 02, 03, 05, 06, 07
**Excluded:** Theme 04 — Change Resistance

This file preserves the checklist criteria and adds code/evidence-based status annotations. Mandatory requirements are separated from recommendations and Bootstrap-specific instructions. This conversion does not independently reverify the checklist against the assignment documents.

Use the checkboxes to track completion. Mark a requirement complete only after verification through code inspection, tests, deployment evidence or the relevant deliverable.

## Main Project — Core Requirements

### User roles and permissions

- [ ] Three user categories exist: **Employee, Manager, General Manager**. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)
- [x] Managers can group employees into teams. **[PASS]** — Implemented in account/dashboard/team/clock flows and permissions. (E2)
- [x] All users can edit their account information. **[PASS]** — Implemented in account/dashboard/team/clock flows and permissions. (E2)
- [x] All users can delete their own account. **[PASS]** — Implemented in account/dashboard/team/clock flows and permissions. (E2)
- [x] All users can report arrival and departure times. **[PASS]** — Implemented in account/dashboard/team/clock flows and permissions. (E2)
- [x] All users can view their own dashboard. **[PASS]** — Implemented in account/dashboard/team/clock flows and permissions. (E2)
- [ ] Managers and the General Manager can manage their team(s). **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)
- [ ] Managers and the General Manager can view average daily and weekly working hours of teams over a selected period. **[FAIL]** — No daily/weekly aggregates or dashboard period selector; charts show per-entry durations. (E3)
- [ ] Managers and the General Manager can view an individual employee's daily and weekly working hours over a selected period. **[PARTIAL]** — Implemented in `frontend/src/components/HoursReport.vue` (period chips + custom dates, daily bars up to 14 days, weekly bars beyond, total / per week / per worked day / days worked, accessible table) on Today and on /team (`MyTeamView.vue`); checked in a local headless browser on October 9, 2026 (Europe/Paris, midnight-crossing session split correctly). Deployed to OVH on October 9; offline snapshot/period switching verified in local regression and live browser checks. Full report arithmetic/period coverage remains unverified. Managers reach their team members (backend still returns 403 outside their teams) and admins everyone via /team. Remaining: full report arithmetic/period coverage and the General Manager/admin naming. (E3)
- [ ] Managers and the General Manager can view their employees' dashboards. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)
- [ ] The General Manager can promote an employee to Manager. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)
- [ ] The General Manager can view all users' dashboards. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)
- [ ] The General Manager can delete any user's account. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)

### Dashboards, accessibility and employee protection

- [ ] Dashboards display daily working hours. **[PARTIAL]** — Implemented in `frontend/src/components/HoursReport.vue` (period chips + custom dates, daily bars up to 14 days, weekly bars beyond, total / per week / per worked day / days worked, accessible table) on Today and on /team (`MyTeamView.vue`); checked in a local headless browser on October 9, 2026 (Europe/Paris, midnight-crossing session split correctly). Deployed to OVH on October 9; offline snapshot/period switching verified in local regression and live browser checks. Full report arithmetic/period coverage remains unverified. Remaining: full report arithmetic/period coverage. (E3)
- [ ] Dashboards display weekly working hours. **[PARTIAL]** — Implemented in `frontend/src/components/HoursReport.vue` (period chips + custom dates, daily bars up to 14 days, weekly bars beyond, total / per week / per worked day / days worked, accessible table) on Today and on /team (`MyTeamView.vue`); checked in a local headless browser on October 9, 2026 (Europe/Paris, midnight-crossing session split correctly). Deployed to OVH on October 9; offline snapshot/period switching verified in local regression and live browser checks. Full report arithmetic/period coverage remains unverified. Remaining: full report arithmetic/period coverage. (E3)
- [ ] Dashboard data can be viewed over a selected period. **[PARTIAL]** — Implemented in `frontend/src/components/HoursReport.vue` (period chips + custom dates, daily bars up to 14 days, weekly bars beyond, total / per week / per worked day / days worked, accessible table) on Today and on /team (`MyTeamView.vue`); checked in a local headless browser on October 9, 2026 (Europe/Paris, midnight-crossing session split correctly). Deployed to OVH on October 9; offline snapshot/period switching verified in local regression and live browser checks. Full report arithmetic/period coverage remains unverified. Remaining: full report arithmetic/period coverage. (E3)
- [ ] The application is accessible, including for users with visual impairments. **[NOT VERIFIED]** — Labels exist; keyboard, contrast, screen-reader and chart alternatives need auditing. (E3)
- [ ] The application considers protections against unethical usage, such as employee surveillance. **[PARTIAL]** — Role/team restrictions exist; employee-protection policy/design review remains. (E2)
- [ ] Additional relevant features are considered based on research and audits. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E2)

## Theme 01 — API

### Application architecture

- [x] A standalone API is implemented. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [ ] The API was created without an HTML/JavaScript frontend using appropriate Phoenix generator flags. **[NOT VERIFIED]** — Original generator command is undocumented; Phoenix assets/dev routes remain. (E1)
- [x] The API runs on `localhost:4000` in the required local setup. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] Schema and endpoint nomenclature follows the project subject. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)

### Database schemas

**Users**

- [x] A `users` schema exists. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [ ] `username` is a required, non-null string. **[PARTIAL]** — Changeset requires value, but DB migration leaves column nullable. (E1)
- [ ] `email` is a required, non-null string. **[PARTIAL]** — Changeset requires value, but DB migration leaves column nullable. (E1)
- [ ] Email format is validated (`X@X.X`). **[PARTIAL]** — Regex requires @ but does not enforce a dotted domain (X@X.X). (E1)

**Clocks**

- [x] A `clocks` schema exists. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [ ] `time` is a required, non-null datetime. **[PARTIAL]** — Changeset requires value, but DB migration leaves column nullable. (E1)
- [x] `status` is a required, non-null boolean. **[PASS]** — Required by changeset and null:false migration. (E1)
- [x] `status = true` represents clock-in. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] Each clock entry is associated with a user. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)

**Working Time**

- [x] A `workingtime` schema exists. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [ ] `start` is a required, non-null datetime. **[PARTIAL]** — Changeset requires value, but DB migration leaves column nullable. (E1)
- [ ] `end` is a required, non-null datetime. **[PARTIAL]** — Changeset requires value, but DB migration leaves column nullable. (E1)
- [x] Each working-time entry is associated with a user. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [ ] Working-time dates follow `YYYY-MM-DD HH:mm:ss`. **[PARTIAL]** — Filter accepts space-separated input; schema/JSON use UTC ISO 8601; exact format compatibility needs verification. (E1)

### Mandatory API endpoints

**Users**

- [x] `GET /api/users?email=&username=` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `GET /api/users/:userID` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `POST /api/users` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `PUT /api/users/:userID` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `DELETE /api/users/:userID` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)

**Working Time**

- [x] `GET /api/workingtime/:userID?start=&end=` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `GET /api/workingtime/:userID/:id` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `POST /api/workingtime/:userID` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `PUT /api/workingtime/:id` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `DELETE /api/workingtime/:id` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)

**Clocks**

- [x] `GET /api/clocks/:userID` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] `POST /api/clocks/:userID` **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] The clock POST endpoint supports both arrival and departure and switches clock status appropriately. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)

### Validation and testing

- [x] Database migrations run successfully. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [x] Database structure and associations are checked after migration. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)
- [ ] API endpoints are extensively tested using Postman. **[NOT VERIFIED]** — Automated tests exist; no extensive Postman results were found. (E1)
- [x] API responses and errors are verified. **[PASS]** — Implemented in API/schema/Compose code or supported by migration/test records. (E1)

## Theme 02 — Web Interfaces

### Application structure

- [x] The frontend uses Vue.js. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] The frontend consumes the Time Manager API. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] The application uses one main view defined in `src/App.vue`. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [ ] All required components are located in `src/components`. **[PARTIAL]** — Account functions use Admin/Profile/auth views; reconcile exact User component/method criteria with permitted Theme 05 restructuring. (E3)

### User component

- [ ] A `User` component exists. **[PARTIAL]** — Account functions use Admin/Profile/auth views; reconcile exact User component/method criteria with permitted Theme 05 restructuring. (E3)
- [x] The component identifies the current user. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] User identification is present throughout the application. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [ ] `createUser()` is implemented. **[PARTIAL]** — Account functions use Admin/Profile/auth views; reconcile exact User component/method criteria with permitted Theme 05 restructuring. (E3)
- [ ] `updateUser()` is implemented. **[PARTIAL]** — Account functions use Admin/Profile/auth views; reconcile exact User component/method criteria with permitted Theme 05 restructuring. (E3)
- [ ] `getUser()` is implemented. **[PARTIAL]** — Account functions use Admin/Profile/auth views; reconcile exact User component/method criteria with permitted Theme 05 restructuring. (E3)
- [ ] `deleteUser()` is implemented. **[PARTIAL]** — Account functions use Admin/Profile/auth views; reconcile exact User component/method criteria with permitted Theme 05 restructuring. (E3)

### WorkingTimes component

- [x] A `WorkingTimes` component exists. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [ ] Route `/workingTimes/:userID` exists. **[FAIL]** — Specified URL is absent from frontend router; features are embedded in dashboard. (E3)
- [x] Component contains `userId` data. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] Component contains `workingTimes` data. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] `getWorkingTimes()` is implemented. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] Recorded working times are presented in a summary table. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)

### WorkingTime component

- [x] A `WorkingTime` component exists. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [ ] Creation route `/workingTime/:userid` exists. **[FAIL]** — Specified URL is absent from frontend router; features are embedded in dashboard. (E3)
- [ ] Editing/deletion route `/workingTime/:userid/:workingtimeid` exists. **[FAIL]** — Specified URL is absent from frontend router; features are embedded in dashboard. (E3)
- [x] `createWorkingTime()` is implemented. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] `updateWorkingTime()` is implemented. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] `deleteWorkingTime()` is implemented. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] Working-time records can be created, modified and deleted through the interface. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)

### ClockManager component

- [x] A `ClockManager` component exists. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [ ] Route `/clock/:userid` exists. **[FAIL]** — Specified URL is absent from frontend router; features are embedded in dashboard. (E3)
- [x] `startDateTime` data exists. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] `startDateTime` is `null` when no work period is active. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] `clockIn` boolean data exists. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] `clockIn` is true while a work period is active. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] `refresh()` is implemented. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] `clock()` is implemented. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] Clock actions correctly switch between active and inactive states. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)

### ChartManager component

- [x] A `ChartManager` component exists. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. Note (October 9, 2026): the Punch Card redesign (design-handoff/DESIGN.md) removed it from the dashboard; the file is kept but no page renders it. Decide whether to restore it on `/chartManager/:userid` for Theme 02. (E3)
- [ ] Route `/chartManager/:userid` exists. **[FAIL]** — Specified URL is absent from frontend router; features are embedded in dashboard. (E3)
- [x] At least three graphs are displayed. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [x] Graphs use different visualization types, such as bar, line, pie or radar. **[PASS]** — Present in Vue source, inspected logic and prior build/UI evidence. (E3)
- [ ] Graphs are configurable. **[PARTIAL]** — Options defined in code; no user-facing chart configuration controls. (E3)
- [ ] Vue Router is used if separate components are created for individual charts. **[NOT APPLICABLE]** — All charts remain in ChartManager; no separate chart components need routing. (E3)

### Formatting and UX

- [ ] Dates and times follow `YYYY-MM-DD hh:mm:ss`. **[FAIL]** — UI uses locale formatting and datetime-local, not exact required display format. (E3)
- [ ] The interface is functional and ergonomic. **[PARTIAL]** — Core UI flows work; full ergonomics/accessibility/error-state review remains. (E3)
- [ ] The interface presents information clearly. **[PARTIAL]** — Core UI flows work; full ergonomics/accessibility/error-state review remains. (E3)
- [ ] Appropriate features support a good user experience. **[PARTIAL]** — Core UI flows work; full ergonomics/accessibility/error-state review remains. (E3)

## Theme 03 — DevOps

### Docker architecture

- [x] The application runs using Docker containers. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] A frontend container exists. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] A backend container exists. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] A database container exists. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] At least three containers are used. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] The database uses persistent storage. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] Container configuration allows the services to communicate correctly. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)

### Hosting

- [x] The application is deployed to a server. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] The server is accessible through the internet. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] The deployed application works with its backend and database. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)

### CI/CD pipeline

- [x] Repository changes automatically trigger a pipeline. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] The pipeline compiles the application. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] The pipeline runs project tests. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [x] The pipeline builds the required Docker images. **[PASS]** — Supported by Compose, deployment records and passing GitHub CI. (E4)
- [ ] The pipeline automatically deploys the new application version to the server. **[FAIL]** — Workflow runs build/tests/images only; deployment remains manual. (E4)
- [ ] Changes can be deployed through the pipeline without manually performing the deployment steps. **[FAIL]** — Workflow runs build/tests/images only; deployment remains manual. (E4)

### Optional enhancements

- [ ] Kubernetes is implemented. *(Optional)* **[NOT VERIFIED]** — Optional; no implementation evidence found. Not a mandatory failure. (E4)
- [ ] Application monitoring is implemented, for example Grafana or Kibana. *(Optional)* **[NOT VERIFIED]** — Optional; no implementation evidence found. Not a mandatory failure. (E4)
- [ ] SonarQube or equivalent code-quality analysis is implemented. *(Optional)* **[NOT VERIFIED]** — Optional; no implementation evidence found. Not a mandatory failure. (E4)

## Theme 05 — Authentication

### Roles and database

- [x] Roles are implemented and associated with users. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Roles are predefined. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Role CRUD is not exposed. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Role information can be read through user associations. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] The user schema supports passwords. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Passwords are stored as secure hashes. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Administrator users are initialized in the database. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Employees can belong to multiple teams. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)

### JWT authentication

- [x] JWT authentication uses the Joken library. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] A CSRF token is generated. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] The CSRF token is included in the JWT. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] The JWT is delivered using an HttpOnly cookie. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] The CSRF token is returned at login. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Protected requests verify that the submitted CSRF token matches the one contained in the JWT. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Authentication processing retrieves the user ID from the JWT. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Authentication processing retrieves the user role from the JWT. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Protected endpoints enforce the appropriate permissions. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] API routes are updated to support password-based authentication. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)

### Frontend authentication

- [x] Users can register. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Users can log in. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Users can log out. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Role promotion works through the frontend. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Role demotion works through the frontend. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Relevant buttons and dropdowns trigger the new actions. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Access to protected pages is restricted according to roles. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Team management is available. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)

### Bootstrap-specific criteria

These are specified in the Authentication Bootstrap rather than all being strictly required by the Theme 05 project brief.

- [ ] A 50-character CSRF token is generated. **[FAIL]** — Bootstrap only: token is 43 base64url characters from 32 random bytes, not 50. (E5)
- [x] The JWT includes the user ID. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] The JWT includes the user role. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] The JWT includes the CSRF token. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [ ] The JWT has a 30-day expiry. **[FAIL]** — Bootstrap only: JWT lifetime is 24 hours, not 30 days. (E5)
- [ ] `POST /users/sign_in` authenticates a user. **[PARTIAL]** — Bootstrap only: equivalent /api/auth/login, register and logout exist; exact paths differ. (E5)
- [ ] `POST /users/sign_up` registers a user. **[PARTIAL]** — Bootstrap only: equivalent /api/auth/login, register and logout exist; exact paths differ. (E5)
- [ ] `/users/sign_out` invalidates or removes the authentication session. **[PARTIAL]** — Bootstrap only: equivalent /api/auth/login, register and logout exist; exact paths differ. (E5)
- [x] Password hashing uses an appropriate library, such as Bcrypt. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)
- [x] Vue Router `beforeEach()` is used to check page permissions. **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)

### Recommended structure

- [x] Authentication, registration and profile management are split into separate routed components. *(Recommended, not mandatory.)* **[PASS]** — Verified in authentication code, 27-test validation and recorded deployment/browser checks. (E5)

## Theme 06 — Mobile

### Mobile application

- [ ] A mobile version of the application exists. **[PARTIAL]** — Vue PWA builds with a manifest, cached interface and attendance verified at a 390px viewport. Separate native-app/original mobile brief coverage and real-phone validation remain outstanding. (E6)
- [ ] Every required web application page has a mobile version, except dashboards. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Mobile authentication works. **[PARTIAL]** — PWA online login, cached offline profile, expiry, account isolation and reauthentication are browser-tested; real-phone/native brief verification remains outstanding. (E6)
- [ ] The mobile interface is functional and usable. **[PARTIAL]** — Attendance workflow verified at 390px in a browser; full mobile-page usability and real-device checks remain outstanding. (E6)

### Offline mode

- [ ] The mobile application works when the device is offline. **[PARTIAL]** — Deployed PWA attendance reopens offline after an initial online visit and survives closing the tab; verified on live OVH HTTPS at 390px. Real-phone/native brief and all-page coverage remain outstanding. (E6)
- [x] Relevant application data is stored locally. **[PASS]** — Profile, server attendance snapshot, completed sessions and pending events persist per API/account; browser reopening and account-isolation tests passed locally. (E6)
- [x] Local storage or a mobile database is used for offline persistence. **[PASS]** — IndexedDB snapshots/actions and localStorage profile; no cached passwords or JWT copies. Persistence verified through tab reopening. (E6)
- [x] Clock-in actions can be recorded while offline. **[PASS]** — Real-account offline clock-in queued with UUID and original UTC timestamp; browser tests passed. (E6)
- [x] Clock-out actions can be recorded while offline. **[PASS]** — Real-account offline clock-out persists and projects completed local sessions; browser tests passed. (E6)
- [x] Offline actions are retained until synchronization. **[PASS]** — Persistent queue entries removed only after matching server acknowledgement. Reload, logout, expiry, conflict and lost-response retention verified. (E6)
- [x] Offline changes are automatically synchronized when connectivity returns. **[PASS]** — Reconnect without a button drains the queue; startup/login/focus/visibility and 30-second retry also trigger authenticated synchronization while the app is open. Verified locally and on the live OVH HTTPS deployment. (E6)

### Bootstrap-specific criteria

- [x] Offline requests are maintained in FIFO order. **[PASS]** — Auto-incremented IndexedDB sequence with serial replay and Web Locks; timestamps and ID order verified end to end. (E6)
- [x] Local data is refreshed when the application reconnects. **[PASS]** — Authoritative server clocks/history refresh after successful replay; status/history/statistics use the updated snapshot. Browser tests passed. (E6)
- [ ] Server data is prioritized as described in the Bootstrap. **[PARTIAL]** — Successful replay replaces snapshots with server data; rejected/conflicting events are retained for reconciliation. Exact original Bootstrap conflict policy has not been checked and automatic conflict resolution is not implemented. (E6)
- [x] Synchronization displays progress to the user. **[PASS]** — App.vue shows offline/pending/sync counts, completion, errors and manual retry. Browser scenarios verified. (E6)
- [x] Synchronization errors are handled appropriately. **[PASS]** — Network retries retain events; 401 requests login; 403/422 stop ordered replay and retain remaining actions. Lost response, expiry, conflict and account-isolation tests passed. (E6)

### Recommended mobile UX

- [ ] Navigation uses a tab bar rather than a burger menu. *(Recommended.)* **[FAIL]** — Recommended only; dedicated mobile implementation remains unfinished. (E6)
- [ ] Native device features improve usability and presentation. *(Recommended.)* **[FAIL]** — Recommended only; dedicated mobile implementation remains unfinished. (E6)
- [ ] Layout and controls are adapted to mobile screen sizes. *(Recommended.)* **[FAIL]** — Recommended only; dedicated mobile implementation remains unfinished. (E6)

## Theme 07 — Security

### Penetration testing

- [ ] A penetration test is performed against the application. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] Identified security vulnerabilities are patched. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)

### Injection vulnerabilities

- [ ] XSS vulnerabilities are tested. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] Script injection vulnerabilities are tested. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] HTML injection vulnerabilities are tested. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] SQL injection vulnerabilities are tested. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] NoSQL injection vulnerabilities are considered where applicable. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)

### Configuration and authentication security

- [ ] Public access to sensitive configuration files is tested. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] Password hashes are evaluated for resistance to cracking. **[PARTIAL]** — Bcrypt implemented/tested; cracking-resistance assessment not recorded. (E7)
- [x] Unauthorized access to frontend routes is tested. **[PASS]** — Specific auth/permission checks covered by tests and recorded browser/API verification; not a full penetration assessment. (E5)
- [x] Unauthorized access to backend endpoints is tested. **[PASS]** — Specific auth/permission checks covered by tests and recorded browser/API verification; not a full penetration assessment. (E5)
- [x] JWT cookie HttpOnly protection is checked. **[PASS]** — Specific auth/permission checks covered by tests and recorded browser/API verification; not a full penetration assessment. (E5)
- [ ] Potential JWT theft scenarios are investigated. **[PARTIAL]** — HttpOnly and expiry covered; copied-token revocation/broader theft scenarios remain. (E7)
- [x] Password transmission security is checked. **[PASS]** — October 9 external trusted TLS and browser registration/login verified HTTPS password requests; public app ports are loopback-only and HTTP redirects to HTTPS. Full interception assessment remains separate. (E7)

### Availability and network security

- [ ] The possibility of database flooding or denial of service is tested. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] Appropriate protections are implemented for identified denial-of-service weaknesses. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [x] HTTPS enforcement is verified. **[PASS]** — Owner authorized October 9 OVH cutover: trusted IP certificate, HTTP 308 redirect, Secure/HttpOnly cookies, HTTPS API/login/logout and loopback-only app bindings verified. (E7)
- [ ] Risks of traffic interception over insecure connections are investigated. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)

### Additional security coverage

- [ ] Other relevant attack vectors are investigated. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] The mobile application is included in the security assessment. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] Identified vulnerabilities are fixed and the fixes are verified. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)

### Recommended audit practices

- [ ] Security findings, fixes and verification results are documented. *(Recommended evidence of completed testing.)* **[PARTIAL]** — Incident/auth evidence exists; full security audit report remains. (E7)
- [ ] Testing approaches and findings are discussed with classmates. *(Recommended.)* **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)

## Final Audit Criteria

For the actual implementation audit, assess each requirement using these statuses:

| Status | Meaning |
| --- | --- |
| PASS | Requirement is implemented and verified with evidence. |
| PARTIAL | Some elements are implemented, but the requirement is not fully satisfied. |
| FAIL | Evidence confirms the requirement is missing or incorrectly implemented. |
| NOT VERIFIED | Insufficient evidence is available to determine implementation status. |
| NOT APPLICABLE | The criterion is conditional and its condition does not apply. |

**Evidence should include:** relevant source file paths, API response results, screenshots, automated test output, CI/CD run logs or deployment verification.

**Final rule:** Only mandatory project criteria should determine whether the project satisfies the assignment. Bootstrap-specific criteria should be tracked separately, and recommendations or optional features must not be marked as mandatory failures.
