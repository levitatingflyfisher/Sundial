# Vision

> The north star for Sundial. If you (person or agent) are about to change
> something load-bearing, read this first — it says what must stay true and why.
> For *how it's built*, see [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md);
> for *why each decision was made*, [docs/adr/](docs/adr/).

## The one idea

**A tally of time spent outdoors, kept honest by forgiveness instead of
surveillance — and kept entirely on your device.**

Every screen-free tracker faces the same failure: you start a timer, get absorbed
in the moment, and forget to stop. Come back to eight hours logged when you were
out for two. The tempting fix is to *watch* you — geofences, motion sensors,
aggressive auto-stop, nagging notifications. Sundial refuses all of that.

> **The real fix for a forgotten timer is editing, not intervention.** Any
> session — including one you just stopped — is immediately and completely
> editable. Tap it, correct the duration, done. No side-stopwatch, no mental
> accounting, no app watching you while you're supposed to be outside.

That single principle — *forgiveness over prevention* — plus a hard commitment to
**local-first, no-account** storage, is the whole product. The rest is a timer, a
running total against a goal you set, and a few quiet ways to see your pattern.

## What this is

A local-first mobile/web app for logging time spent outdoors and measuring it
against a personal yearly goal (1000 hours is the friendly default). The core loop
is three taps: **start the timer, go outside, stop the timer.** Everything else —
history, stats, badges, multiple people — is optional and stays out of the way.

Two ways to use the same data:

- **Focus mode** — one screen: a 7-day dot row, the timer, and `247h / 1000h this
  year`. No tabs, no cards, no badges in your face. For people who want a habit,
  not a dashboard.
- **Full mode** — the timer plus history, stats, charts, badges, and per-person
  profiles. Same sessions underneath; just a richer surface.

It is a *tool, not a slot machine.* No feed, no streak anxiety, no push nags, no
leaderboard, no ads.

## Design commitments (do not break these)

These are the load-bearing beliefs. Breaking one is a design regression, not a
feature. Each is recorded as an [ADR](docs/adr/) and defended in the tests.

1. **Local-first, no account — ever — for the core.** Everything works fully
   offline, on-device (Drift/SQLite). The shipped app makes **zero network calls**.
   Any future sync is opt-in and travels as **encrypted blobs through a dumb
   relay** — never plaintext, never a BaaS. ([ADR-0004](docs/adr/0004-local-first-ghost-tier.md))
2. **Forgiveness over prevention.** Every session is editable with no lock-out
   window. Auto-stop exists but is **opt-in and off by default**, with a generous
   2-hour threshold — an outdoor day is not a bug to be interrupted.
   ([ADR-0005](docs/adr/0005-forgiveness-over-prevention.md))
3. **Inform, never nag.** Goals and badges motivate; they never shame. Behind pace
   is **amber, never red**. No streak counters, no "you're falling behind"
   notifications, no dark patterns.
4. **No ads, no tracking, no data sales.** Enforced architecturally: there is no
   analytics dependency, no telemetry, and no server to send anything to.
5. **Your data is yours and portable.** Export to JSON, PDF, or plain text; import
   from JSON. A backup you can read, keep, and move.
6. **Focus mode is a lens, not a lesser tier.** It renders the *same* sessions
   through a calmer surface. Switching modes is a single preference flag — no
   migration, no data hidden behind a paywall. ([ADR-0006](docs/adr/0006-focus-mode-as-surface.md))
7. **Genuine craft.** Clean Architecture (domain / data / presentation), Riverpod,
   Drift, and real tests — unit, widget, and golden/visual. Warm, not sterile:
   home-cooked software for households.

## Honest scorecard — built vs. aspirational

A guiding light has to tell the truth about where the light reaches. This code and
its comments were written by an AI assistant; treat them as *an accurate record of
what currently exists, offered with gratitude and a grain of salt* — verify a claim
before you rely on it. As of `0.1.0`:

**Real, tested, load-bearing (Ghost tier, local-only):**
- The timer state machine (idle → running → paused → stopped), background-safe,
  with Android home-screen-widget and media-notification controls.
- Manual entry, **unrestricted session editing** (including retiming a session to a
  different day), delete, and reverse-chronological history.
- Stats: Today / This Month / This Year / All-Time, a cumulative chart, a heatmap,
  and a per-month breakdown — all filterable by profile.
- Goals (annual default 1000h + optional monthly) with amber-when-behind pacing.
- Badges with a confetti unlock; **multiple local profiles** for a household.
- Export (JSON / PDF / plain text) and JSON import, robust to a bad row.
- Focus and Full modes; dark mode; 12/24-hour and week-start preferences.
- ~30+ test files across unit, widget, golden/visual, and an integration flow.
  Fonts are bundled (no Google Fonts egress); ships as an installable PWA and an
  Android APK.

**Aspirational — documented, not shipped:**
- **Sync and family accounts** (the Token / Named tiers). The auth interface is
  stubbed; both upgrade paths throw `UnimplementedError`. No relay, no encryption
  code, no shared family view yet.
- **Enrichment**: photos per session, an adventure map (manual pins, never live
  GPS), achievements beyond badges, and opt-in "share my year" cards. The schema
  reserves nullable `location`/`lat`/`lng` columns; nothing is built on them.
- **iOS**: the launcher-icon config and release pipeline target Android and web
  only; there is no iOS build story yet.

**A caveat worth naming (a good grain-of-salt example):** badges are currently
*revoked* if your all-time total drops back below a threshold — e.g. after deleting
or shortening sessions. Some product notes describe milestones as permanent; the
code as shipped does not treat them that way. Trust the code, and if permanence is
the intent, that gap is the first thing to close.

## Horizons (problems, not a feature list)

Framed as *problems* on purpose — a dated feature list would only rot.

- **Near — the sync problem.** How do you give a family one shared view without a
  server that can read their days? The transport is easy; the hard parts are
  conflict resolution across devices and key management a non-technical parent can
  actually set up (a seed phrase, not an account). Solve those before writing a
  single byte to any relay.
- **Mid — enrichment that never becomes surveillance.** Photos and places belong to
  outdoor memories, but the moment the app asks for live location while you're out
  there, it has failed its own thesis. The constraint: everything enriching is
  added *retroactively, from the couch,* and never costs attention in the field.
- **Far — parity without an account.** iOS support, and a genuinely offline-first
  sync that a parent can turn on with a shared phrase and no sign-up — proving that
  "no account" and "works across our phones" are not in tension.

## The name

**Sundial** — the oldest instrument for telling time. It needs no power, no
network, and no account; it works only outdoors, in the daylight, by where you
stand under the sky. That is exactly what this app measures: time spent outside.
Fitting that it should need nothing but you and the sun.
