# Team attendance failure display — October 13, 2026

Previously, `MyTeamView.fetchStatus` caught attendance failures and returned a
clocked-out state with zero hours. That misrepresented unavailable data as an
employee's actual attendance and could claim nobody was working.

The view now distinguishes loading, available and unavailable status. Person cards
show `Status unavailable` and an accessible unknown-hours dash on failure; genuine
confirmed zero-hour results remain zero. The team summary counts only confirmed
states and explicitly identifies unavailable/loading people. The selected employee's
unavailable state has an alert, and its unverified week summary is hidden. A refresh
button allows recovery without waiting for polling. Request generations and owner/
selection guards prevent stale responses from replacing the currently selected
team or employee's status. Existing attendance caching, queue and synchronization
services are unchanged.

## Focused local evidence

- `npm.cmd run build`: production/PWA build passed.
- `npm.cmd run test:reporting`: 3 tests passed.
- `npm.cmd run test:security`: 4 pagination tests passed.
- `BROWSER_EXECUTABLE_PATH=<installed Chrome> npm.cmd run test:team-status`:
  real candidate Vue build with a fully fictional mocked API at localhost,
  browser-emulated 390px Europe/Paris context. Loading does not fabricate zero;
  one/all failed members display unavailable and unknown hours; valid zero remains
  zero; selected unavailable week is hidden; retry recovers; cached offline attendance
  remains available; delayed old-team response is ignored; layout fits and no page
  errors occurred. No server/database mutation was used for this regression.

The first browser run used an anchored status-text regex that did not tolerate the
span's whitespace; the selector was corrected and the final run passed. The request
wait is bounded. A corresponding browser step is included in the frontend CI gate
before Docker publication/deployment.

These checks fix and verify the specific defect; they do not establish full interface
accessibility, full dashboard arithmetic or all security scope. CI/deployment outcome
is recorded separately when the published revision completes.
