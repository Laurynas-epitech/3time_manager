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
| October 9, 2026 | Audited and annotated all 195 checklist items; added evidence notes and remaining priorities. | 106 PASS, 31 PARTIAL, 35 FAIL, 22 NOT VERIFIED, 1 NOT APPLICABLE. Existing test/CI evidence is dated October 8; no fresh full live audit was run. |
| October 9, 2026 | Added this legend and the persistent checklist-update workflow. | Documentation change only; implementation statuses and totals are unchanged. HTTPS remains deferred. |
| October 9, 2026 | Organized 16 workspace artifacts into ../_local_artifacts and prepared team-facing plan/instructions and Git ignore rules. | Keys remain in the workspace root. Ignore checks and staged-content scan passed; no requirement statuses changed. Deferred HTTPS changes remain unstaged; no push/deployment performed. |

| October 9, 2026 | Fetched GitHub and compared current branch and local main with origin/main. | Both comparisons: 0 ahead, 0 behind at fd75089. Local staged/untracked work is not published; checklist statuses unchanged. |

| October 9, 2026 | Owner authorized committing and pushing the team plan, progress instructions and ignore rules on chore/project-plan-and-gitignore. | Staged files reviewed and diff checks passed. Deferred HTTPS changes excluded; application criteria/totals unchanged. |
| October 9, 2026 | Frontend only: daily/weekly hours over a selected period, "Punch Card" redesign (design-handoff/) of the app shell, Employee Today and Manager My team (`/team`, admins: "Dashboards" incl. "Everyone"), read-only Teams page for employees, punch edit fixes (scroll/inline edit, visible errors), toasts. No backend change. | Checked locally in headless Chromium (desktop 1440px + mobile 390px, no horizontal overflow; add/edit/delete punch, role redirects, employee team edits rejected by the API with 403). 4 items FAIL → PARTIAL (period/daily/weekly dashboards, individual hours); totals updated. Remaining redesign screens: Teams, People, Profile. ChartManager no longer rendered (Theme 02 decision pending). Not deployed to OVH. |

## User-approved scope and priorities

Use the final checklist below as the project plan: Main Project and Themes 01, 02, 03, 05, 06, 07. Theme 04 is excluded. Source: `C:\Users\laury\Downloads\TIME_MANAGER_FINAL_CHECKLIST.md`. The full checklist with inspected status is included below so the plan does not depend on the Downloads file remaining available.

The source checklist says it has not been independently reverified against assignment documents. Consult the original brief when an exact criterion or conflict needs clarification. Mandatory requirements determine assignment completion. Track bootstrap-specific items, recommendations and optional enhancements separately; do not turn them into mandatory failures.

## Persistent user decision: HTTPS deferred

The user explicitly chose to defer HTTPS and stick with HttpOnly JWT cookies for the current theme work. Keep JWT authentication, password hashing, CSRF checks and backend permissions intact. No HTTPS cutover is authorized. The pending HTTPS approval question was superseded by this decision; do not apply the prepared server setup.

HTTPS is not explicit in the supplied Theme 05 project criteria. However, the final checklist explicitly includes HTTPS enforcement and insecure-traffic interception testing under Theme 07. Therefore HTTPS is deferred, not permanently removed from the project plan. Revisit it with the user during Theme 07; do not silently mark that criterion complete or exempt it. HttpOnly prevents JavaScript from reading the cookie; it does not encrypt HTTP traffic.

## Current implementation baseline and evidence

- Theme 05 integration PR #4 was merged. Local main was fast-forwarded to `fd75089` (merge of `2160cfc`).
- Backend `mix precommit`: 27 tests, zero failures, in disposable PostgreSQL 16 containers without production mounts.
- Frontend production build passed. PR #4 GitHub CI passed frontend build, backend tests, and Docker image builds.
- See `THEME05_VALIDATION.md`, `AUTHENTICATION_SETUP.md`, and `DATABASE_OPERATIONS.md` for detailed validation and deployment records. These records support specific findings, not blanket completion of every final checklist item.
- The clean application database and authentication were deployed earlier; original incident database/evidence remains preserved. Never delete or initialize incident volumes.
- Prepared, uncommitted HTTPS work is on branch `https-secure-cookies`: `HTTPS_SETUP.md`, `docker-compose.https.yml`, `ops/enable-https.sh`, Nginx/renewal files, and localhost port changes in `docker-compose.secure.yml`. They were not applied to OVH. Preserve them as deferred work; do not deploy or publish automatically.
- Existing implementation uses `employee`, `manager`, `admin` roles. The Main Project checklist names Employee, Manager, General Manager. Verify semantic coverage and required naming before marking this criterion PASS.
- No mobile implementation or completed Theme 07 penetration assessment has been verified in this session.
- CI is verified; automatic CD remains outstanding in the available evidence.
- The older `../_local_artifacts/EPITECH_TIME_MANAGER_CURRENT_HANDOFF.md` describes an earlier incident/recovery checkpoint and is stale where it conflicts with later deployment records.

## Workspace organization and team publication

- Application repository: `3time_manager` (this folder). Run Git commands here, not from the outer workspace.
- Temporary validation folders, archives, deployment helpers and historical handoffs: `../_local_artifacts/`, preserved outside the repository.
- SSH keys: `../time` and `../time.pub`; left in place to keep existing SSH commands working. Never stage them.
- Team documents: `MEMORY.md`, `AGENTS.md`, authentication/database runbooks and validation notes. Keep these tracked.
- Repository `.gitignore` excludes secrets, private keys, backups/archives, incident evidence and generated outputs. Existing dependency/build ignores remain; lockfiles, migrations, source and `.env.example` remain eligible for tracking.
- The outer workspace `.gitignore` provides an additional guard if someone initializes Git there; it is outside this repository and is not part of its team commit.
- Deferred HTTPS work remains uncommitted and unstaged. Review explicit staged files rather than using `git add .` for this preparation.

## Checklist status and remaining work

Checked boxes mean PASS. Unchecked boxes distinguish PARTIAL, FAIL, NOT VERIFIED and NOT APPLICABLE; they do not all mean missing implementation. This is a repository/evidence audit, not a fresh live-server or full browser/security test run. Previous passing checks are dated October 8, 2026.

| Scope | PASS | PARTIAL | FAIL | NOT VERIFIED | NOT APPLICABLE |
|---|---:|---:|---:|---:|---:|
| All checklist items | 106 | 35 | 31 | 22 | 1 |
| Mandatory items only | 100 | 31 | 21 | 18 | 1 |

### Concrete remaining priorities

1. Reconcile General Manager/admin naming and responsibilities; manager team creation is admin-only while managers can manage memberships.
2. Add per-day/per-week individual and team aggregates and period selection; existing average is per entry, not average daily/weekly team hours.
3. Enforce database NOT NULL constraints for required fields with reviewed data-preserving migrations; tighten email validation to the required format.
4. Reconcile the Theme 02 named routes/User component criteria with the later authentication views; add needed compatibility routes and exact date/time presentation, plus chart controls and accessibility verification.
5. Add safe automatic CD; existing CI already passes.
6. Build Theme 06 mobile/offline functionality after checking its original documents.
7. Complete Theme 07 assessment/fixes/retests, including mobile; revisit deferred HTTPS with the user.
8. Collect missing Postman, UX, accessibility and employee-protection evidence. Bootstrap-only mismatches are tracked separately and do not by themselves invalidate Theme 05.

### Evidence keys used below

- **E1 - API/data:** `backend/lib/time_manager_web/router.ex`, user/clock/working-time schemas, `backend/priv/repo/migrations/`, API controller/tests; `DATABASE_OPERATIONS.md` migration/restore record. The required local port is configured, not freshly exercised on Windows.
- **E2 - Account/role/team behavior:** `backend/lib/time_manager_web/authorization.ex`, UserController/TeamController, `frontend/src/views/ProfileView.vue`, AdminView, TeamsView, DashboardView; `backend/test/time_manager_web/controllers/permissions_test.exs`. General Manager-specific items remain PARTIAL because the implemented role is named admin. Profile self-deletion exists in code; every-role browser deletion was not repeated.
- **E3 - Web/chart evidence:** `frontend/src/App.vue`, `frontend/src/router.js`, `frontend/src/components/{WorkingTimes,WorkingTime,ClockManager,ChartManager}.vue`, `frontend/src/views/`; frontend build and prior UI checks in `AUTHENTICATION_SETUP.md`. ChartManager has bar/line/pie views of per-record durations, not verified daily/weekly aggregates.
- **E4 - Infrastructure:** `docker-compose.yml`, `docker-compose.secure.yml`, Dockerfiles, `.github/workflows/ci.yml`, `DATABASE_OPERATIONS.md`, `AUTHENTICATION_SETUP.md`; successful [PR #4 CI run](https://github.com/Laurynas-epitech/3time_manager/actions/runs/37793116761). Prepared HTTPS edits are not deployed infrastructure evidence.
- **E5 - Authentication:** `THEME05_VALIDATION.md`, `AUTHENTICATION_SETUP.md`, `backend/lib/time_manager/auth/token.ex`, AuthCookie/Authenticate, seeds, role/team migrations, `frontend/src/auth.js`, API/router/views and backend tests. 27 tests passed. JWT includes the issued role; request authorization reloads current role from DB so demotions take effect. Logout clears the cookie but cannot revoke an already copied JWT.
- **E6 - Mobile:** no dedicated mobile app, service worker/offline queue or mobile persistence implementation found in the repository. Layout responsiveness does not establish mobile/offline completion.
- **E7 - Security:** incident/auth records document some issues; no complete Theme 07 penetration-test/injection/DoS/mobile report was found. Unverified security criteria must be investigated on authorized isolated targets, not assumed passed.

## Next work sequence

1. Audit the current Main Project and Themes 01/02/03/05 against the final checklist. Record PASS, PARTIAL, FAIL, NOT VERIFIED, or NOT APPLICABLE with evidence. Do not infer completion from filenames or merged PRs alone.
2. Resolve confirmed mandatory gaps, including dashboards/team aggregates, route/component compatibility and automatic deployment where required. Do not redesign features solely for optional recommendations.
3. Review original Theme 06 documents before implementation choices; build the required mobile pages/authentication and offline clocking/persistence/synchronization. Keep bootstrap FIFO/progress/error requirements separately classified.
4. Perform Theme 07 security testing against authorized isolated/test targets; patch and verify findings. Include mobile and revisit HTTPS at that stage. A checklist entry does not authorize flooding or denial-of-service testing against the live OVH service.
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
- [ ] Managers and the General Manager can view an individual employee's daily and weekly working hours over a selected period. **[PARTIAL]** — Implemented in `frontend/src/components/HoursReport.vue` (period chips + custom dates, daily bars up to 14 days, weekly bars beyond, total / per week / per worked day / days worked, accessible table) on Today and on /team (`MyTeamView.vue`); checked in a local headless browser on October 9, 2026 (Europe/Paris, midnight-crossing session split correctly). Not yet deployed or covered by automated frontend tests. Managers reach their team members (backend still returns 403 outside their teams) and admins everyone via /team. Remaining: deployment evidence and the General Manager/admin naming. (E3)
- [ ] Managers and the General Manager can view their employees' dashboards. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)
- [ ] The General Manager can promote an employee to Manager. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)
- [ ] The General Manager can view all users' dashboards. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)
- [ ] The General Manager can delete any user's account. **[PARTIAL]** — Implementation uses admin rather than General Manager; reconcile naming and required semantics. (E2)

### Dashboards, accessibility and employee protection

- [ ] Dashboards display daily working hours. **[PARTIAL]** — Implemented in `frontend/src/components/HoursReport.vue` (period chips + custom dates, daily bars up to 14 days, weekly bars beyond, total / per week / per worked day / days worked, accessible table) on Today and on /team (`MyTeamView.vue`); checked in a local headless browser on October 9, 2026 (Europe/Paris, midnight-crossing session split correctly). Not yet deployed or covered by automated frontend tests. Remaining: deployment evidence. (E3)
- [ ] Dashboards display weekly working hours. **[PARTIAL]** — Implemented in `frontend/src/components/HoursReport.vue` (period chips + custom dates, daily bars up to 14 days, weekly bars beyond, total / per week / per worked day / days worked, accessible table) on Today and on /team (`MyTeamView.vue`); checked in a local headless browser on October 9, 2026 (Europe/Paris, midnight-crossing session split correctly). Not yet deployed or covered by automated frontend tests. Remaining: deployment evidence. (E3)
- [ ] Dashboard data can be viewed over a selected period. **[PARTIAL]** — Implemented in `frontend/src/components/HoursReport.vue` (period chips + custom dates, daily bars up to 14 days, weekly bars beyond, total / per week / per worked day / days worked, accessible table) on Today and on /team (`MyTeamView.vue`); checked in a local headless browser on October 9, 2026 (Europe/Paris, midnight-crossing session split correctly). Not yet deployed or covered by automated frontend tests. Remaining: deployment evidence. (E3)
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

- [ ] A mobile version of the application exists. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Every required web application page has a mobile version, except dashboards. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Mobile authentication works. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] The mobile interface is functional and usable. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)

### Offline mode

- [ ] The mobile application works when the device is offline. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Relevant application data is stored locally. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Local storage or a mobile database is used for offline persistence. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Clock-in actions can be recorded while offline. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Clock-out actions can be recorded while offline. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Offline actions are retained until synchronization. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Offline changes are automatically synchronized when connectivity returns. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)

### Bootstrap-specific criteria

- [ ] Offline requests are maintained in FIFO order. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Local data is refreshed when the application reconnects. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Server data is prioritized as described in the Bootstrap. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Synchronization displays progress to the user. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)
- [ ] Synchronization errors are handled appropriately. **[FAIL]** — No dedicated mobile/offline persistence or synchronization implementation found. (E6)

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
- [ ] Password transmission security is checked. **[PARTIAL]** — HTTP transport risk identified; encrypted transmission remains deferred. (E7)

### Availability and network security

- [ ] The possibility of database flooding or denial of service is tested. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] Appropriate protections are implemented for identified denial-of-service weaknesses. **[NOT VERIFIED]** — Needs evidence/review; not marked complete. (E7)
- [ ] HTTPS enforcement is verified. **[FAIL]** — DEFERRED by owner: HTTPS files are prepared but not deployed. Revisit for Theme 07. (E7)
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
