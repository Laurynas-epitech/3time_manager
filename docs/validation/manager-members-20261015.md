# Manager member enrollment ? October 15, 2026

The Teams UI loaded only existing managed users, and membership authorization rejected any new employee. Managers can now discover employees through GET /api/teams/:id/member-candidates and enroll them in their own teams. Existing managed assignments remain eligible; admins retain all-user assignment. Employee access, other-team ownership, role changes, and the ordinary /users directory remain restricted.

Verification: production/PWA build passed; four pagination tests passed; tests/team-members-browser.cjs passed in installed Chrome against the local production build with fictional API responses (new employee selected, POST issued, member displayed, candidate removed, no page errors). Backend permissions regressions cover employee enrollment, candidate visibility, employee/other-team denials and admin-target rejection. They were not run: mix is absent and Docker daemon is unavailable. Deployment requested October 15; automated CI will verify the backend before production rollout. No live backend or deployment verification performed yet.

Run backend checks with mix test test/time_manager_web/controllers/permissions_test.exs when Elixir/PostgreSQL are available. Run browser regression with local preview on port 5173 and node tests/team-members-browser.cjs.
