# Known limitations

Remaining implementation or verification work includes:

- Team-wide daily/weekly averages over a selected period and three visible graphs.
  Some original Theme 02 frontend URL contracts need compatibility review.
- Full report arithmetic/DST/overlap verification. Manual working-time edits do
  not currently enforce end-after-start or interval-overlap checks.
- Automatic deployment from CI; workflows stop at tests/image builds.
- Offline datasets/mutations for profile, team and admin pages. Attendance is
  synchronized; other mutations require connectivity.
- All-role/all-page mobile coverage and real-device testing.
- Full security assessment; targeted live verification of revision 87bc705 passed October 13.
  Copied-token revocation and shared-device/resource risks are in [security](security.md).
- Host incident assessment, independent off-server automated backups and failure alerts.

Untested scenarios are not automatically failures. Dated successful checks are
listed in [testing](testing.md); historical operations records remain separate.
