# Documentation

Organized on the [Diátaxis](https://diataxis.fr/) model — four kinds of docs for
four different needs. Find what you need by *what you're trying to do*, not by
guessing a filename.

| I want to… | I need | Go to |
|---|---|---|
| **learn by doing** | a Tutorial | [Tutorials](#tutorials) |
| **accomplish a specific task** | a How-to guide | [How-to guides](#how-to-guides) |
| **look up exact details** | Reference | [Reference](#reference) |
| **understand why** | Explanation | [Explanation](#explanation) |

New here? Start with the [README quickstart](../README.md), then
[Explanation § concepts](concepts.md), then the [architecture overview](architecture/OVERVIEW.md).

---

## Tutorials
*Learning-oriented — take me by the hand through my first success.*

- The **[README quickstart](../README.md)** — clone, generate code, run the app.

*Gap (contributions welcome):* a hand-held "log your first outdoor hour, then edit
it, in 5 minutes" tutorial. If you write one, put it in `docs/tutorials/`.

## How-to guides
*Task-oriented — how do I accomplish X (assumes you know the basics)?*

- **[Build & run](how-to/build-and-run.md)** — set up the toolchain, generate code,
  run the tests, run the app.
- **[Ship the PWA and the APK](how-to/ship-pwa-and-apk.md)** — build for web and
  Android, including the drift-on-web gotchas.
- Working *in* the repo (for humans and agents): **[AGENTS.md](../AGENTS.md)** and
  **[CONTRIBUTING.md](../CONTRIBUTING.md)**.

## Reference
*Information-oriented — tell me exactly, precisely, completely.*

- **[Data model](reference/data-model.md)** — the Drift tables, the badge milestone
  set, and the export JSON format.
- **[Feature status](reference/feature-status.md)** — what's shipped, partial, or
  planned, per feature.

## Explanation
*Understanding-oriented — help me understand the ideas and the why.*

- **[Vision](../VISION.md)** — the one idea, the commitments, the honest scorecard.
- **[Architecture overview](architecture/OVERVIEW.md)** — the layers + diagrams.
- **[Architecture Decision Records](adr/)** — why each load-bearing choice was made.
- **[Concepts](concepts.md)** — sessions, the timer state machine, goals & pacing,
  badges, Focus vs Full mode.
- **[Privacy model](privacy-model.md)** — what leaves the device (nothing), and how
  to verify it.
- **[Limitations](limitations.md)** — read before adopting. What it does *not* do.

---

### The white paper

One long-form document complements this tree:
- **[White paper](whitepaper.md)** — the conceptual case: why this app exists, why
  local-first matters *here*, and how it differs from the cloud incumbent.

*(There is no "yellow paper" / formal spec: Sundial's core is a straightforward
CRUD-plus-aggregation app with no merge semantics, wire format, or proof obligation
that would warrant one. The one durable invariant — how badges track the running
total — is stated plainly in [concepts.md](concepts.md) and
[reference/data-model.md](reference/data-model.md).)*
