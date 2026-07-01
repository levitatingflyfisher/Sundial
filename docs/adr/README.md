# Architecture Decision Records

An ADR captures **one architectural decision**: the context that forced it, the
choice made, and the consequences we accepted. They are immutable once accepted — if
a decision is revisited, add a *new* ADR that supersedes the old one (and mark the
old one `Superseded by ADR-NNNN`) rather than editing history.

Read these when you're about to change something load-bearing and want to know
whether you're fixing a mistake or unknowingly reopening a settled trade-off.

## Index

| # | Decision | Status |
|---|---|---|
| [0001](0001-flutter-clean-architecture.md) | Flutter + Clean Architecture, feature-first | Accepted |
| [0002](0002-drift-over-sqflite.md) | Drift over sqflite for local storage | Accepted |
| [0003](0003-riverpod-for-state.md) | Riverpod for state management | Accepted |
| [0004](0004-local-first-ghost-tier.md) | Local-first, Ghost tier default, no account | Accepted |
| [0005](0005-forgiveness-over-prevention.md) | Forgiveness over prevention (editable sessions, opt-in auto-stop) | Accepted |
| [0006](0006-focus-mode-as-surface.md) | Focus mode is a UI surface over shared data | Accepted |
| [0007](0007-encrypted-backup-seed-phrase.md) | Encrypted backup via a seed phrase; wraps the existing JSON export | Accepted |

## Writing a new one

Copy [`0000-template.md`](0000-template.md) to the next number, fill it in, add a row
above. Keep it to ~one screen — an ADR that needs scrolling is two ADRs.
