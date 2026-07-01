# Sundial — White Paper

*Counting time spent outdoors without counting the person: a local-first tracker
built on forgiveness instead of surveillance.*

**Status:** conceptual/strategic overview. For the commitments see
[VISION.md](../VISION.md); for the mechanics, [architecture/OVERVIEW.md](architecture/OVERVIEW.md);
for what's real vs. aspirational, §6 here and the
[VISION scorecard](../VISION.md#honest-scorecard--built-vs-aspirational).

---

## Abstract

Families who want to spend more time outside — and less on screens — reach for a
number to aim at (a common one is 1000 hours in a year) and something to track it.
The tools that exist are cloud services: your data lives on their servers, basic
functions like editing a mistake are gated behind a subscription, and the very act
of tracking becomes another account, another dashboard, another thing watching you.
Sundial is the opposite bet. It keeps every hour on your own device with no account
and no network, and it solves the one hard usability problem — the forgotten timer —
not by surveilling you but by making every entry trivially editable after the fact.
The thesis: for this kind of intimate household data, local-first plus *forgiveness*
is both the more private design and the more humane one.

## 1. The problem

Two problems, really, and most apps solve neither well.

**The forgotten timer.** You start tracking, get absorbed in the moment — which is
the entire point of going outside — and forget to stop. You come back to eight hours
logged for a two-hour outing. The industry reflex is to *prevent* this with
machinery: geofences, motion detection, car-speed heuristics, aggressive
auto-timeouts, "still outside?" notifications. Each one drains battery, demands
permissions, or interrupts a genuine long hike — and each one watches you during the
exact window the app should leave you alone.

**The data problem.** Where a family spends its days, when its kids play outside, the
rhythm of its weeks — this is intimate. The dominant tracker in this niche is a SaaS:
the data sits on someone else's servers, and features as basic as editing a session
are behind a paywall. You pay, with money and with data, for the privilege of
recording your own life.

## 2. The idea

**Count the time, not the person — and keep it on the device.**

Two moves carry the whole design:

- **Forgiveness over prevention.** The forgotten timer is fixed by *editing*, not
  intervention. Every session — including one just stopped — is immediately and
  completely editable, with no lock-out window. Auto-stop still exists for people who
  want it, but it is opt-in, off by default, and generous (2 hours). No app should
  cost you attention while you're standing in a field.
- **Local-first, no account.** Everything lives in an on-device database. The shipped
  app makes no network calls, has no analytics, and needs no login. There is nothing
  to breach because there is no server, and nothing to sell because nothing is
  collected.

Neither move is novel technology. Together they are a *stance*: the tool serves the
household, not the other way around.

## 3. Why local-first *here*

Local-first is a good default everywhere in the OpenHearth family; for an outdoor-time
tracker it is close to mandatory. The data is low-volume (a few timestamps a day) and
deeply personal (a family's whereabouts and routines). That combination is exactly
where a server is *all cost and no benefit*: it adds a breach surface, a party to
trust, and an account to maintain, in exchange for conveniences (sync, a shared
family view) that can be delivered other ways. So Sundial keeps the data home and
treats sync as a later, opt-in feature to be built *without* a server that can read
the data — encrypted blobs through a dumb relay, keyed by a shared phrase, no account.
The privacy story today is therefore not a promise but a fact you can verify: turn on
airplane mode and the app is unchanged (see [privacy-model.md](privacy-model.md)).

## 4. Two surfaces, one humane default

The same data renders two ways. **Full mode** is the dashboard — history, stats,
charts, badges, per-person profiles. **Focus mode** is one calm screen: seven dots
for the week, the timer, and a single line like `247h / 1000h this year`. No streak
counter with a loss mechanic, no color-coded shame, no nag. The dot row answers one
question — *did I actually get out this week?* — and stops there. Focus mode is not a
lesser tier or a paywall; it is a lens over the same sessions, one preference flag
away. The point is that the quiet option is a first-class citizen, because for many
people the number and the habit are all they want.

## 5. Positioning: the anti-SaaS tracker

Against the cloud incumbent, Sundial's differentiators are structural, not cosmetic:

- **Editing is free and unrestricted** — the incumbent's paywalled feature is
  Sundial's core safeguard.
- **No account, no server** — onboarding is instant and offline; the data is yours,
  on your device, exportable to JSON/PDF/text at any time.
- **No dark patterns** — no streak anxiety, no FOMO notifications, no feed. A tool,
  not a slot machine.
- **Open** — FLOSS, so the recipe is shareable and the privacy claims are auditable.

It does *not* compete on network effects or social features; that's the point.

## 6. What is built, and what is not

A white paper that overclaims is marketing. Honestly, as of `0.1.0`:

**Built, tested, load-bearing (Ghost tier, local):** the timer (background-safe, with
Android widget + notification controls), manual entry, unrestricted editing, history,
the full stats set (today/month/year/all-time, cumulative chart, heatmap, monthly
breakdown), goals with amber-when-behind pacing, badges with confetti, multiple local
profiles, JSON/PDF/text export and JSON import, Focus and Full modes, and the usual
preferences — behind a Clean-Architecture codebase with unit, widget, golden, and
integration tests, shipping as an Android APK and a web PWA with bundled (non-fetched)
fonts.

**Aspirational — designed, not shipped:** sync and family accounts (the auth
interface is stubbed and throws `UnimplementedError`); enrichment (photos, a manual-pin
map, achievements, share cards — the schema reserves location columns but nothing uses
them); and iOS. See [limitations.md](limitations.md).

**A caveat kept in daylight:** badges are currently *recomputed* against the all-time
total, so deleting or shortening sessions can un-earn a milestone. If permanence is
intended, that's the gap to close — the code, not the aspiration, is the source of
truth.

## 7. Why it's worth doing

Because the alternative on offer — pay a subscription to record your own family's
outdoor time onto someone else's servers, and be nagged and geofenced in the process —
gets the relationship backwards. A tool for spending less time on screens shouldn't
demand more attention, more permissions, and more accounts than the habit it's meant
to support. Sundial's contribution isn't a new algorithm; it's a demonstration that
the humane version — private by construction, forgiving by design, calm by default —
is entirely buildable, and that "no account" and "actually useful" are not in tension.

---

## References

- Diátaxis (Procida, D.) — the framework this project's [docs](README.md) follow.
- The three-tier (Ghost / Token / Named) local-first model and encrypted-blob relay
  posture are shared OpenHearth conventions; see
  [ADR-0004](adr/0004-local-first-ghost-tier.md).

*The code and comments referenced here were authored by an AI assistant and describe
what currently exists — take them with gratitude and a grain of salt, and verify
before relying.*
