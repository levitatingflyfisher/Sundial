# Personas

Agents drive the real Sundial build as these people, per the fleet testing
rule. Each scenario gives a start state, plain steps, what success looks like,
and what to check. "Standard checks" means: text scale 1.3 at 360 dp width,
dark mode, airplane mode, and every error in plain words near the thing that
caused it. Scenarios aim at the weak spots found by the September 2026 lens
audit.

## Primary: Rosa, a parent chasing 1000 hours outside with three kids

Rosa is 36, home-schools three children, and set a family goal of 1000 hours
outdoors this year. They start the timer at the park gate and often forget to
stop it until dinner.

- **Goal:** log each outing honestly and see whether the family is on pace.
- **Context:** one-handed, a toddler on the hip, bright sunlight, gloves in
  winter. Uses the Flow screen mostly.
- **Would quit if:** the numbers disagree between screens, or a slip of the
  thumb deletes an afternoon.

**R1. One session, one number.** Start: fresh install, Flow chosen at
onboarding, no sessions. Steps: add a 30-minute session; read the total on
Flow, Timer, and every Stats tile and chart label. Success: every screen shows
the same value (30m, or 0.5h), never 0h or 1h. Check: standard checks; the
Flow clock text scales with system text size.

**R2. The forgotten timer.** Start: timer running for four hours. Steps: tap
STOP; find the session; edit it down to 2h; save. Success: STOP says what was
saved (duration, person, date); the edit is reachable in two taps; the face
arc moved past the three-hour mark while running. Check: dark mode; the
running face shows whose timer it is.

**R3. Undo a swipe.** Start: five sessions in History. Steps: swipe-delete one
session and confirm; look for a way back. Success: an Undo appears, or the
dialog says plainly that the session is gone for good. Check: undo after
delete; the Edit Session back arrow does not drop changes silently.

**R4. Am I on pace?** Start: device date set to early September, 650h logged
against 1000h. Steps: open Stats and Timer. Success: the app shows expected
hours to date; on-pace progress is not painted amber. Check: amber and badge
gold are different colours.

**R5. Import onto a new phone.** Start: device with sessions and a 500h goal;
a JSON export from the old phone with a 1000h goal. Steps: open Export,
import the JSON. Success: the app says what the file holds, asks Merge or
Replace, and offers a way back. Check: offline; row labels say what each
option does, not just file formats.

## Secondary: Theo, a grandparent logging for a grandchild

Theo is 72, has low vision, and helps log outings on a shared tablet for a
grandchild's profile. They are new to touch screens and read every label.

- **Goal:** backfill last Saturday's two-hour walk under the right person.
- **Context:** shared tablet, text scale 1.3 or larger, slow careful taps.
- **Would quit if:** Save does nothing, or buttons change meaning under them.

**T1. Save at zero.** Start: two profiles. Steps: open Add Time, leave the
duration at 00:00, tap Save; then open an existing session's Edit Session and
do the same. Success: both sheets behave alike and explain the problem next to
the duration wheels, not in a vanishing bar at the bottom. Check: standard
checks.

**T2. Backfill a past day.** Start: as above. Steps: open Add Time, pick last
Saturday, set 2h, choose the grandchild, save. Success: the session appears
under the right person on the right date. Check: date and notes fields are
labelled the same way in both sheets.

**T3. The mode pill.** Start: Rich mode. Steps: tap the lit "Rich" segment of
the mode pill. Success: nothing changes; only tapping "Flow" switches mode.
Check: onboarding page 2 shows the word "Recommended" and does not look
pre-selected.
