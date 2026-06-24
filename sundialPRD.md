# Sundial — Product Specification v2.2

*Updated March 2026. Changes from v2.0 reflected throughout.*

---

## Overview

A local-first, family-friendly time tracker for outdoor activity. Built on OpenHearth architecture. Users commit to personal goals (1000 hours/year is default) and track progress across devices with optional family accounts. Core loop: start timer, go outside, stop timer. Everything else is optional.

**Target user:** Families fighting screen saturation. Homeschoolers. LDS/faith communities (pro-natalist, outdoor-oriented). Anyone who wants accountability without corporate data harvesting.

**Platforms:** Flutter mobile (iOS/Android) as Tier 1. Web (responsive) as Tier 2. Desktop stretch goal.

---

## The Problem We're Solving

1. **Forgotten timer** — Start tracking, get absorbed in the moment, forget to stop. Come back to 8 hours logged when you were only out 2. The existing 1000 Hours Outside app has no edit in free tier.

2. **No manual entry** — Hiked yesterday without tracking? Can't backfill.

3. **No editing** — Made a typo or double-logged? Stuck deleting and re-entering.

4. **Sync friction** — Partner tracked on their phone, you on yours. No shared view of family progress.

5. **Privacy/lock-in** — Existing app is SaaS. Data lives on their servers. Subscription to unlock features.

---

## Core Product Strategy

**Three-Tier Auth Model (OpenHearth standard):**

| Tier | Auth | Storage | Use Case |
|------|------|---------|----------|
| **Ghost** | None | Local device only (SQLite) | Default. Complete functionality, zero account friction. |
| **Token** | Anonymous UUID | Device + E2E encrypted cloud blobs | Multi-device sync. No PII server-side. |
| **Named** | Email/passkey | Device + E2E encrypted + profile | Account recovery, family sharing, shared calendar. |

**Key constraint:** Ghost mode must be 100% functional. Token/Named are opt-in upgrades that unlock family features, never required for core functionality.

---

## Phase 1: MVP (Flutter Mobile + Web)

### Must-Have Features

#### 1. Stopwatch Timer

- Large, readable display: HH:MM:SS format
- Start/Pause/Stop buttons
- Session summary: "Time added: 2h 34m" on stop
- Haptic feedback on start/stop (mobile)
- Works while app is backgrounded

**The real solution to the forgotten timer is editing, not intervention.**

The primary safeguard is that any session — including one just stopped — is immediately and easily editable. User forgot and left the timer running for 6 hours when they were only out 2? Tap the session, change the duration, done. No stopwatch on the side, no mental accounting. This is more respectful of the user than any auto-stop behavior.

**Auto-stop (secondary safeguard, default OFF):**
- User can optionally enable an inactivity check
- Default threshold: **2 hours** (not 30 min — that's intrusive for anyone doing a real hike)
- Threshold is adjustable: 1h / 2h / 3h / 4h or custom
- Notification: "Timer still running — still outside?" with Dismiss (keep running) and Stop & Save options
- If no response within 5 minutes, timer auto-stops and saves the session
- This feature is **off by default**. Users who want it turn it on. Users who don't, never see it.
- No car-speed detection in Phase 1 (complex, marginal value, adds battery/permission overhead)

**Session editing is a first-class Phase 1 feature, not a footnote:**
- Tap any session to edit duration, date, or notes
- Running sessions can be edited mid-flight if needed (correct start time)
- No lock-out period; no "you can only edit within X minutes" restriction

#### 2. Quick Session Notes (Phase 1)

Notes are moved up from Phase 3 because the use case is real and simple: families want a lightweight label on what they did.

- Optional single text field on session stop (or editable later)
- Character limit: ~100 characters — this is a label, not a journal
- Examples: "park day with co-op", "nature club", "camping with family!", "backyard play"
- No formatting, no markdown, no rich text
- Shows inline on history view under the session duration
- Searchable in Phase 2

This is not the full Notes & Photos feature from Phase 3. It's a sticky note, not a blog post.

#### 3. Manual Time Entry

- "Add Time" button → bottom sheet modal
- Fields: date picker, hours, minutes
- Can add to today or any past date (configurable, suggested default: 90 days back)
- Validation: warn on entries >12h; prevent negative time
- Quick add shortcut: "Add 30 min to today"

#### 4. Edit & Delete Sessions

- Session detail view accessible by tapping any history card
- Edit: duration, date, notes
- Delete: confirm dialog
- Swipe-to-delete on mobile
- Bulk edit: Phase 2

#### 5. Daily/Monthly/Yearly Totals

Dashboard stat boxes:
- **Today** (hours + minutes)
- **This Month** (hours, progress toward monthly goal if set)
- **This Year** (hours, progress toward annual goal)
- **All-Time** (total hours ever tracked)

Real-time updates on any add/edit.

**Goal progress visualization:**
- Progress bars are informational, not punitive
- Color: neutral (blue/green) when on pace; **yellow/orange** when behind — never red
- No streak counters, no "you're falling behind" push notifications
- User should see where they stand without having to do mental math

#### 6. Badge System

- Unlock at: 10h, 50h, 100h, then every 100h
- **Badge earn UX: confetti animation** (confirmed preferred over toast or silent addition)
- "Earned On" date stored with each badge
- Earned badges displayed prominently; upcoming badges visible but grayed
- No badge-loss mechanic; badges are permanent milestones

#### 7. Session History / Timeline View

- Reverse chronological list
- Each row: date, day-of-week, total hours, quick notes preview
- Tap to expand: full notes, edit/delete options
- Swipe-to-delete (mobile)
- Infinite scroll with optional date-range filter

#### 8. Custom Goals

- **Annual goal:** Default 1000h, editable
- **Monthly goal:** Optional; if set, shows monthly progress bar
- Goals inform, never nag

#### 9. Local-First Storage (Ghost Tier)

- SQLite via `drift` (mobile) / IndexedDB (web)
- Zero server calls in Ghost mode
- 100% offline functionality
- No login required
- Data backup: export as JSON or PDF

---

### Phase 1 UI/UX

**Mobile-first:**
- Bottom sheet for "Add Time" and session editing
- FAB for timer start/stop
- Tab navigation: Timer | History | Stats | Settings
- Light mode default; dark mode toggle

**Web (responsive):**
- Same Flutter codebase, adapts to larger screens
- Desktop: sidebar nav + main content area
- PWA installable

**Settings (Phase 1):**
- Annual and monthly goal amounts
- Auto-stop: enable/disable + threshold (default: OFF)
- Time format (12h vs 24h)
- Theme (light/dark)
- Data export / import

---

## Focus Mode (Minimalist UI — Phase 1)

Some users don't want a tracker. They want a habit. One button, one number, a sense of whether they're keeping up. Everything else is noise.

Focus Mode is not a separate app, a paywall tier, or a stripped-down version. It's a UI surface choice that sits on top of the exact same data model. Switch to full mode at any time — all sessions, all history, everything is already there waiting.

### Choosing Your Mode

**Onboarding (first launch):**
> *"How do you want to use this?"*
> - **Simple** — Just the timer and your yearly total
> - **Full** — Timer, history, stats, badges, family features

Both options are free, forever. This is a focus preference, not a feature gate.

The choice sets a default but is permanently changeable in Settings → Appearance → Mode.

### What Focus Mode Shows

One screen. Three questions answered at a glance:

**Past** — A minimal 7-day dot row. Each dot is filled if you logged any outdoor time that day, empty if not. Not a streak counter — no anxiety, no badge, no loss mechanic. Just a quiet visual confirmation of the recent pattern. This week, did I actually do this?

**Present** — The timer. Big button, big clock. Start/Pause/Stop. Nothing else competes for attention.

**Status** — A single line below the timer: `247h / 1000h this year`. No progress bar, no percentage, no color coding. Just the numbers. The user can do the math if they want to, or just feel where they are.

That's it. No tabs. No bottom nav. No cards.

### What Focus Mode Hides

- Badge system (earned silently in background; visible if user switches to full mode)
- History timeline (data is stored; just not surfaced)
- Notes field (no prompt on session stop; no text input)
- Stats dashboard (daily/monthly totals, all-time)
- Monthly goals
- All Phase 3+ features (photos, maps, sharing)
- Multi-profile / family features (single account only; backup via JSON export is available)

### What Focus Mode Keeps

- Timer with full start/pause/stop
- Manual time entry ("Add Time" — still accessible; just less prominent)
- Session editing (tap today's dot or the current session to correct time — forgiveness over prevention still applies)
- Yearly total and annual goal (editable in Settings)
- Local-first storage, full offline, no account required
- JSON backup/export
- Auto-stop (if user has enabled it — inherits the same setting)

### The One Tricky Edge: Session Editing in Focus Mode

In Focus Mode, there's no history list to tap into. But users still need to fix a forgotten timer. Solution: tapping today's dot in the 7-day row opens a minimal edit sheet for today's total. That's the only entry point to session data in Focus Mode — simple enough to not feel like a hidden feature, but not prominent enough to pull attention.

If a user needs to edit older sessions, they switch to Full Mode temporarily (one tap in Settings), fix what they need, switch back. The mode toggle is fast and lossless.

### Data Model Note

Focus Mode requires zero schema changes. Sessions are stored identically. The 7-day dot row is computed from the same `Sessions` table as the full history view — it's just a different render of the same query. Switching modes is a single `userPreference` flag; no migration, no data movement.

### UI Spec (Focus Mode)

```
┌─────────────────────────────┐
│                             │
│   ● ● ○ ● ● ● ○            │  ← 7-day dots (Mon–Sun or rolling)
│                             │
│        00:00:00             │  ← Timer display
│                             │
│         [ START ]           │  ← FAB / large button
│                             │
│    247h / 1000h this year   │  ← Status line
│                             │
└─────────────────────────────┘
```

Minimal chrome. No bottom nav. Settings accessible via gear icon top-right. "Add Time" accessible via small `+` top-left (small but present — backfilling is valid).

---

## Phase 2: Family Accounts & Sync (Token/Named Tiers)

### Multi-Device Sync (Token Tier)

- Sessions sync bidirectionally across all devices
- Conflict resolution: last-write-wins + timestamp
- E2E encryption on client; server sees only encrypted blobs
- Works offline; syncs on reconnect

### Family Profiles (Named Tier)

- Parent creates Named account (email + passkey)
- Add child profiles (name + optional birthdate; no email required)
- **Everyone sees everyone's data by default** — family transparency, no hidden sibling views
- Parent can restrict visibility if needed, but open is the default
- Kids see the full family view, not just their own
- Privacy: family data is never shared beyond the family account

### Features Unlocked by Family Tier

- Shared family calendar: all members' sessions in one timeline
- Family collective goal ("5000h this year as a family")
- Parent dashboard with per-member breakdown
- Account recovery via passkey + BIP39 backup codes

---

## Phase 3: Enrichment (Photos, Map, Sharing)

### Photos per Session

- Optional photo attachment (1-3 photos per session)
- Stored locally on device (Ghost tier); synced E2E encrypted if Token tier
- Thumbnail visible when expanding a session in history
- "That hike photo" surfaces naturally as you scroll back — no special album view required
- No cloud-only storage; photos never require an account

### Adventure Map (Manual, Not GPS Tracking)

The map feature should never require live GPS. User feedback is clear: constant location tracking is a battery drain and an attention drain — especially when you're trying to get kids buckled.

**Implementation:**
- Location is added **retroactively** via manual pin drop or address search
- "Where were you?" is an optional field on session edit, not required at session stop
- Map view shows pins for tagged sessions — "everywhere we've been outside"
- No GPS trace recording, no live tracking, no Strava-style "end session and process route"
- Privacy: location data stays local (Ghost/Token tier); never uploaded without explicit opt-in

This is strictly lower-friction than Strava. The user can add a location from the car ride home, from the couch that evening, or never. No prompts, no flow, no typos.

### Achievements (Beyond Badges)

- "First 100h in a month"
- "30-day streak" (informational, never coercive)
- "Highest single session"
Lighthearted; never nagging.

### Light Social Sharing (Opt-In Only)

- "Share my year" card: static image, no engagement loop
- Family sharing link: view-only, generated manually
- No commenting, liking, feed algorithms, or auto-posting
- Integrity: user initiates every share, always

### Export

- **PDF** (clean printable summary — most useful for most users)
- **JSON** (backup / portability)
- CSV is low priority; skip unless requested

---

## Phase 4: LDS/Faith Vertical (Stretch)

- Come Follow Me journal app cross-link
- Sabbath awareness: mark Sunday as rest day, disable timer start on Sabbath (opt-in)
- Link outdoor time to family home evening or preparedness themes
- Generic by default; faith-specific features are settings toggles

---

## Feature Scope by Phase

| Feature | Phase | Notes |
|---------|-------|-------|
| Stopwatch timer | 1 | Core |
| Session editing (unrestricted) | 1 | Core — the real forgotten-timer fix |
| Session notes (quick label) | 1 | Moved up from Phase 3 |
| Manual entry | 1 | Core |
| Totals (daily/monthly/yearly) | 1 | Core |
| Goal progress bars (yellow/orange when behind) | 1 | Core |
| Badge system + confetti | 1 | Core |
| History/timeline | 1 | Core |
| Custom goals | 1 | Core |
| Local-first storage | 1 | Core |
| Auto-stop (default OFF, 2h threshold, adjustable) | 1 | Opt-in safeguard |
| Focus Mode (minimalist UI — same data, clean surface) | 1 | Onboarding choice + Settings toggle |
| Multi-device sync | 2 | Token tier |
| Family profiles | 2 | Named tier |
| Shared family calendar (everyone sees everyone) | 2 | Named tier |
| Photos per session (local-first) | 3 | Optional enrichment |
| Adventure map (manual pin drop, no live GPS) | 3 | Optional enrichment |
| Achievements beyond badges | 3 | Optional enrichment |
| Light social sharing | 3 | Opt-in only |
| LDS/faith integration | 4 | Stretch |

---

## Technical Architecture

### Platform Strategy

**Tier 1: Flutter Mobile (iOS + Android)**
- `drift` (SQLite), `riverpod` (state), `sanctuary_auth` plugin
- Encryption: `sodium_libs` (XChaCha20-Poly1305)

**Tier 2: Web (Flutter Web)**
- Same codebase compiles to web
- PWA installable, mobile browser compatible

### Backend (Token/Named Tiers Only)

- Supabase: PostgreSQL + Auth + Edge Functions
- Schema additions for notes field on sessions table (Phase 1 local; synced in Phase 2)
- Location field on sessions: optional lat/lng + label string, E2E encrypted

### Storage

**Ghost:**
`Sessions(id, date, seconds, notes, location_label, lat, lng, created_at, updated_at)`

**Token/Named:** Same schema, synced as encrypted blobs. Server never sees plaintext.

---

## User Flows

### Flow 1: Forgot to Stop the Timer

1. User started timer at 9am, got absorbed, checked phone at 4pm — 7 hours logged
2. Tap the running session card
3. Edit duration: change to 2h 30m
4. Save. Totals update instantly.
5. No side-stopwatch required.

### Flow 2: Backfill + Add a Note

1. Yesterday's nature club hike, didn't track
2. Tap "Add Time" → pick yesterday → enter 90 min
3. Add note: "nature club — saw a red-tailed hawk"
4. Done in 15 seconds

### Flow 3: Badge Unlock

1. User crosses 100h milestone
2. Confetti animation triggers
3. Badge displayed on screen; "Earned On" date stored
4. No nag to share or keep going — just the moment

### Flow 4: Family View (Named Tier)

1. Parent sets up family account
2. All four family members' sessions show on shared calendar
3. Kids see siblings' time too — shared ownership of the family goal
4. Parent dashboard: "This month: family 247h total — [Child1] 82h, [Child2] 74h, [Parent1] 51h, [Parent2] 40h"

### Flow 5: Adventure Map (Phase 3)

1. Family gets home from hike; kids are buckled and waiting
2. User does NOT open the app — nothing required
3. That evening, user taps the day's session, taps "Add location"
4. Types park name or drops a pin on the map
5. Map view now shows that park in the growing collection of adventures

---

## Design Principles

**Simplicity first.** Every friction point between intention and action is a failure.

**No dark patterns.** No streak reminders, no nagging notifications, no FOMO. Tool, not slot machine.

**Respect the moment.** You're outside. The app should cost you nothing while you're out there. When you're back, editing is fast and forgiving.

**Family first.** Shared visibility builds shared investment. Don't hide kids from each other.

**Privacy is default.** Local until you opt in. Cloud is encrypted. Location is retroactive and optional.

**Forgiveness over prevention.** Better to let the user fix a mistake than to prevent it with a feature they resent.

---

## Open Design Questions (Resolved)

| # | Question | Resolution |
|---|----------|------------|
| 1 | Check-in timing/default | **Default OFF.** If enabled: 2h threshold, adjustable. User controls this entirely. |
| 2 | Check-in notification style | N/A — default off; style TBD if feature is used |
| 3 | Badge UX | **Confetti animation** |
| 4 | Can kids see siblings? | **Yes — everyone sees everyone by default** |
| 5 | Photo storage | Local (Ghost tier); E2E sync if Token tier |
| 6 | Map: GPS trace vs. pins | **Manual pins only — no live GPS, no trace recording** |
| 7 | Goal progress color | **Yellow/orange when behind** — never red |
| 8 | Export format | **PDF + JSON** — CSV low priority |

---

## Success Metrics (by Phase)

### Phase 1
- <2 second time-to-timer-start
- Session editing discoverable and used (>70% of beta users find and use it)
- Zero edit lock-outs reported
- Auto-stop opt-in rate tracked but not a success criterion (it's opt-in)

### Phase 2
- >40% of multi-device users upgrade to Token or Named
- Family view used >3x/week by parents
- Zero data loss on sync

### Phase 3
- >30% of users add notes to sessions
- >15% of users add photos
- >10% of users use adventure map
- Map adds <1s latency to session view on 3G

---

## Out of Scope (Explicitly)

- Leaderboards or competitive scoring
- Streak anxiety features
- Push notifications about outdoor activity
- Apple Health / Strava integration
- Ads or paywalls
- Community feed (no chat, no follows, no likes)
- Live GPS tracking
- Car-speed auto-stop (Phase 1; revisit in Phase 2 if requested)

---

## Development Timeline (Rough)

- **Phase 1:** 8-10 weeks (Flutter mobile + web, Ghost tier, notes field included)
- **Phase 2:** 6-8 weeks (Supabase, Token/Named auth, family sync)
- **Phase 3:** 6-8 weeks (photos, manual map pins, light social)
- **Phase 4:** 4-6 weeks (LDS integration, if doing it)

---

## Ownership & Licensing

- **Owner:** OpenHearth — 501(c)(3)
- **Developer:** OpenHearth project team via ISS contract
- **License:** MIT or GPL-3 (TBD)
- **Data:** User owns all data; OpenHearth has no commercial rights
- **Funding:** Grants and donations; no VC, no exit plan

---

**Version:** 2.2
**Status:** Ready for design & architecture review
**Key changes from v2.1:** Added Focus Mode — minimalist onboarding choice + settings toggle; same data model, clean single-screen UI (7-day dots, timer, yearly total only); no badges, history, notes, or social in this mode; session editing preserved via tap-on-dot; JSON backup available.

---

## Addendum — April 2026: Supabase Removed from Architecture

Supabase has been dropped from the OpenHearth architecture. References to Supabase in the Phase 2 section (PostgreSQL + Auth + Edge Functions) reflect a design that is no longer the plan.

**What this means for Sundial:**
- **Phase 1 (Ghost, local-only):** Completely unaffected. Ship as designed.
- **Phase 2 (family sync):** Will use a vendor-agnostic encrypted blob relay (Cloudflare R2 + Workers is the default candidate) rather than Supabase. The server stores and returns ciphertext — it never interprets the payload. Auth will use a seed-phrase-based shared-key scheme, not Supabase Auth.

This reflects the current OpenHearth architecture as of April 2026.
