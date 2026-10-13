# Independent audit against the supplied project checklist

Date: October 13, 2026 (Europe/Paris).

## Verdict

This is a substantial working application, but the complete assignment is unfinished. Authentication is the strongest completed area. Core attendance, account management, individual reporting, containers and offline attendance exist. Team averages, reachable three-chart functionality and automatic deployment are confirmed gaps. Whole-application mobile/offline coverage, accessibility and the breadth of security assurance remain incomplete.

The existing tracker reports **99/165 applicable mandatory rows fully verified (60.0%)**, with 52 partial, nine failed and five unverified. That is a different, finer-grained checklist which excludes Theme 04. It is useful context, **not a newly calculated percentage for the supplied eight-section checklist**, not an assignment grade and not a measure of development effort. Including Theme 04 prevents presenting that number as completion of all eight sections. No defensible exact overall percentage follows without agreeing how to weight these overlapping requirements.

Only Theme 05 has sufficiently strong evidence to call its listed assignment functionality substantially complete. The other technical themes have material gaps or verification limits. Theme 04 was deliberately excluded from the prior project scope; no deliverable was identified in the inspected repository. It remains unfulfilled against this newly supplied full checklist unless excluded from submission by agreement.

## Scope and independence

### Finding validity and importance review (October 13, 2026)

A second source review confirms the main implementation gaps. However, this report mixes confirmed defects, assignment compatibility questions and missing verification. These should not receive the same priority. This review inspected source and retained evidence; it did not repeat runtime/security checks or independently re-extract the original assignment.

| Finding | Review verdict | Practical importance |
|---|---|---|
| Team daily/weekly averages | Confirmed missing: MyTeamView selects one person and passes selected.id to HoursReport; team clock-status counts are not hour averages. | High for the stated core reporting requirement. |
| Three charts and graph configuration | Confirmed unreachable: ChartManager appears only in its own source, with no importing view or route. | High for Theme 02 submission; existing bar reporting still works. |
| Automatic deployment | Confirmed absent from inspected CI: frontend/backend/Docker jobs only, without publication or rollout. | High for the stated DevOps requirement; does not mean manual hosting is broken. |
| Manual interval ordering | Confirmed missing server validation: create/update use a changeset that only casts and requires fields. Reversed intervals can be submitted directly to the API. | High for data correctness. The clock-transition path separately checks chronological order. Overlap rejection requires an agreed policy; automatic rejection is not itself an established assignment requirement. |
| Copied JWT after logout/password change | Logout only deletes the cookie; authentication checks signature, expiry, CSRF and current DB user, without session revocation. Retained assessment records post-logout replay returning 200. | Meaningful security hardening, especially for a stolen admin session, with up to the remaining 24-hour JWT lifetime. Requires possession of both cookie and CSRF; this review establishes no token-stealing exploit. Not an automatic failure of the required logout UI. |
| Required database fields nullable | Confirmed in migration source, without subsequent NOT NULL alterations for these fields. | Medium: explicit schema compliance/data integrity. Normal application writes already validate required values; this is not evidence that API clients can insert nulls. Actual live DB schema was not inspected. |
| Period filter excludes intersecting sessions | Confirmed containment query. A 23:00-01:00 shift is excluded from a filter starting at midnight. | Medium/API contract question: a defect if the contract means all hours intersecting the period; valid if it means fully contained sessions. Frontend reports clip full history and are not established broken by this query. |
| Literal frontend URLs | Confirmed absent, but later route-recreation permission is recorded in MEMORY. | Conditional submission compatibility, not a confirmed user-facing functional defect. Resolve against the accepted brief before prioritizing aliases. |
| Whole-app offline support | Profile/team/admin operations use network APIs without attendance-style offline mutation queues. | Real scope limitation; priority depends on whether offline requirements cover those operations or principally attendance. Offline first-time authentication should not be invented as a mandatory capability without explicit wording. |
| Theme 04 deliverable | Explicitly excluded by persistent user decision in MEMORY. | Outside the agreed project scope. Do not treat it as required remaining work unless the user changes scope or submission rules establish otherwise. |
| Accessibility, phone testing, DST, broad pentest/user research | Incomplete evidence, rather than demonstrated failures. time.js uses calendar-day boundaries and elapsed milliseconds; a DST bug was not established. | Targeted verification is useful. Lack of exhaustive testing alone does not prove broken functionality or require unlimited testing for completion. |
| Email regex/date serialization | Regex is permissive; typed UTC timestamps and localized display are present. | Low/conditional. Acceptance of a@b alone does not prove a vulnerability or an agreed validation failure. Date format interpretation needs the brief, not a storage rewrite. |
| Ethical data policies/retention controls | Useful suggestions, but MEMORY classifies employee-protection features as recommended. | Do not promote suggested policies or new controls into mandatory implementation gaps. |

The findings are largely source-backed, not fabricated. The report's broad partial statuses and 60% row count should not be read as a defect count or a grade. The statement that only authentication is substantially complete reflects a strict verification threshold, not proof that the remaining features mostly fail. Prioritize team averages, reachable charts, CD and manual interval validation; assess session revocation separately as security hardening. Treat excluded scope, contract ambiguities and verification gaps explicitly.

- Baseline: local Git HEAD `87bc705`, plus the existing modified and untracked files. This audit assesses the actual working tree, including pending security changes, rather than assuming HEAD contains everything.
- Input: the user's attached `Pasted text.txt` containing Main Project and Themes 01–07. Original PDFs were not re-extracted during this audit. Brief interpretation recorded in MEMORY is treated as prior evidence, not independently re-established assignment wording.
- Independently inspected frontend routes and mounting, account/admin/team/report/clock code, backend routes/controllers/authorization, schemas/migrations, JWT/CSRF/cookies, attendance synchronization, Compose and CI.
- Read dated validation reports and relevant test assertions. Reports demonstrate recorded checks within their stated scope; their existence does not prove every feature or the current public server state.
- Fresh checks here: `node --test tests/pagination.test.js` **4/4 passed**; `npm.cmd run build` **passed**, including generated PWA service worker. PowerShell initially blocked `npm.ps1`; invoking `npm.cmd` resolved this without changing execution policy.
- Elixir `mix` was unavailable on PATH. Backend tests, browser scenarios, database migrations, live server/CI and physical devices were **not freshly exercised** here. The retained 52-test backend and 42-case browser results are prior same-day evidence.
- No app fixes, migrations, deployment, external attack traffic or production-data changes were performed. This audit and the required tracking updates are documentation changes.

Status meanings: **Implemented** = source establishes the feature, with supporting results where available; **Partial** = meaningful implementation exists but listed scope or verification is incomplete; **Missing** = source confirms a gap; **Unverified** = insufficient evidence; **N/A** = inactive conditional requirement. Implemented does not mean exhaustively tested.

## 1. Core application — partial

| Supplied requirement | Assessment | Evidence and limits |
|---|---|---|
| Employee, Manager, General Manager; role-appropriate functions | Implemented | Predefined employee/manager/admin roles, frontend guards and backend Authorization. Admin supplies the General Manager privilege model; this is a functional mapping, not a missing fourth role. |
| Managers organize employees into teams; team management | Partial | Teams UI, membership endpoints and managed-team checks exist. Team create/update/delete are admin-only; managers manage membership within existing authorized assignments. Confirm whether this restricted team lifecycle meets the expected manager scope. |
| Edit and delete own account | Implemented | ProfileView save/remove, user update/delete, self-or-admin authorization; historical profile/self-delete evidence. Full all-role regression was not repeated. |
| Clock in and clock out | Implemented | ClockManager, clock controller, attendance service; recorded online/offline/replay checks. |
| Own dashboard; daily/weekly times; reporting period | Implemented, verification incomplete | DashboardView, WeekCard, HoursReport, date chips/custom range, midnight splitting. DST, overlap and all arithmetic boundaries lack comprehensive evidence. |
| Team average daily and weekly hours over selected period | Missing | MyTeamView chooses individual users; HoursReport accepts one userId. No team aggregation/denominator or team-wide period average was found. Individual per-week/per-worked-day tiles do not meet this requirement. |
| Individual employee daily/weekly hours; employee dashboards | Implemented, verification incomplete | Manager-selected user report on `/team`; API scopes to managed members. Full all-role/target matrix was not freshly run. |
| General Manager promotes employees, views all dashboards, deletes any account | Implemented, verification incomplete | AdminView role/deletion controls, admin Everyone group, admin API permissions. Broad role/target edge cases remain beyond retained targeted checks. |
| Accessibility for visually impaired users | Partial | Labels, status/alert regions, chart table equivalent and semantic navigation exist. No full keyboard, screen-reader, contrast/zoom audit establishes application-wide accessibility. |
| Safeguards against unethical data use | Partial | Scoped access and restricted membership grants reduce exposure. No complete employee-data policy, purpose/retention controls or documented stakeholder acceptance evidence was identified. Treat the checklist's consideration requirement separately from inventing mandatory extra features. |
| Adapt features through user research/audits | Partial | Security audits demonstrably led to fixes. Stakeholder needs research and traceable product decisions remain unverified; technical security work alone does not establish user research. |

## 2. Theme 01 API — implemented routes, incomplete data guarantees

All **12 supplied method/path combinations are declared** in `backend/lib/time_manager_web/router.ex`, with matching controller actions:

| Method | Exact supplied path | Assessment |
|---|---|---|
| GET | `/api/users?email=XXX&username=YYY` | Implemented: scoped filtering; exhaustive filter combinations not freshly tested |
| GET | `/api/users/:userID` | Implemented: authorized profile read |
| POST | `/api/users` | Implemented: admin-only creation with password support |
| PUT | `/api/users/:userID` | Implemented: self/admin update |
| DELETE | `/api/users/:userID` | Implemented: self/admin delete |
| GET | `/api/workingtime/:userID?start=XXX&end=YYY` | Partial: containment filter excludes intervals overlapping a period boundary |
| GET | `/api/workingtime/:userID/:id` | Implemented: owner-scoped record lookup |
| POST | `/api/workingtime/:userID` | Implemented: permitted manager/admin creation |
| PUT | `/api/workingtime/:id` | Implemented: authorized edit; body cannot change owner |
| DELETE | `/api/workingtime/:id` | Implemented: authorized delete |
| GET | `/api/clocks/:userID` | Implemented: authorized clock history |
| POST | `/api/clocks/:userID` | Implemented: in/out handling and UUID replay protection |

Route existence is independently verified; it is not a fresh 12-endpoint execution result. Protected creation/edit behavior should be assessed with the later role requirements, not failed merely because anonymous callers cannot mutate records.

| Other supplied requirement | Assessment | Evidence and limits |
|---|---|---|
| Users table, username/email, email validation | Partial | User changeset requires values and validates email. Regex `^[^\s]+@[^\s]+$` accepts weak forms such as `a@b`; actual validation policy should be defined. DB username/email remain nullable. |
| Clocks table, time/status/user; boolean status | Partial | Typed schema and required changeset; only status has `null: false` in the original migration. Time and owner remain nullable. |
| Workingtime table, start/end/user | Partial | Typed schema/required changeset, but DB start/end/owner remain nullable. |
| Required values, no nulls | Partial | Application changesets cover normal writes; migrations do not enforce all required database constraints. API checks are not database guarantees. |
| Date/time format | Partial | UTC datetime columns; ISO serialization/local browser storage; space-separated UTC filter helper. Exact prescribed storage/serialization interpretation remains unresolved. Do not replace typed database dates with text merely to satisfy a literal display string. |
| Migrations work | Implemented with dated evidence | Migration source and recorded migration/restore checks exist; no fresh empty-DB migration or upgrade check here. |
| Correct database CRUD, all endpoints, thorough tests | Partial | Auth, permissions, clocks and security test suites plus recorded results. No fresh full CRUD/filter/malformed-ID suite for all 12 endpoints, nor comprehensive coverage evidence. Postman itself is recommended, not compulsory. |

Additional correctness concern: `WorkingTime.changeset` validates presence but not end-after-start or overlapping sessions. Manual bad intervals can yield incorrect/double-counted reports. The GET filter uses `w.start >= start AND w.end <= end`; it does not include all sessions intersecting a period. The frontend's full-history clipping reduces that specific UI issue but does not change API semantics.

## 3. Theme 02 web interfaces — partial

| Supplied requirement | Assessment | Evidence and limits |
|---|---|---|
| Vue; App.vue main shell; components in src/components; API connection | Implemented | Vue app/router and connected components; fresh production build passed. |
| Persistent current-user display | Implemented | App.vue mounts AppHeader, which shows account identity/role and navigation. |
| User create/update/get/delete | Implemented functionally | Registration/AdminView, ProfileView, auth session/me and API calls provide these operations. Literal single User component/method naming is absent; prior brief review records permission to split account/auth components. |
| WorkingTimes summary, userId/workingTimes/getWorkingTimes | Implemented | Component is mounted in dashboard/team views; presents attendance summaries. Cards/list should not be failed solely for lacking an HTML table where brief wording permits a summary. |
| `/workingTimes/:userID` | Missing | Not in frontend router. |
| WorkingTime individual creation/update/delete | Implemented | Connected editor/history controls exist; recorded CRUD browser checks. |
| `/workingTime/:userid` and `/workingTime/:userid/:workingtimeid` | Missing | Neither client route is defined. |
| ClockManager startDateTime, clockIn, refresh(), clock(), toggling | Implemented | Explicit state/methods in mounted component and attendance service. |
| `/clock/:userid` | Missing | No frontend route; API `/api/clock` alias does not satisfy a browser URL. |
| ChartManager, three charts, configurable/different graph types | Partial implementation, missing reachable feature | ChartManager.vue contains Bar/Line/Pie and options, but is neither mounted by current views nor routed. Source code for dormant charts is not delivered UI functionality. HoursReport supplies one daily/weekly bar presentation. End-user graph configuration is not established by static Chart.js options. |
| `/chartManager/:userid` | Missing | Not in client router. Backend endpoint is a working-time list, not a mounted frontend chart page. |
| Vue Router for separated charts | N/A condition | ChartManager's graphs are inline; app otherwise uses Vue Router. |
| Specified date/time format | Partial | See Theme 01 storage/serialization caveat; localized UI is not independently a failure. |
| Ergonomics and clear information | Partial | Consistent shell, date controls, feedback, mobile tabs, table alternative. No independent user usability study; unavailable status can appear as clocked-out/zero after fetchStatus catches errors. |

The later brief's recorded route-recreation allowance makes literal URL compliance an interpretation issue. The supplied checklist explicitly requests these URLs, and the actual router lacks them. Provide compatible aliases or obtain a documented assessment interpretation; do not silently mark them satisfied.

## 4. Theme 03 DevOps — partial

| Supplied requirement | Assessment | Evidence and limits |
|---|---|---|
| Docker frontend/backend/database containers | Implemented | Compose services and Dockerfiles; dated deployment records. Not freshly started here. |
| Database restart persistence | Implemented with dated evidence | Named postgres_data volume and recorded backup/restore/deployment preservation; no fresh restart here. |
| Hosted server and public internet access | Recorded implementation; current state unverified | October 13 deployment report records OVH HTTPS release 87bc705. No fresh remote request in this audit. |
| Automated pipeline triggered by repository changes | Partial | Push/PR workflow for main only. A push to the integration branch alone does not match; no frontend test step. |
| Automatic compile/build and tests | Implemented | Frontend build/backend compile+tests declared; dated successful CI record. Current pending assessment changes are not assumed to have passed remote CI. |
| Automatic Docker image builds | Implemented | Docker job depends on frontend/backend jobs. |
| Automatic deployment after repository changes | Missing | No deploy job, image publication/server rollout or equivalent deployment hook identified. Manual deploy script and manual release records do not satisfy CD. |

Kubernetes and the named observability/quality tools are optional and receive no deduction.

## 5. Theme 04 change resistance — no assessed deliverable

The previous tracking document explicitly excludes Theme 04 by a persistent user decision. This audit preserves that scope decision and does not change its old denominator. Against the attached full checklist, however, no repository evidence was identified for stakeholder identification, employee concerns/demands, targeted corrective communication, simplicity mockups, audience-specific formats, produced communication materials or an explanation of acceptance/tension outcomes.

Assessment: **unverified outside the repository / absent from inspected deliverables**, rather than claiming such work cannot exist elsewhere. Generic project README/runbooks and implementation screenshots are not enough to establish the organizational assignment. If all eight themes are required for submission, this needs a dedicated deliverable or an explicit exclusion agreement. No requirement to produce every suggested media format is invented.

## 6. Theme 05 authentication/authorization — strongest area

| Supplied requirement | Assessment | Evidence and limits |
|---|---|---|
| Roles/password schema, predefined roles, full-permission administrators | Implemented | User/role schema, migrations, seeds and admin authorization. Password hash/role database nullability remains a data-hardening limitation noted above. |
| Employees in multiple teams | Implemented | many_to_many team_users relation and team context/UI. |
| JWT using Elixir Joken | Implemented | Token module uses Joken.Config, signed claims and expiry. |
| Create CSRF token; embed in JWT; return at login | Implemented | Cryptographic generation, csrf claim and sign-in response. |
| JWT HttpOnly cookie | Implemented | AuthCookie; Secure configured for deployed TLS; dated browser checks. |
| Verify X-CSRF-Token against JWT | Implemented | Authenticate verifies signature/claims and constant-time CSRF comparison. |
| Authenticated identity/role from token | Implemented with stronger current-role check | user_id locates DB user; role claim exists, but effective role is read from DB so demotion takes effect without trusting stale JWT role. |
| Secure password storage/verification and password routes | Implemented | Bcrypt, eight-character minimum/72-byte maximum, login verification and profile password changes. |
| Registration/login/logout/profile controls | Implemented | Connected views/auth/API; recorded registration/session/logout checks. Logout clears the browser session, but copied tokens remain valid. |
| Promotion/demotion UI | Implemented | AdminView and admin-only role update. Self-demotion restriction is deliberate. |
| Role page restrictions and API enforcement | Implemented | Router guard, admin pipeline and resource authorization; recorded permissions/security tests. |
| Teams functionality | Implemented with scope caveat | Team/member UI/API and assignment checks. Manager lifecycle restriction remains the Core caveat. |

This does not mean authentication is free of security issues: copied-session revocation after logout/password changes remains unresolved. The requirement to have a logout UI/API is distinct from proving comprehensive session-theft resilience.

## 7. Theme 06 mobile/offline — attendance implemented, full scope partial

| Supplied requirement | Assessment | Evidence and limits |
|---|---|---|
| Mobile version | Implemented as responsive PWA | Service-worker app shell, installable manifest and mobile navigation. A native app is not mandated by the supplied checklist. |
| Every non-dashboard page mobile-compatible | Partial | Responsive layouts and retained 390px auth/admin/team/security checks; no full role/page/device/keyboard matrix. Dashboard exemption does not excuse profile/team/admin coverage. |
| Mobile authentication | Implemented, device coverage partial | Shared auth and recorded narrow viewport login/session checks; no fresh phone test. |
| Offline mode and reconnect synchronization throughout application | Partial | Attendance cache/session/queue persist; profile, team and admin datasets/mutations are not fully offline-enabled. Previously authenticated sessions can reopen; offline first-time login/registration is not established. |
| Offline employee clock-in and clock-out | Implemented with dated tests | ClockManager -> attendance IndexedDB queue; recorded reload/new-tab and in/out scenarios. |
| Retain records locally | Implemented | IndexedDB snapshots/actions; service worker caches app shell. |
| Synchronize offline clock records with backend | Implemented with dated tests | Online-event synchronization, original timestamps/UUIDs, FIFO/retry/conflict handling and backend deduplication; local and deployed attendance results recorded. |

Remaining: full non-dashboard offline expectations, real-phone/shared-device checks and local-data privacy. Device data is editable/unencrypted; backend authorization, not cached role state, remains the authority.

## 8. Theme 07 security — real testing/remediation, incomplete assurance

| Required area | Assessment | Evidence and limits |
|---|---|---|
| Perform penetration testing, identify vulnerabilities, fix findings | Partial but substantive | Actual controller/browser/resource/transport checks and fixes are documented. Not merely a hypothetical threat list. Limited controlled scenarios do not establish a comprehensive pentest. |
| XSS; script and HTML injection | Tested within limited scope | Recorded 42 stored injection cases across roles/two widths, escaped Vue output; no complete DOM/sink/infrastructure audit. |
| SQL injection | Tested within limited scope | Bound Ecto queries and SQL-style input assertions; no exhaustive endpoint/filter/database-permission audit. |
| NoSQL injection | N/A | PostgreSQL backend; no identified NoSQL query layer. |
| Sensitive configuration exposure | Tested within limited scope | Diagnostic/sensitive-path checks and narrow history pattern scan; not a full secret/history/host audit. |
| Weak hashes/password cracking | Partial | Bcrypt cost-12 timing and password validation recorded. Rate limiting helps online guessing; no broad password-policy/cracking exercise. |
| Unauthorized frontend/API access | Tested within limited scope | Guards, ownership/role/mass-assignment tests, offline role-tamper 403 and real DB role response. All possible role/resource combinations not established. |
| DB flooding/DoS | Partial | Read caps, write/auth limits, bounded 40-read probe and frontend rendering caps. No sustained/concurrent/distributed capacity or exhaustion assessment. |
| JWT HttpOnly cookie | Implemented and recorded tested | Source cookie flags plus local/live checks. |
| Recovering/stealing tokens | Partial; confirmed outstanding risk | Copied cookie plus CSRF returned 200 after logout in recorded local assessment. No JWT revocation after logout/password change. |
| Password transmission and HTTPS-only access | Recorded implementation/test | Deployed TLS/HTTP redirect/Secure cookie checks and local dummy-credential observer. No fresh public certificate/port check here. |
| HTTP interception | Partial | Recorded HTTP marker visible/TLS marker absent, certificate trust rejection/acceptance; does not prove resistance to trusted malicious CA or compromised devices. |
| Mobile security | Partial | Offline role tampering tested; unencrypted editable cache, physical-phone/shared-device scenarios remain. |
| Other vectors | Partial | Malformed bodies, hostile offsets, redirect/proxy spoofing, role/owner assignment, bounded queries covered by source/recorded tests. Broader dependency/infrastructure review and incident analysis remain. |

The local input/filter/offset and bounded frontend list changes are **pending**, while the documented public release is **87bc705**. Its recorded deployment checks must not be extended to these unreleased changes.

## Priority to reach submission completeness

1. Implement team-wide daily/weekly averages with explicit denominator, selected period and representative arithmetic verification.
2. Mount the three-chart feature, supply user graph configuration, and resolve the required client URL contracts.
3. Add automated server deployment after successful CI with a reviewable rollout/rollback path; integrate relevant frontend checks into CI.
4. Add data-preserving NOT NULL constraints and validate manual interval ordering/overlap policy; verify period-boundary API semantics and report DST arithmetic.
5. Resolve Theme 04 submission scope and provide the communication deliverable if required; document stakeholder research and accessibility outcomes.
6. Finish non-dashboard mobile/offline scope and device coverage. Do not call attendance-only offline support whole-application offline completion.
7. Address copied-token revocation; broaden security checks to remaining relevant areas, then release/retest pending fixes. Keep every claim tied to the revision and scope actually tested.

## Evidence references

- Structure/contracts: `frontend/src/{App.vue,router.js,auth.js,api.js,time.js}`, `frontend/src/components/{AppHeader,ClockManager,WorkingTimes,WorkingTime,HoursReport,ChartManager}.vue`, `frontend/src/views/{DashboardView,MyTeamView,TeamsView,AdminView,ProfileView}.vue`.
- Auth/data/API: `backend/lib/time_manager_web/{router.ex,authorization.ex,auth_cookie.ex}`, `backend/lib/time_manager_web/plugs/authenticate.ex`, user/working-time/clock/auth controllers, `backend/lib/time_manager/{accounts/user.ex,auth/token.ex,time_tracking.ex,time_tracking/working_time.ex,time_tracking/clock.ex}`, `backend/priv/repo/migrations/`.
- Offline/infrastructure: `frontend/src/services/attendance.js`, `frontend/vite.config.js`, Compose overlays/Dockerfiles, `.github/workflows/ci.yml`.
- Dated results: `docs/validation/security-assessment-20261013.md`, `docs/validation/security-deployment-20261013.md`, `docs/validation/authentication-20261008.md`, `docs/features/offline.md`, relevant operations runbooks and retained tests.
- Prior tracking: `MEMORY.md`; its row score is kept distinct from this report's eight-section comparison.
