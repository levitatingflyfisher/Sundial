# Privacy model

The short version: **nothing leaves your device.** Sundial in its shipped form is a
local-only app with no network layer. This page says exactly what that means and how
you can verify it yourself, rather than asking you to take it on trust.

## What leaves the device

**Nothing, automatically.** The app has no analytics, no telemetry, no crash
reporting, no ads, and no backend to talk to. There is no account and no login. Every
session, profile, badge, and preference lives in a local SQLite database (via Drift)
on the device.

The only data movement is **user-initiated and local**:

| Action | What moves | Where |
|---|---|---|
| Export (JSON / PDF / text) | Your data, **plaintext** | To a file *you* choose (and then wherever you send it) |
| Encrypted backup (`.ohbk`) | Your data, **encrypted** under a key derived from a recovery phrase only you hold | To a file *you* choose or share — see below |
| Import (JSON / `.ohbk`) | Your data | From a file *you* pick, into the local database |
| Android widget / notification | Timer state | Between the app and the OS, on-device only |

Exports go exactly where you send them — the app does not upload them anywhere.

### Encrypted backup (`.ohbk`)

The encrypted-backup option wraps the same JSON export above in a ChaCha20-Poly1305
envelope, keyed from a 12-word BIP39 recovery phrase generated on-device — see
[ADR-0007](adr/0007-encrypted-backup-seed-phrase.md) and the
[data-model reference](reference/data-model.md#encrypted-backup-ohbk-envelope). The
phrase is the only key: **there is no server-side copy and no reset email** — losing
the phrase means losing the ability to decrypt that backup. This is the same
trade-off local-first apps make everywhere (device loss without a backup already
loses the data); the encrypted option just makes a *carried* backup as private as
the on-device one.

The crypto lives in a **separate, shared package** (`sanctuary_auth_core`, consumed
as a sibling path dependency — see the [README](../README.md#quickstart)), not
hand-rolled in this app. That package also ships an HTTP client and a Sync-tier
client for a *different*, cloud-relay feature — Sundial does not call either; only
the local Ghost-tier seed/encrypt/decrypt primitives are wired up here. If you `grep`
`pubspec.lock` you will find `http` as a transitive dependency for that reason; `grep
lib/` for a network client (below) will not.

## No fonts fetched, either

A subtle leak in many apps is fonts fetched from Google at runtime, which pings a
third party on first launch. Sundial **bundles its fonts** (Lora and Nunito ship in
`assets/fonts/`), so even first launch fetches nothing. This is covered by a test
(`test/shared/theme/offline_fonts_test.dart`) so a regression is caught.

## How to verify it yourself

You don't have to trust this page. Check it:

- **No network in the code.** Search the source for HTTP clients or URLs:
  ```bash
  grep -rniE 'http:|https:|HttpClient|package:http|dio|socket' lib/
  ```
  You'll find no networking dependency in `pubspec.yaml` and no client in `lib/`.
- **No analytics dependency.** Scan `pubspec.yaml` — there is no Firebase, no
  Sentry/Crashlytics, no analytics SDK.
- **Watch the traffic.** Run the app on a device with a network monitor (or in
  airplane mode). It works fully offline and makes no outbound connections.

## The threat model (such as it is)

Because nothing leaves the device, the network attacker and the server-breach
attacker simply have no data to take — there is no server and no wire traffic. The
realistic risks are **local**:

- **Device loss / wipe.** Your data is only on the device. Mitigation: export a JSON
  backup periodically. (There is no cloud backup — see
  [limitations.md](limitations.md).)
- **Device access.** Anyone who can unlock your device can open the app; Sundial does
  not add its own lock. Rely on your OS screen lock.
- **Exports you share.** A JSON/PDF export is plaintext your data — treat a shared
  export like any other personal file.

## When sync arrives

Sync and family features are designed but unbuilt (see
[ADR-0004](adr/0004-local-first-ghost-tier.md)). The commitment for when they land:
data will travel as **encrypted blobs through a dumb relay** — a server that only
stores and returns ciphertext it cannot read — keyed by a shared seed phrase, with no
required account and no Backend-as-a-Service. Until then, this page describes the
whole story: local, offline, yours.
