# Reference: data model

Precise lookup material for Sundial's on-device schema and export format. Source of
truth: `lib/core/storage/app_database.dart` and `lib/features/export/`. Schema
version: **3**.

## Tables

### `Profiles`

One person in a household. Local only.

| Column | Type | Notes |
|---|---|---|
| `id` | text | primary key |
| `name` | text | display name |
| `emoji` | text? | optional |
| `colorValue` | int | ARGB int (e.g. `0xFF5E9478`) |
| `sortOrder` | int | default `0` |
| `createdAt` | int | epoch ms |

A `default` profile ("Me", sage green) is seeded on install.

### `Sessions`

One logged stretch of outdoor time.

| Column | Type | Notes |
|---|---|---|
| `id` | text | primary key |
| `startTime` | int | epoch ms |
| `endTime` | int | epoch ms |
| `durationSecs` | int | **stored, not derived** — the editable source of truth |
| `notes` | text? | short label, optional |
| `dateDay` | text | `YYYY-MM-DD` grouping key |
| `profileId` | text? | FK → `Profiles.id` |
| `locationLabel` | text? | **reserved** for the future map; unused today |
| `lat` | real? | **reserved**; unused today |
| `lng` | real? | **reserved**; unused today |
| `createdAt` | int | epoch ms |
| `updatedAt` | int | epoch ms |

### `Badges`

Milestone rows, seeded on install; `earnedAt` is set when crossed.

| Column | Type | Notes |
|---|---|---|
| `id` | text | primary key, e.g. `badge_100h` |
| `thresholdHours` | int | hours required |
| `earnedAt` | int? | epoch ms when earned; `null` = not (yet) earned |

**Seeded thresholds (hours):** `10, 25, 50, 75, 100, 200, 250, 300, 400, 500, 600,
700, 750, 800, 900, 1000`.

**Invariant the code maintains:** a badge is earned **iff** the all-time total is ≥
its `thresholdHours`. This is *recomputed*, not latched — awarding on cross
(`checkAndAwardMilestones`) and **revoking** if the total later drops below
(`revokeIfBelowMilestones`). See [concepts.md § badges](../concepts.md#badges) for the
grain-of-salt note on revocation.

### `UserPrefs`

A simple key/value table for durable preferences. The typed shape
(`lib/features/settings/domain/user_prefs.dart`):

| Preference | Default |
|---|---|
| `annualGoalHours` | `1000` |
| `monthlyGoalHours` | *unset* (optional) |
| `appMode` | `flow` (Focus) |
| `flowTimerStyle` | `gnomon` (also `arc`, `dualRing`) |
| `autoStopEnabled` | `false` |
| `autoStopThresholdHours` | `2` |
| `isDarkMode` | `false` |
| `timeFormat` | `h12` (also `h24`) |
| `weekStart` | `sunday` (also `monday`) |

*(Transient state like the running timer's start timestamp is kept in
`shared_preferences`, not in Drift.)*

## Migrations

- **v1 → v2:** added milestone badges `25, 75, 250, 750`.
- **v2 → v3:** added the `Profiles` table and `Sessions.profileId`; seeded the default
  profile.

Add a feature that needs storage → add the table here, bump `schemaVersion`, add an
`onUpgrade` step, and regenerate with `build_runner`.

## Export JSON format

Produced by `JsonExporter.buildJson` (`lib/features/export/data/json_export_impl.dart`).
Current `version`: **3**.

```jsonc
{
  "version": 3,
  "exported": "2026-07-03T12:00:00.000",   // ISO-8601
  "annual_goal_hours": 1000,
  "profiles": [
    { "id": "default", "name": "Me", "emoji": "🌲",
      "color_value": 4284388472, "sort_order": 0, "created_at": 1720000000000 }  // 0xFF5E9478
  ],
  "sessions": [
    { "id": "…", "start_time": 1720000000000, "end_time": 1720007200000,
      "duration_secs": 7200, "date_day": "2026-07-03",
      "profile_id": "default", "notes": "park day",
      "created_at": 1720000000000, "updated_at": 1720000000000 }
  ],
  "badges": [                                // only EARNED badges are written
    { "id": "badge_100h", "earned_at": 1720000000000 }
  ]
}
```

- Optional session fields (`profile_id`, `notes`) are omitted when null.
- Only **earned** badges are exported (id + `earned_at`). On import, thresholds come
  from the install's own seed, and unknown badge ids are skipped — so old backups
  restore cleanly on newer installs and vice-versa.
- Import (`json_import_impl.dart`) is **row-tolerant**: one malformed session is
  skipped rather than aborting the whole import.
