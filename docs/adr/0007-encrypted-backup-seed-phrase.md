# ADR-0007: Encrypted backup via a seed phrase; wraps the existing JSON export

- **Status:** Accepted
- **Date:** 2026-07-12

## Context

Sundial already ships local-first, no-account storage (ADR-0004) with a plaintext
JSON export/import for moving data between devices. Plaintext is fine for a
human-readable summary but is a poor default for a *portable* backup — a lost or
misplaced `.json` file is fully readable by whoever finds it, and it captures
free-text session notes and family members' names (see
[docs/privacy-model.md](../privacy-model.md)).

Auth/crypto is also security-sensitive code that should be written and audited
once and shared across OpenHearth apps, not re-implemented per app.

## Decision

Add an **encrypted `.ohbk` backup** option beside the existing plaintext/JSON/PDF
exports on the same Backup & Restore screen (`/export`), built on the shared
`sanctuary_auth_core` + `sanctuary_backup_ui` packages (consumed as sibling path
dependencies — see the [README](../../README.md#quickstart)). There is no server
and no account: the seed phrase is a recovery key, not a login.

- The **key** is derived from a 12-word seed phrase (BIP39 + HKDF), isolated to
  Sundial via its own `appDomain` (`'sundial'`) so its key material never
  overlaps another OpenHearth app sharing a household seed. The user proves they
  wrote the phrase down by re-entering it before export becomes available —
  turning a UX assertion into a cryptographic check.
- The payload is encrypted with **ChaCha20-Poly1305** (AEAD), scoped by the
  `sundial-backup/v1` AAD context, and framed in the OHBK wire format.
- **`SundialBackupSerializer` wraps the existing `JsonExporter`/`JsonImporter`**
  (`lib/features/export/data/`) rather than inventing a second serialization —
  the `.ohbk` payload is the same JSON the `.json` export already produces,
  wrapped in an `{app, schemaVersion, payload}` envelope so a restore can reject
  a backup made for a different app or a future schema before it's ever handed
  to the importer.
- **Restore is destructive and transactional**: sessions and profiles are wiped
  and re-inserted inside one Drift transaction; the fixed badge catalog
  (id + thresholdHours, seeded at install) is never dropped — only earned status
  is reset and re-applied from the backup.

## Consequences

- **Buys:** a real "please keep this safe" backup format alongside the existing
  human-readable/JSON options, with zero server and zero plaintext egress; a
  shared, auditable crypto module; no second import code path to maintain.
- **Costs:** the seed phrase is unrecoverable if lost — there is no reset email,
  by design. The destructive-replace restore requires an explicit confirm
  dialog stating the consequence in full.
- **Forecloses:** server-side key escrow or account-based recovery. Recovery is
  the user's responsibility, mediated only by the seed phrase.

## Alternatives considered

- **A separate settings screen for backup, independent of `/export`:** rejected —
  Sundial already has one Backup & Restore screen; a second one would fragment a
  single mental model into two.
- **A second bespoke serializer, independent of `JsonExporter`/`JsonImporter`:**
  rejected — two parallel schemas is two things that can drift out of sync; the
  `.ohbk` envelope is deliberately "the same JSON, encrypted."
