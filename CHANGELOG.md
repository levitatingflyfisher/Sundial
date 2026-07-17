# Changelog

All notable changes to Sundial will be documented in this file.

## [Unreleased]

### Added
- Snapshot vault ("Previous backups" on the Backup & Restore screen):
  every encrypted export and every restore leaves a stamped on-device
  snapshot (keep-10, pinnable) you can restore, pin or delete.
- Mandatory pre-restore snapshot: a restore refuses to run unless the
  current data was snapshotted (and the snapshot verified) first —
  restoring is now reversible.
- Preview before restore: the confirm dialog shows the backup's age and
  per-table row counts next to what's on the device now.
- Encrypted exports verify themselves by read-back before reporting
  success, and the `.ohbk` envelope now carries a `createdAt` stamp
  (older backups still restore; older app versions still read new
  backups).
- Silent freshness snapshot when the newest one is older than 7 days.
