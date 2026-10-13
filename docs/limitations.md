# Known limitations

Remaining implementation or verification work includes:

- Full dashboard-specific arithmetic and accessibility verification. Team averages,
  configurable three-chart reports, required frontend routes and interval ordering
  are implemented/deployed; targeted DST/clipping/partial-update tests passed.
  Recorded overlaps are deliberately summed, rather than rejected.
- An intentional failed-health rollback test and a dedicated restricted deployment
  identity. Actual CI/build/publication/rollout and a disposable backup restore passed.
- Appropriate offline Teams/People reads and whole-app offline coverage. Attendance
  synchronizes; profile/admin mutations require connectivity. Offline destructive
  mutation queues are not prescribed by the supplied checklist.
- Full screen-reader/contrast/keyboard/zoom and physical-device checks. Targeted
  role/page browser-emulation coverage passed.
- Full security assessment; targeted live verification of revision 87bc705 passed October 13.
  Copied-token revocation and shared-device/resource risks are in [security](security.md).
- Host incident assessment, independent off-server automated backups and failure alerts.

Untested scenarios are not automatically failures. Dated successful checks are
listed in [testing](testing.md); historical operations records remain separate.
