# AI implementation and completion-verification brief

Date: October 13, 2026 (Europe/Paris).

This is an execution brief for a future implementation task. Writing this document does not implement or verify the fixes. Baseline: [independent audit](independent-requirements-audit-20261013.md), including its finding validity review. Read current code again before editing; recorded commits and test counts are historical.

## Authoritative scope and timebox

The user's supplied Complete Project Requirements Checklist (attachment 6b5740b4-0a82-40b2-ada1-40ff426136e4, Pasted text.txt) is the requirements boundary. Give that attachment to the implementing AI alongside this document. The user requests one implementation session, targeting at most two hours. Prioritize required gaps and focused verification; report any unfinished point honestly when the timebox ends. Do not promise that all checks or deployment will finish within it.

Required implementation priorities: team daily/weekly averages; reachable three-chart functionality with configuration; the frontend URLs explicitly listed in the supplied checklist; required database constraints; and automatic deployment. Verify remaining applicable checklist functions using current evidence and focused checks, including accessibility, mobile/offline clocking and the specified security investigation/remediation. Existing implemented features should receive credit supported by relevant evidence.

Section 1 interval ordering is a targeted correctness fix. Section 5 session revocation is optional hardening, not an independently prescribed feature or automatic release blocker. Implement optional work only after required priorities, within the timebox, unless a reproducible defect makes it necessary to satisfy the checklist. The checklist requires investigation of token theft risks; documenting and testing that risk is distinct from prescribing a revocation architecture. Offline admin/profile mutation queues and first-time offline login are not explicitly required. Do not add them by default.

Theme 04 is included in the attachment but remains excluded by the user's earlier persistent scope decision. Do not silently reinstate it or claim all eight sections complete while it is excluded; state that completion is within the agreed applicable scope.

The scope rules above take precedence over broader suggestions below. Neither this brief nor the independent audit replaces the supplied checklist.

## Instructions to the implementing AI

Implement the confirmed gaps below in small, reviewable changes. Read root/nested AGENTS.md and MEMORY.md first. Preserve unrelated working-tree edits, deployed HTTPS, authorization, attendance IndexedDB persistence, original offline timestamps and UUID replay protection. Inspect Git status and identify the actual revision and pending changes. Do not reset the tree or infer that historical tests passed on your changes.

Complete local implementation and meaningful verification, then write an evidence report. Do not claim an item complete because code exists, a build passes, a test file exists, or an older report says it passed. Run the relevant checks and inspect their results. If tools, credentials or devices are unavailable, state exactly which acceptance checks remain unverified and continue independent work. Do not broaden scope to Theme 04, native mobile rebuilding, new employee-monitoring features or unlimited penetration testing.

Production changes and external rollout must follow the authorization actually available in that session. This document is not permission to deploy, alter production data or configure repository secrets. Prepare and locally verify rollout artifacts before requesting any missing deployment authorization. Use disposable databases and fictional accounts for tests.

Recommended sequence: team reporting; reachable charts and required URLs; data constraints with interval validation; CI/CD; focused remaining-checklist verification. Session revocation is optional after required work. Each required section below is a separate completion gate; optional sections do not become mandatory gates.

## 1. Manual working-time correctness

Starting points: backend/lib/time_manager/time_tracking/working_time.ex, time_tracking.ex, working_time_controller.ex; frontend/src/components/WorkingTime.vue and WorkingTimes.vue.

Implement server validation using the effective start/end fields from the changeset, including unchanged fields on updates. Default policy: end must be strictly later than start. Return the existing structured validation response (normally 422), without storing a failed request. Keep overnight and multi-day valid intervals. Apply the rule to both create and update and ensure automatic clock transitions still behave correctly. Decide explicitly how zero-duration clock pairs should behave rather than accidentally breaking them through a shared changeset. Show validation errors in the editor.

Do not add overlap rejection without documenting a policy. If overlaps are disallowed, check against other records of the same owner, excluding the edited record, treat touching endpoints as non-overlapping and address simultaneous writes with a transaction/DB constraint. If overlaps are permitted, document whether reporting sums recorded intervals or unions occupied time; report arithmetic must follow that decision.

Completion checks:

- Direct API create with reversed/equal times is rejected according to the chosen policy; no row is inserted. Updating only start or only end cannot produce an invalid interval; the original row survives rejection.
- A 23:00-01:00 overnight record succeeds and reports two hours, split one hour per date. Another user's record cannot be edited or reassigned through the body.
- Tests cover valid overnight creation, partial updates and clock-transition compatibility. Exercise create/edit errors in the browser. If enforcing overlaps, include same-owner overlap, different-owner overlap, adjacent records and concurrent-insert coverage.

## 2. Required database constraints

Starting points: backend/priv/repo/migrations and accounts/user.ex, time_tracking/{clock,working_time}.ex. Map each required field to the exact checklist row before changing it. Confirm username/email, clock time/owner and working-time start/end/owner constraints; evaluate authentication fields separately because legacy passwordless accounts may exist.

Generate a new migration through mix ecto.gen.migration; do not rewrite already-applied migrations. Inventory existing null/orphan rows. Do not manufacture timestamps, passwords or owners, silently delete data, or invent employee values to make migration succeed. Provide an explicit repair step or fail with an actionable preflight error when data cannot be safely repaired. Add NOT NULL constraints once data is valid, preserving foreign keys, indexes and deletion behavior. Plan locks/upgrade impact and rollback behavior.

Completion checks:

- A fresh disposable DB migrates and seeds successfully. A copy containing valid legacy rows upgrades with unchanged row counts and values.
- A fixture with invalid legacy rows exercises the documented preflight/repair behavior without silently losing data.
- Inspect actual DB catalog constraints after migration. Direct SQL null inserts/updates fail for each targeted field; normal application CRUD still succeeds.
- Record upgrade and rollback checks in a disposable environment. Local migration evidence does not establish that production has migrated.

## 3. Team daily/weekly averages over a selected period

Starting points: frontend/src/views/MyTeamView.vue, components/HoursReport.vue, time.js; backend team authorization and reporting queries. Add a visible team summary alongside the existing individual employee report.

Default metric contract, to record before implementation: use distinct current team members as the denominator, including employees with zero recorded hours. Include the manager only if they are a member. Count each member once within a team. Use the selected inclusive calendar dates in an explicit reporting timezone, converted to a half-open interval [start, next-day midnight). Daily average = sum of member hours on that date / member count. Weekly average = sum of member hours in that calendar week intersected with the selected dates / member count. Label truncated first/last weeks. An empty team displays 'No members', not NaN or a fabricated zero average. This uses current membership, not undocumented historical membership reconstruction.

Clip intervals to the reporting period and split them at local calendar midnights. Use elapsed time across DST rather than assuming every day is 24 hours. Define treatment of open sessions explicitly; default completed-session totals, with any live estimate separately labelled. Round for display only.

Prefer a bounded authorized server aggregation for team reports rather than fetching every user's entire history. Validate period bounds, timezone and team identity. Managers can report only their assigned teams; admins can report any team. Do not accept caller-supplied member IDs as authority. Use stable limits and avoid N+1 queries or truncated pagination totals. Show loading, empty and error states; a failed fetch must not appear as zero hours.

Completion checks:

- Three members, with 8h, 4h and 0h on Monday: team total 12h, per-member daily average 4h. Tuesday records 6h, 0h and 0h: average 2h. For a selected Monday-Tuesday period, that week's average is 6h/member, not 3h; any extra per-day tile must be separately labelled. Verify these from fixed fixtures, not from the implementation's own helper.
- Verify empty team, zero-hour member, duplicate membership handling, partial weeks, midnight crossing, period clipping and two teams sharing a member without global double-counting mistakes.
- Under Europe/Paris, 2026-03-29 01:00+01:00 to 04:00+02:00 is 2 elapsed hours; 2026-10-25 01:00+02:00 to 04:00+01:00 is 4. Assert the displayed date allocation and totals.
- Test employee/unassigned-manager denial, assigned-manager success and admin success. Include data beyond existing page sizes to prove totals are complete.
- Browser: choose a team and dates, confirm expected values and switch teams without stale results. Existing individual reports and offline attendance still work.

## 4. Reachable three-chart functionality

Starting points: frontend/src/components/ChartManager.vue, HoursReport.vue, router.js, DashboardView.vue and MyTeamView.vue. Reuse existing Chart.js dependencies and shared reporting calculations.

Mount a real reporting view reachable from navigation. Provide three meaningful graph types: daily-hour bars, weekly-hour line and a pie/doughnut distribution of recorded hours by weekday. Avoid misleading negative slices or clocked-out/worked targets disguised as actual data. All graphs must use the same authorized user and period with clear units, labels, empty/error states and matching table equivalents. Destroy/update chart instances correctly when switching targets or navigating.

Provide demonstrable configuration such as period and daily/weekly grouping; a simple graph selector is a reasonable implementation choice. Reconcile the exact graph-configuration wording with the brief rather than inventing an extensive settings system. Graph types must actually render; three dormant components do not qualify.

Completion checks:

- Browser navigation reaches the report for an employee's own data and a manager's authorized target. Switching bar/line/pie visibly renders all three and changes the appropriate data. Reload/direct navigation works.
- Fixed-fixture numeric datasets and tables agree with independently expected hours; pie slices total the selected recorded hours. No-data state produces no invalid chart values.
- Changing period/user updates charts without showing another user's previous data. API enforcement denies unauthorized target access even when URL/props are manipulated.
- Keyboard controls, labels and readable table equivalents work; verify desktop and 390px layout. Production/PWA build passes and navigation produces no chart errors.

## 5. JWT session revocation (optional security hardening)

Starting points: auth/token.ex, plugs/authenticate.ex, auth_controller.ex, accounts.ex, auth_cookie.ex, frontend/src/auth.js and services/attendance.js. Keep HttpOnly/Secure cookies, CSRF checking and current DB role enforcement.

Recommended design: a persisted server session identified by the signed JWT jti, with user, expiry and revocation state. Register it when issuing a token; authenticate only an active session owned by that user. Online logout revokes the current session and clears the cookie. Successful password change revokes every session for that account, atomically with the password update; require reauthentication or issue a clearly documented replacement session. A per-user session-version design is acceptable if all-session logout is deliberate and documented. Do not use only an in-memory blacklist that disappears on restart or differs between instances.

Never log credentials, raw JWTs or CSRF values. Handle pre-migration tokens explicitly; invalidating them and requiring login is a valid documented release choice. Expired-session cleanup must not revive revoked sessions. Preserve offline attendance data according to existing logout/account-isolation rules: rejected synchronization must retain pending actions for correct-user reauthentication. Offline logout clears local access but cannot promise immediate server revocation without connectivity; document and test that boundary.

Completion checks:

- Sign in, copy cookie + CSRF into a separate test client, verify 200 before logout, then 401 after online logout. Repeat after server restart; use a different instance when deployment has multiple instances.
- Sign in twice; after password change both old sessions return 401. Failed password change leaves sessions unchanged. New-password login succeeds and old-password login fails.
- Missing/wrong CSRF and revoked/expired sessions fail. DB role demotion still takes effect. Account deletion invalidates access.
- Browser login/reload/logout and offline attendance/reconnect work. Pending actions survive session rejection, synchronize after same-user login and never transfer to another account. Distinguish local clear from server revocation in offline-logout evidence.

## 6. CI and automatic deployment

Starting points: .github/workflows/ci.yml, existing Compose/Dockerfiles and docs/operations/{https,database}.md. Inspect existing release scripts and hosting setup; reuse the working deployment model rather than replacing it.

Keep PR validation. Add relevant deterministic frontend reporting tests alongside build and backend checks. Confirm actual release/integration branch policy before changing triggers; do not deploy arbitrary branches or PRs. A successful release-branch push should build/publish immutable SHA-tagged images and trigger an automatic server rollout only after checks pass. Serialize deployments. Configure credentials through the hosting/repository secret mechanism, with least privilege, rather than committing them.

Rollout must retain the database volume, HTTPS/proxy settings, backup/source manifest and previous image references. Perform preflight, backup verification, explicit migration handling, service health checks and authenticated report/clock smoke checks. Roll back compatible application images on failure; schema rollback is not automatically safe. Document migration compatibility and recovery. A manually runnable workflow is useful but does not by itself meet automatic deployment. An environment requiring manual release approval should be described as gated deployment, not fully automatic.

Completion checks:

- Local/staging successful rollout preserves seeded users and attendance; failed health check restores the prior compatible app; no volume recreation. Verify usable backup/restore separately in a disposable DB.
- A release push produces a real successful CI/deployment run and the server reports the intended SHA/image digest. A failing test prevents rollout; a PR runs checks without deployment. Validate serialization or stale-release prevention.
- Post-rollout checks verify HTTPS redirect, login/cookie/CSRF, role restrictions, new reporting and offline original-timestamp/exactly-once replay. Recheck DB constraints if migrated.
- Record workflow/run links, revision/digests, backup and rollout results without secrets. Without configured secrets or an authorized staging/live execution, classify the workflow as prepared/local-verified and deployment behavior as unverified.

## 7. Conditional and verification-only findings

| Item | Implementation or verification instruction | Completion evidence |
|---|---|---|
| Exact client URLs | The user's supplied checklist explicitly lists these: implement /workingTimes/:userID, /workingTime/:userid, /workingTime/:userid/:workingtimeid, /clock/:userid and /chartManager/:userid as functional views or compatible routes. Parse/validate params and authorize target/record ownership; redirects must preserve the requested target. A later explicit user waiver may change this scope. | Direct navigation/reload and actual intended operation for every route, plus denial of other users' targets. A redirect to the default dashboard that drops the target does not qualify. |
| Period API semantics | Document containment versus overlap. For overlap semantics use start < periodEnd AND end > periodStart; document whether response returns original or clipped intervals. Retain validation/pagination and inspect consumers before changing behavior. | Fixture crossing each boundary, inside/outside/exactly-touching intervals, invalid filters and authorization. Existing frontend report regression. |
| All-page offline | Build a role/page/action matrix and reconcile scope with Theme 06. Cache only appropriate account-scoped reads. Mark genuinely online-only actions clearly. If mutations are required offline, implement durable authenticated queues with idempotency, explicit conflict handling and server reauthorization; do not blindly reuse clock toggles for destructive admin operations. | Network-disabled reload/read/action checks for each agreed page, reconnect replay, account switching, expiry, changed roles and conflicts. Attendance-only results cannot certify whole-app offline completion. First-ever offline login is not assumed required. |
| Accessibility/mobile | Review actual pages for keyboard/focus, labels/errors, screen-reader chart equivalents, contrast and 200% zoom. Check agreed role/page paths on narrow and wide screens. Fix observed defects, not hypothetical ones. | Dated page/role/device matrix and concrete outcomes; automate suitable checks and record manual keyboard/screen-reader checks. State when only viewport emulation was used. |
| Security assurance | Map required relevant vectors to existing tests; add targeted missing checks for changed code using controlled fictional data. NoSQL stays N/A. Use bounded resource tests only within authorized environments. | Payload, expected/actual result, revision/environment and remediation/retest for each relevant vector. Do not claim 'secure' from one build or unlimited exhaustive coverage as a completion prerequisite. |
| Research/ethics | Separate mandatory adaptation/research evidence from recommended employee-protection controls. Document real observations, decisions and outcomes. | Traceable existing audit-driven changes or actual stakeholder feedback. Never invent interviews, acceptance or research results. |
| Email/date format | Define the accepted contract before tightening email rules. Keep typed UTC storage; translate API/display formatting only where required. | Contract-backed valid/invalid fixtures and round trips; no invented requirement for a dotted public domain or timestamp-as-text migration. |
| Theme 04 | Excluded by persistent user scope decision. | No implementation requested; do not change the denominator or create deliverables unless scope changes explicitly. |

## Final verification and evidence handoff

Run focused tests during each change. At completion run backend mix precommit as required by backend/AGENTS.md; frontend npm.cmd run build and npm.cmd run test:security; relevant offline/browser scenarios against a disposable running stack. Add/report meaningful reporting and session regression tests. Read test scripts for environment/setup requirements before invoking them. If a tool is missing, record the limitation rather than changing PASS status from source inspection alone.

Create docs/validation/remediation-verification-<date>.md with:

| Item | Contract/decision | Changed files | Exact command or browser action | Expected and actual result | Revision + environment | Status/remaining work |
|---|---|---|---|---|---|---|
| One row per acceptance gate | Include metric/policy choices | Link source/tests | Include failures as well as passes | Use independently expected numeric values | Identify dirty changes and local/staging/live scope | Implemented / verified / deployed / unverified separately |

Retain concise test output and browser artifacts where useful, with fictional data and no secrets. Review final diff for unrelated edits. Update only affected MEMORY checklist entries using dated evidence, recalculate totals if statuses change and add a progress-log entry. Do not mark an entire theme PASS because its new feature passed. End with what changed, checks actually run, remaining limitations and deployment state. No exact overall grade or effort percentage should be inferred from checklist counts.

Completion rule: an item is verified only when its agreed behavior is reachable, authorization and data integrity hold, its acceptance checks ran successfully against the identified revision, and the evidence is recorded. A prepared rollout is not a completed deployment; a documented ambiguity is not an implemented feature.
