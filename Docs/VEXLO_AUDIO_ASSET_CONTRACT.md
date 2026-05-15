# Vexlo Audio Asset Contract

## Purpose

This file is the single source of truth for importing real sound assets into Vexlo.

It exists to prevent:
- inconsistent filenames
- tribal-knowledge asset placement
- accidental runtime churn
- ambiguous event coverage

`AudioService.swift` remains the authoritative runtime mapping. This document defines how assets must be named and imported so that no code changes are required when real files arrive.

## Import Location

All gameplay, result, and system sound files should be added to the main app target bundle for `Vexlo`.

Rules:
- keep files flat in the app bundle unless a future explicit packaging decision is made
- do not create sprawling folder trees for a small sound set
- do not split identical event families across inconsistent locations

## Preferred File Format

Preferred format order is already enforced by `AudioService`:
1. `.caf`
2. `.wav`
3. `.m4a`

Preferred production choice:
- use `.caf` for final short UI/gameplay assets unless a deliberate mastering/export reason requires otherwise

## Naming Convention

Current runtime contract expects one canonical base name per event.

Naming rules:
- lowercase only
- `sfx_` prefix for all supported events
- concise intent-oriented names
- no spaces
- no mixed naming styles
- no version labels in the runtime base contract

## Canonical Event-to-Asset Mapping

These are the current authoritative filenames expected by `AudioService`:

| Event | Required base filename |
| --- | --- |
| `piecePickup` | `sfx_pickup` |
| `validPlace` | `sfx_place` |
| `invalidPlace` | `sfx_invalid` |
| `lineClear` | `sfx_clear` |
| `comboX2` | `sfx_combo` |
| `comboX3Plus` | `sfx_combo` |
| `gameOver` | `sfx_fail` |
| `newBest` | `sfx_best` |
| `dailyComplete` | `sfx_fail` |
| `utilityOpen` | `sfx_utility_open` |
| `utilityClose` | `sfx_utility_close` |
| `toggleOn` | `sfx_toggle_on` |
| `toggleOff` | `sfx_toggle_off` |
| `shareTap` | `sfx_share` |
| `startNewRunConfirm` | `sfx_new_run` |
| `continueResume` | `sfx_continue` |
| `rerollSuccess` | `sfx_reroll` |

## Variations Policy

Current contract supports one canonical asset per runtime base name.

Rules:
- do not add numbered runtime alternates yet
- do not add random variation behavior yet
- if future variation is needed, it must be added centrally in `AudioService`
- until then, any exploration versions should stay outside the runtime contract

This keeps the first premium asset pass deterministic and prevents accidental feel drift.

## Missing Asset Behavior

Missing files are intentionally safe.

Rules:
- missing assets must result in silence
- no crash
- no fallback to unrelated sounds
- no noisy logging requirement

Silence is the correct failure mode until final assets are installed.

## Change Discipline

If an audio asset needs a different runtime name:
- update `AudioService.swift`
- update this document in the same change

If a new event is added later:
- add the event in `AudioService`
- add its canonical filename here
- do not invent parallel naming schemes
